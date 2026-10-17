# Estado actual del prototipo

Corte: 17 de octubre de 2026, aplicación `0.1.0+1`, `main` hasta `44d0aeb`. Existe una versión jugable y un APK de depuración generado por CI. La aceptación final del MVP en un teléfono físico está pendiente.

## Qué está implementado

| Área | Comportamiento actual | Código principal | Evidencia y límite |
| --- | --- | --- | --- |
| Arranque | Carga el balance, abre el guardado y muestra el taller o una jornada restaurada pausada | [main.dart](../lib/main.dart) | Apertura y restauración revisadas en navegador |
| Tablero | Arena 360 × 560, un generador, un hoyo, bolas circulares y pala de un puntero | [Board](../lib/features/board/domain/board.dart), [GardenGame](../lib/features/board/presentation/garden_game.dart) | Empuje y recogida observados; sensación en móvil pendiente |
| Física | Fricción, bordes, separación e impulso entre bolas mediante rejilla espacial | [Board](../lib/features/board/domain/board.dart) | Prueba de grupo de diez bolas dentro de límites; no certifica comodidad |
| Monedas | Captura genera valor físico, aterrizaje, recogida por toque/barrido, fusión y límite de pilas | [Board](../lib/features/board/domain/board.dart) | Pruebas de cobro único y conservación del valor |
| Ciclo | Producción, cierre, pausa y noche; 60 + 5 s como base; noche sin límite | [DayCycle](../lib/features/day_cycle/domain/day_cycle.dart), [GameSession](../lib/app/game_session.dart) | Diez ciclos controlados y límite temporal probados |
| Economía | Enteros; ingreso diario separado del ahorro; cierre único; pendientes perdidos | [Economy](../lib/features/economy/domain/economy.dart), [GameSession](../lib/app/game_session.dart) | Cierre repetido y compras inválidas probados |
| Mejoras | Ocho tipos, tres ramas, costes, niveles y requisitos; efectos al siguiente día | [Catálogo](../lib/features/upgrades/domain/catalog.dart), [CSV](balance.csv) | Validación de catálogo, dependencias y compras |
| Automatización | Un robot que empuja, velocidad mejorable e imán alrededor de la pala activa | [Robot](../lib/features/automation/domain/robot.dart), [Board](../lib/features/board/domain/board.dart) | Casos controlados de robot e imán superados |
| Progreso | Ahorro, niveles, día, récord, último resultado y comparación con el anterior | [Progress](../lib/features/progression/domain/progress.dart) | Guardado/restauración y ciclos probados; no hay historial completo |
| Persistencia | JSON v1; cola de escrituras; principal y copia; restauración pausada | [Referencia](persistencia.md) | Recuperación en archivos temporales Linux; falta ensayo en Android real |
| Interfaz | Jornada, pausa, taller por ramas, mensajes de ayuda y errores de guardado | [game_app.dart](../lib/app/game_app.dart) | Recorrido de widgets y navegador; taller aún en lista |
| Sonido | Clic del sistema al cobrar/comprar, con opción de silencio | [game_app.dart](../lib/app/game_app.dart) | Sin audio propio ni volumen independiente; sonido real no certificado en todos los destinos |
| Entrega | Android vertical y web de apoyo; SDK fijado y lockfile versionado | [Configuración](../pubspec.yaml), [.fvmrc](../.fvmrc) | APK y web compilados; sin validación en teléfono |
| CI | Activación exclusivamente manual, formato, análisis, pruebas, APK, firma y artefactos | [Workflow](../.github/workflows/flutter-manual.yml) | Ejecución manual correcta en `main`; ver [CI](ci.md) |

## Evidencias publicadas

- [PR #2](https://github.com/migdlp/incremental_hole_game/pull/2): aplicación y guardado, fusionados en `main` como `70556fb`.
- [PR #3](https://github.com/migdlp/incremental_hole_game/pull/3): APK manual, fusionado en `main` como `44d0aeb`.
- [Ejecución manual 39020361800](https://github.com/migdlp/incremental_hole_game/actions/runs/39020361800): correcta sobre `44d0aeb`, incluyendo análisis, 17 pruebas, compilación, firma y subida del APK.
- [Registro de validación](validacion-prototipo.md): condiciones de las pruebas locales y capturas. Los artefactos de CI tienen retención de 14 días; el enlace de ejecución identifica la evidencia aunque la descarga haya caducado.

Las pruebas de simulación usan objetos controlados. La revisión del navegador usó generación normal y puntero: 3 capturas y 6 monedas cobradas, sin errores de JavaScript. Ninguno de esos resultados demuestra rendimiento o balance en un teléfono.

## Diferencias entre diseño y entrega

| Propuesta del diseño | Situación real |
| --- | --- |
| Árbol con conexiones visuales | Lista por ramas con requisitos y estados; falta el grafo final |
| Audio con recursos propios, concurrencia y volumen | Solo clic del sistema y silencio; `flame_audio` no está instalado |
| Sistema de partículas y carga de 150 partículas | `particle_limit` está en el CSV, pero no existe sistema de partículas ni pools |
| Modelos separados `RunState`, `BoardSnapshot`, `SaveEnvelope` | Se componen mapas JSON desde `GameSession` y `Board`; esas clases no existen |
| Eventos de tablero con IDs y tipos | `BoardEvents` devuelve conteo de capturas e importe recogido; los objetos retirados evitan repetir eventos |
| Coordinación directa de automatización desde sesión | `Board` posee el robot y consulta su controlador puro |
| Tipos de contenido y puertos públicos más amplios | Hay un tipo de bola, ocho IDs de mejora y un puerto de guardado; sin motor genérico ni archivos públicos de exportación por módulo |
| Suite `integration_test` y perfil en móvil | Existen pruebas de reglas/sesión y widgets; no hay suite `integration_test` ni mediciones físicas |
| Primera bola inmediata en la propuesta económica inicial | El código espera a acumular el intervalo de generación; se ha corregido la explicación de economía |

## Pendiente de aceptación

| Prioridad | Tarea | Evidencia para cerrarla |
| --- | --- | --- |
| Alta | Elegir Android físico y validar entrada, legibilidad y grupos | Registrar modelo, Android, versión/commit, recorrido y problemas observados |
| Alta | Probar guardado nativo e interrupciones | Salir a segundo plano, reabrir, forzar cierre y verificar que no hay doble cobro; documentar pérdida desde el último guardado |
| Alta | Validar economía y progresión | Diez jornadas manuales; revisar primera compra y robot en aproximadamente 3–5 días sin garantizar ese ritmo |
| Alta | Medir rendimiento | Modo profile, 200 bolas y 100 pilas, tres jornadas y revisión tras diez ciclos; objetivo de 60 FPS aún sin verificar |
| Media | Completar audio y volumen | Recursos propios con licencia, silencio y control independiente; prueba real por destino |
| Media | Completar presentación | Grafo del árbol, respuesta visual final e iconos de instalación propios |
| Según necesidad | Ampliar pruebas de integración y robustez | Añadir regresiones de errores observados, recuperación y evolución de esquema antes de declarar garantías más amplias |

La carga de partículas de la especificación solo podrá medirse cuando exista ese sistema. No se registra como prueba realizada.

## Fuera de este MVP

Sin backend, cuentas, nube, clasificación, monetización, prestigio, recompensas por tiempo cerrado, múltiples tableros, varios robots, robot recolector de dinero ni monedas especiales. iOS y escritorio nativo no están configurados como destinos de esta entrega. Una versión firmada para tienda no forma parte de la pipeline actual.
