# Referencia de guardado y recuperación

## P01 · Estrellas y burbujas físicas (0.15.0+23)

Completar una cuota expulsa burbujas físicas; agarrarlas y lanzarlas contra paredes
o herramientas permite romperlas y cobrar estrellas permanentes. Un premio por
cuota y un cobro por identidad, separados del vuelo visual. Pendientes reaparecen
entre jornadas, con un límite de cuerpos activos que no elimina recompensas.
**Al morir o prestigiar se pierden las pendientes; las cobradas se conservan.**
Esta regla P01 sustituye la conservación opaca provisional descrita en la entrega
S03 inferior. No se convierten pendientes en saldo automáticamente.

JSON v11 / balance v17 con v16 congelado. DEBUG permite forzar premios y ajustar
todos los parámetros provisionales. Gravedad/succión se comparan mediante
interruptores experimentales en DEBUG; su integración final sigue abierta.
P02 y BAL01 continúan pendientes. [Contrato y pruebas](p01-estrellas-burbujas.md).

## Entrega anterior S03 · Prestigio y derrota (0.14.0+22)

**Decisión expresa del usuario:** activar derrota en juego normal con las cuotas
provisionales actuales. Al incumplir el quinto día se termina la partida y aparece
**DERROTA**, sin estadísticas. Continuar abre la tienda de prestigio; Nueva partida
vuelve al día 1. Se reinician monedas, mejoras, herramientas y alimentación, y se
conservan estrellas cobradas, compras permanentes, descubrimientos y datos P01 pendientes.

Nodo Prestigio visible desde el comienzo al explorar, mayor y girado 45°, tanto en
normal como DEBUG. Su compra exige confirmación y reinicia inmediatamente, sin
botón posterior. Configuración de prueba: 10.000 monedas, Generador V + Valor V +
Duración V, esquina avanzada (48,48). **No son decisiones finales de BAL01.**

La tienda muestra estrellas y permite nueva partida, sin catálogo P02 ni premios
P01 inventados. Morir no concede estrellas. JSON v10 / balance v16, con v15 congelado.
Checkpoint permanente independiente, dos copias actuales y barrera de revisión:
una copia normal antigua no puede reabrir una partida terminada. DEBUG es temporal.
[Contrato, integración y pruebas](s03-prestigio-metaprogresion.md).

S03 sustituyó las cuotas sin derrota. P01 ya añade burbujas; P02 y BAL01 siguen pendientes.

## C01 · Cobro automático vigente (0.13.0+21)

Cada captura calcula una única recompensa completa (Valor, dorada y racha),
alimenta inmediatamente y registra el importe garantizado. Tras aproximadamente
1 s, una moneda decorativa salta del hoyo y vuela en curva al monedero; el saldo
visible aumenta al recibirse. No hay colisiones, recogida manual ni fase final
de recogida: producción base 15 s y cierre directo con liquidación íntegra.

Barrido, Área, Imán y Atracción salen del catálogo activo. El usuario autorizó
retirar sus compras **sin reembolso**; no se altera saldo ni otras mejoras.
Robot conserva solo Escoba ancha II como requisito, confirmado por el usuario.
JSON v9 / balance v15, con v14 congelado para física de jornadas antiguas.
Registros económicos y pool visual independientes; agrupación u omisión visual
no pierde dinero. Restaurar liquida directamente lo pendiente, una sola vez.
[Implementación, DEBUG y medición pendiente](c01-cobro-automatico.md).

Las referencias anteriores a recogida manual o fase final describen versiones
históricas y quedan sustituidas por C01.

## Contrato vigente · S01, 0.12.0+20

JSON v8 / balance v14. `feeding` guarda período, jornadas, puntos normales e
instantáneos, contadores de jornada, objetivo y paso provisional. Tablero v14
guarda `feeding.normal` / `feeding.instant`; su suma debe coincidir con
`ball_value × (captured + 9 × goldenCaptured + combo.bonusUnits)` y los contadores
de jornada con la sesión. Restaurar no vuelve a acreditar capturas. v1–v7 migra
sin alimentación histórica; una jornada activa antigua termina con su balance
y S01 empieza en la siguiente completa. v13 queda congelado. DEBUG no persiste
sus experimentos ni su fallo reversible. Se conservan saldo, compras, opciones,
archivos y paquete. [Detalle S01](s01-alimentacion-cuotas.md).

## Ampliación M03, 0.11.0+19

JSON v7 / balance v13. Campo opcional raíz `launcherPose` para posición/ángulo
entre jornadas; guardados anteriores usan pose inicial. Tablero v13 guarda
`launcher`: pose, reloj parcial, presión/velocidad, RNG, intentos/disparos y flash.
Restauración valida antes de aplicar, abre pausado y no repite disparo/sonido.
Balance v12 congelado para jornadas antiguas; compras y saldo conservados. DEBUG
restaura también pose y no guarda sus experimentos. [Detalle M03](m03-generador-lanzador.md).

## Ampliación E02, 0.10.0+18

JSON v7 / balance v12. `board.blackHole` conserva RNG, comprobaciones,
identidades, objetos/daño, activaciones y tiempos. Guardar/restaurar no repite
activación ni sonido; reabre pausado. Recogida elimina objetos y efecto. El CSV
v11 queda congelado para jornadas antiguas, sin cambiar saldo/compras ni
introducir E02 a mitad. [Detalle de campos y pruebas](e02-agujero-negro.md).

## Ampliación E01, 0.9.0+17

JSON v7, balance v11. `eventRandom` guarda el RNG de eventos independiente del
emisor de bolas; si falta en datos anteriores se inicializa sin borrar progreso.
La jornada v11 guarda `board.gravity` y las velocidades libres de escoba/bate.
Se conservan sorteo pendiente, objeto/daño, tiempo restante, anuncio y fuerza
filtrada: cargar no repite ni el sorteo ni la activación. Los tiempos se validan
contra la fase/tiempo de la jornada antes de modificar la sesión. Reaparece pausada.
`balance_v10.dart` congela v10; las jornadas 1–10 conservan su configuración hasta
terminar. La siguiente usa el balance vigente. DEBUG no escribe simulaciones ni
semillas de prueba en el guardado real. [Campos y comportamiento E01](e01-gravedad.md).

Las secciones siguientes conservan los contratos anteriores.

## Contrato M02, 0.8.0+16

JSON **v7**, balance **v10**. `levels.bat` conserva las tres compras; los tableros
v10 añaden `batPosition` y `batAngle`. Se validan pose y configuración antes de
restaurar; no se recuperan dedos activos. La jornada reaparece pausada. Las poses
se reinician al comenzar otra jornada, como ocurre con la escoba.

`haptics` es un booleano opcional de preferencias: falta significa `true`.
Se conservan `sound`, `visualFeedback`, archivos, saldo, compras y migraciones.
`balance_v9.dart` congela la economía anterior: una jornada guardada de balances
1–9 termina con su configuración original y la siguiente usa v10. Impactos,
contactos y enfriamiento de audio/háptica son transitorios. DEBUG no escribe
compras ni jornadas de prueba. [Detalle M02](m02-bate-beisbol.md).

Las secciones siguientes conservan contratos y evidencias anteriores.

## Sesión de depuración temporal

El modo de depuración no cambia el esquema JSON. Al entrar entre jornadas, `GameSession.enterDebug()` captura el progreso normal y encola su guardado antes de activar el modo. Mientras está activo, `save()` no encola escrituras de las pruebas. La cola anterior continúa escribiendo únicamente instantáneas normales. Las compras, reinicios y jornadas de prueba se descartan al salir mediante restauración de la instantánea inicial. Una nueva instancia de la aplicación inicia el modo desactivado y carga el guardado normal. Ver [uso del modo de depuración](modo-debug.md).

## Actualización de combos — esquema v6

La revisión de código 0.6.0+11 escribe JSON v6 y acepta v1–v5. `board.combo` guarda `enabled`, `streak`, `remaining` y `bonusUnits`. La racha y su ventana restante usan tiempo de simulación; la carga conserva ambos valores y presenta la jornada pausada. `bonusUnits` conserva el incremento acumulado por combos incluso después de terminar una racha. Se exige `generated = ball_value × (captured + 9 × goldenCaptured + bonusUnits)` además de `generated = collected + pending`.

Se rechazan tiempos no finitos/fuera de ventana, rachas mayores que las capturas, bonificaciones negativas o fuera del máximo posible y contabilidad incongruente antes de aplicar el estado. Un combo desactivado no puede tener racha, tiempo ni bonificación. El tablero de una jornada v6 debe incluir este bloque.

Una jornada v1–v5 no contiene combo: se carga con `enabled = false` y mantiene sus premios ×1 hasta terminar. Al volver a guardarla en v6 se conserva ese estado; solo la siguiente jornada activa combos. No se cambian niveles, saldo ni configuración histórica. El balance sigue en versión 6; el esquema JSON v6 es independiente de la versión del balance. Las secciones siguientes documentan contratos anteriores.


## Actualización vigente — 0.5.0+10 · JSON v5 y balance 6

Se escribe `version: 5` y se aceptan versiones 1–5. `grandfathered` mantiene las compras del catálogo antiguo; `previousTree` conserva los niveles que ya estaban comprados en v4 antes del nuevo requisito de Imán. Ambos mapas se validan contra sus requisitos históricos y no conceden niveles nuevos. Las compras posteriores cumplen el CSV actual.

Las jornadas nuevas usan balance 6: Mano I cuesta 13, Valor da 2/3/5/8/13 y el imán requiere Área III y cuesta 300. Una jornada activa mantiene su balance 1–5 hasta terminar. El balance 5 queda congelado en [balance_v5.dart](../lib/features/upgrades/domain/balance_v5.dart), además de las copias históricas existentes.

`board.coins` contiene monedas individuales de valor 1/10/50/100/500. Al restaurar una pila histórica de otro importe se descompone sin perder dinero. `board.queuedCoins` es un mapa denominación → cantidad que conserva las monedas pendientes de emitir si se llena el límite de objetos visibles. Se valida que solo tenga claves de las cinco denominaciones y cantidades enteras no negativas; forma parte del valor pendiente. El nuevo límite visible es 1000; las jornadas históricas conservan su límite original.

`board.collectedCoins` registra denominación → cantidad recogida durante la jornada y se copia a `last.collectedCoins` al cerrarla. Se exige que su valor sumado coincida con el ingreso cobrado. `null` significa que ese desglose no se guardaba en la jornada histórica; se conserva el ingreso y se indica que falta el detalle, sin deducir un recuento ficticio de un total. Las claves se serializan como cadenas canónicas, por ejemplo `"50"`.

La restauración valida configuración, recuentos, IDs y contabilidad antes de modificar la sesión. Al cargar no se restaura un agarre ni se cobra el día dos veces. A partir de aquí se conserva la documentación histórica de los esquemas anteriores; esta sección prevalece para el contrato actual.

## Bolas doradas — 0.3.3+8

El esquema v4 añade `golden` a cada bola y `goldenCaptured` al tablero. En datos anteriores ausentes significan bola normal y cero capturas doradas. El contador dorado debe estar entre cero y el total capturado. La contabilidad valida `generated = ball_value × (captured + 9 × goldenCaptured)` además de `generated = collected + pending`. El estado aleatorio sigue guardado, así que cargar no vuelve a sortear una bola existente ni reinicia la secuencia de emisiones.

## Historial — esquema v4 y balance 5

La revisión 0.3.1+6 conserva el esquema JSON v4 y admite balances 1–5. Las jornadas nuevas usan **balance 5**: $1 por bola base y 3 segundos de recogida final. Las jornadas activas de balance 4 conservan sus tiempos y valores completos desde [balance_v4.dart](../lib/features/upgrades/domain/balance_v4.dart); los balances 1–3 siguen usando [legacy_balance.dart](../lib/features/upgrades/domain/legacy_balance.dart). No se modifica el ahorro ni se convierten los importes existentes.

Las monedas siguen guardándose como pilas con `value` entero. La descomposición en denominaciones de $1/$10/$50/$100/$500 es presentación derivada; no añade otro saldo ni requiere migrar los objetos. Ningún agarre se restaura. Al terminar la jornada histórica, el siguiente día adopta el balance actual.

La evidencia de compatibilidad incluye recargar dos veces una jornada de balance 4 con monedas pendientes, recoger y bancar su importe anterior una sola vez, y comenzar luego una jornada de balance 5. Las secciones históricas que siguen conservan el contrato de versiones anteriores; esta actualización prevalece para las versiones actuales.

## Actualización del árbol — v4

El formato actual escribe `version: 4` y `grandfathered`, un mapa de niveles heredados. Al leer v1/v2/v3 se validan sus requisitos históricos y se conservan sus compras sin conceder requisitos nuevos; al volver a guardar, esta procedencia queda persistida. Los niveles heredados deben ser compras válidas del catálogo anterior. Cualquier compra posterior sigue el CSV actual, incluidos requisitos cruzados separados por `&`.

Las jornadas activas mantienen `balanceVersion` 1/2/3 y los valores congelados en `legacy_balance.dart` hasta terminar, también tras sucesivas restauraciones en v4. En la entrega del mapa las jornadas nuevas usaban balance 4; ahora usan balance 5. Se conserva la validación de configuración, contabilidad y objetos antes de modificar la sesión. Las referencias a v3 que siguen documentan el formato anterior.

La capacidad de mano se guarda como nivel `hand` y efecto de jornada `hand_capacity`. Los guardados previos sin ese efecto se normalizan a capacidad 1 solo si no hay compras de mano. No se restauran agarres; todas las bolas sostenidas se serializan con velocidad cero. Una escoba seleccionada durante el bug de acceso gratuito vuelve a mano si no está comprada; su pose guardada no concede acceso físico.

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
- `balanceVersion = 7` identifica el balance actual: 15 + 5 s y emisión base de 1,5 bolas/s. Las jornadas activas guardadas con versiones 1–6 conservan sus tiempos y balance hasta que terminan; el nuevo balance se aplica al comenzar el día siguiente. No es la versión del esquema JSON.
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
| v3 | Exige herramienta válida y `run.balanceVersion` entero, `1`, `2` o `3`; valida los valores exactos contra esa versión |

Saldo, resultados, niveles y objetos de la misma jornada se conservan. Una jornada v1/v2 restaurada mantiene sus tiempos e intervalo originales hasta terminar, y se abre pausada. Al volver a guardar se escribe v3 con `balanceVersion: 1`, para poder reabrirla de nuevo. El siguiente `startDay` usa el balance actual (`3`). Un guardado nocturno antiguo comienza directamente con el balance nuevo.

Los valores históricos de duración e intervalo están conservados en `UpgradeCatalog.settings` para `balanceVersion: 1` y `2` para validar partidas antiguas; no son una segunda tabla de balance para ajustar partidas nuevas. La validación completa precede a la aplicación del estado. `load` conserva como copia la instantánea leída; la escritura v3 ocurre al siguiente guardado normal.

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

El tablero congelado detrás del pop-up de resultados es un detalle de presentación en memoria. `run` sigue siendo `null` al cerrar y no se guarda ese fondo; al reabrir una noche se muestra un tablero vacío detenido con los resultados y las compras conservados.

## Actualización: guardado v7 y balance v8

La racha pasa a requerir compra. El balance v7 está congelado en
`balance_v7.dart`: jornadas antiguas conservan recompensa, tiempos y racha hasta
terminar; las nuevas usan v8 y exigen el desbloqueo. Se mantiene lectura de JSON
v1–v6, conservando saldo y niveles.

Los tableros v8 guardan `specials` (cargas y duración restante) y `captureAllIds`
(bolas ya presentes al activar Captura total). Una activación pendiente se
consume una vez en el siguiente paso, incluso si se guarda antes; las monedas
siguen pasando por la contabilidad normal. Se validan cargas, tiempos y objetivos.
El tiempo cerrado o pausado no recarga. Una nueva jornada reinicia las cargas.
Los dos agarres de escoba son transitorios: se guarda su pose física, no dedos
activos; restaurar deja la sesión pausada y sin agarres.

## Preferencia de feedback visual

El JSON v7 admite el campo opcional booleano `visualFeedback`. Se guarda con las
preferencias, igual que `sound`. Si falta en una partida anterior, se restaura
como `false`; no se reinicia el progreso ni la jornada. Es presentación: no
modifica la configuración económica ni la geometría o controles del tablero.

## M01 — balance v9 y paredes

El esquema JSON sigue en v7. `levels.walls` conserva I–III mediante la validación
y compras existentes; el ajuste de la jornada queda fijado al empezar. Se admite
balance 9 y se conserva el CSV v8 en `balance_v8.dart`; las jornadas activas v8
no reciben campos nuevos. Las anteriores utilizan rebote ×0,40 y límite 380 como
fallback de física. Los impactos visuales son transitorios y no se serializan.
