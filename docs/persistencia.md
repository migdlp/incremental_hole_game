# Referencia de guardado y recuperación

Formato actual: JSON, `version = 3`; se aceptan también versiones `1` y `2` mediante compatibilidad explícita. Implementación: [GameSession](../lib/app/game_session.dart), [Board](../lib/features/board/domain/board.dart) y adaptadores de [persistencia](../lib/persistence/). Este documento describe el contrato actual, no un servicio de sincronización.

## Dónde se guarda

| Destino | Adaptador | Ubicación o claves |
| --- | --- | --- |
| Android y otros entornos con `dart:io` | `FileSaveStore` | Directorio devuelto por `getApplicationSupportDirectory()` de `path_provider` |
| Web | `WebSaveStore` | `SharedPreferences`, claves lógicas `progress` y `progress.backup` |

En archivo se usan `progress.json`, `progress.backup.json` y temporales `progress.tmp`/`progress.backup.tmp`. El directorio concreto depende de plataforma y aplicación; no se fija `/workspace` como lugar de progreso del jugador. Los archivos del entorno de desarrollo son otra cosa, descrita en la [guía de desarrollo](guia-desarrollo.md).

En web, el plugin gestiona la representación de las preferencias en el almacenamiento del navegador. No se debe depender de su prefijo interno al acceder desde código de la aplicación. El progreso pertenece al origen del sitio y puede perderse si se borran sus datos o cambian sus condiciones de almacenamiento.

## Estructura superior

| Campo | Tipo | Significado |
| --- | --- | --- |
| `version` | entero | Se escribe `3`; se admiten `1`, `2` y `3` |
| `tool` | cadena | Herramienta seleccionada: `hand`, `broom` o `vee`; debe estar desbloqueada |
| `day` | entero | Jornada actual si hay `run`, o siguiente jornada disponible de noche |
| `balance` | entero | Ahorro bancado, separado del ingreso del día en curso |
| `record` | entero | Mayor ingreso de una jornada finalizada |
| `levels` | objeto ID → entero | Niveles comprados; un ID ausente equivale a nivel cero |
| `sound` | booleano | Clics del sistema activados o silenciados |
| `last` | objeto o `null` | Último resultado: `day`, `income`, `generated`, `captured`, `previousIncome` |
| `run` | objeto o `null` | Jornada activa; `null` indica taller/noche |

Ejemplo completo y válido de partida nueva, antes de comenzar el primer día:

```json
{
  "version": 3,
  "tool": "hand",
  "day": 1,
  "balance": 0,
  "record": 0,
  "levels": {},
  "sound": true,
  "last": null,
  "run": null
}
```

No hay un campo de historial completo ni se guarda una fecha para generar progreso sin conexión. La pausa no necesita persistirse: cualquier jornada cargada se presenta pausada.

## Jornada activa

`run` contiene `remaining` (segundos), `collected`, `generated`, `settings`, `balanceVersion` y `board`.

- `settings` contiene las bases y efectos comprados al iniciar el día. La carga exige igualdad con el catálogo de esos niveles y de la versión de balance correspondiente.
- `balanceVersion = 2` identifica el balance actual: 10 + 5 s y emisión base cada 3 s. `1` identifica el anterior: 60 + 5 s y emisión base cada 0,75 s. No es la versión del esquema JSON.
- `board.random` conserva el estado entero del generador congruencial; la semilla inicial es `day * 7919`.
- `board.nextId`, `captured` y `spawnClock` conservan identificadores, capturas y progreso del intervalo de emisión.
- `board.balls` contiene objetos `{id, p: [x, y], v: [vx, vy]}`.
- `board.coins` contiene objetos `{id, p: [x, y], value, landing}`. `landing` es el tiempo restante de aterrizaje entre `0` y `0.2`.
- `board.robot` es `[x, y]`; `robotTarget` es ID de bola o `null`.

La posición del robot y su objetivo se conservan; sus temporizadores internos de decisión/atasco se reinician. El puntero, orientación de escoba y agarre activo no se serializan. Una bola agarrada se guarda en su posición como bola normal con velocidad cero; no se restaura un lanzamiento ficticio. Las animaciones cosméticas no constituyen una fuente de ingreso.

## Compatibilidad entre versiones

| Esquema leído | Tratamiento |
| --- | --- |
| v1 | No incluye herramienta. Quien tenía `paddle` comprado recibe `broom: 1` y selecciona escoba; el resto selecciona mano. No se concede barrido. Se valida la configuración original sin los desbloqueos nuevos |
| v2 | Conserva herramienta y compras. La jornada activa pertenece al balance anterior |
| v3 | Exige herramienta válida y `run.balanceVersion` entero, `1` o `2`; valida los valores exactos contra esa versión |

Saldo, resultados, niveles y objetos de la misma jornada se conservan. Una jornada v1/v2 restaurada mantiene sus tiempos e intervalo originales hasta terminar, y se abre pausada. Al volver a guardar se escribe v3 con `balanceVersion: 1`, para poder reabrirla de nuevo. El siguiente `startDay` usa el balance actual (`2`). Un guardado nocturno antiguo comienza directamente con el balance nuevo.

Los valores históricos de duración e intervalo están conservados en `UpgradeCatalog.settings(..., balanceVersion: 1)` para validar partidas antiguas; no son una segunda tabla de balance para ajustar partidas nuevas. La validación completa precede a la aplicación del estado. `load` conserva como copia la instantánea leída; la escritura v3 ocurre al siguiente guardado normal.

## Cuándo y cómo se escribe

Se solicita una instantánea al comenzar o terminar el día, comprar, seleccionar herramienta, cambiar sonido, entrar en pausa y aproximadamente cada cinco segundos de avance activo. `snapshot()` captura los valores del momento de la solicitud. Una cadena de futuros `_writes` ejecuta las escrituras en orden, evitando que una solicitud antigua termine sobrescribiendo una más reciente.

En una escritura de archivo:

1. Si existe una instantánea anterior validada y guardada, se escribe en `progress.backup.tmp` con `flush` y se renombra a `progress.backup.json`.
2. La nueva instantánea se escribe en `progress.tmp`, también con `flush`.
3. Se renombra el temporal a `progress.json`.
4. La sesión actualiza `_lastSaved` solo si el adaptador terminó sin error.

La copia se forma a partir de `_lastSaved`, no copiando a ciegas un principal posiblemente dañado. El reemplazo usa operaciones de archivo; no se implementa una transacción de base de datos ni se garantiza durabilidad frente a cualquier corte de alimentación. Principal y copia son dos reemplazos distintos.

En web se escribe primero la preferencia de copia anterior y después la principal. No es una transacción atómica entre las dos claves. Un resultado falso o una excepción del adaptador se comunica como error de guardado.

## Carga y validación

`loadCandidates()` devuelve principal y copia en ese orden. Para cada candidato, la sesión intenta decodificar y validar todo el estado antes de aplicarlo:

- Versión admitida, tipos esperados, día/saldo/récord no negativos y resultado anterior coherente.
- IDs de mejora conocidos, niveles dentro del catálogo y requisitos satisfechos.
- Configuración de jornada coincidente y tiempo finito, positivo y dentro de su duración.
- Límites de bolas/pilas, valores de monedas positivos, aterrizaje válido y posiciones/velocidades finitas.
- IDs de objetos únicos, positivos y anteriores a `nextId`.
- `generated == collected + pending` y `generated == captured * ball_value`.

Si se rechaza el principal y la copia es válida, se restaura esa copia y se muestra un aviso. El aviso depende del índice del candidato: si el principal no existe y la copia es el único candidato, el código actual puede cargarla sin ese mensaje. Si los candidatos existentes fallan, `load()` informa del error sin sobrescribirlos. `Bootstrap` ofrece reintentar o crear una partida nueva con confirmación explícita. Si no hay ningún candidato, se inicia un progreso vacío.

La lectura nativa permite decodificar UTF-8 dañado para que el candidato pueda rechazarse y se intente la copia. Un error de acceso al directorio/archivo puede impedir obtener los candidatos; no se promete recuperación de todos los fallos del sistema de archivos. Estas comprobaciones son validación de consistencia, no protección criptográfica frente a edición de partidas.

## Cierre e ingreso único

El cierre crea el resultado, banca `collected`, actualiza día/récord, elimina la jornada y encola una sola instantánea compuesta. No se guarda «sumar dinero» por separado de «terminar el día».

Una segunda llamada a `finishDay()` se ignora al no haber jornada. Tras cargar una instantánea nocturna no hay jornada que volver a cobrar. Si se recupera una copia anterior al cierre, también se recupera el saldo anterior a ese cierre, por lo que no se combina una jornada antigua con un saldo nuevo.

## Límites y evolución

- El intervalo de cinco segundos es una frecuencia de solicitud, no un máximo garantizado de pérdida. Una escritura en curso, un fallo de almacenamiento o recuperar una copia anterior pueden hacer retroceder más.
- No hay avance por tiempo real mientras está cerrada la aplicación; al volver hay que continuar explícitamente.
- Un fallo de escritura no revierte las acciones en memoria. Se muestra un aviso y se permite reintentar; salir antes de un guardado correcto puede perderlas.
- Modificar IDs, valores de balance, reglas o esquema puede invalidar una jornada guardada. La igualdad de `settings` es deliberadamente estricta; probar compatibilidad antes de distribuir un cambio de balance.
- Hay compatibilidad explícita v1/v2 → v3 y conservación del balance anterior por jornada. Para cambios futuros hay que ampliar y probar esa política; incrementar el esquema no migra automáticamente configuraciones desconocidas.
- Firma de APK y formato del guardado son asuntos distintos. Una APK con certificado diferente puede exigir desinstalar la anterior y borrar sus datos; consultar [desarrollo](guia-desarrollo.md) antes de hacerlo.

La evidencia de archivo disponible procede de pruebas Linux y la de web de recargas en Chromium. La aceptación de recuperación y cierre forzado en Android físico sigue pendiente en [estado actual](estado-actual.md).
