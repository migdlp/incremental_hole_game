# Estado actual del prototipo

> Actualización 0.3.3+8: cabecera sin oscurecer durante la recogida final; 1 % de bolas doradas con recompensa ×10 (base $10), guardado y contabilidad por tipo. Conserva la mano con peso de 0.3.2+7. Los enlaces de APK inferiores corresponden a sus versiones históricas.

> **Entrega Android — 19 de octubre de 2026:** PR #15 integrada en `main`, commit `27b3950146389f2db3f63cf708ffb289ed908859`. Versión **0.3.1+6**. [Pipeline 39181076818](https://github.com/migdlp/incremental_hole_game/actions/runs/39181076818) correcta: formato, análisis, 88 pruebas, compilación Android y firma verificada. [Descargar APK y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39181076818/artifacts/12155843676), disponible hasta el 2 de noviembre de 2026. Descomprimir e instalar `jardin-mecanico-debug.apk`. La prueba en Android físico y el ajuste de balance siguen pendientes. Las notas de preparación inferiores conservan el estado anterior a esta entrega.


> Revisión 0.3.1+6 preparada para integrar: CF-01 a CF-04, monedas sin cifras, $1 por captura base, 3 s de recogida final y recorrido estadísticas → árbol → comenzar día. La implementación se verifica con pruebas y compilación web; Android físico pendiente. Ver [economía](economia.md), [árbol](arbol-de-mejoras.md) y [compatibilidad](persistencia.md). Esta nota prevalece sobre las cifras históricas inferiores.

> Actualización vigente — 19 de octubre: se implementa el [mapa futuro v0.6](cambios-futuros-arbol-mejoras.md) en 0.3.0+5: 44 nodos, cuatro ramas, cinco niveles, seis colores, Doble emisión y alcance del imán. Mano inicial de una bola, mejoras a 2/3/4/5/6 y escoba solo tras comprarla. Guardado/balance v4 conserva las compras y jornadas antiguas. Esta nota sustituye estados anteriores que la contradigan; ver [árbol actual](arbol-de-mejoras.md) y [historial](../CHANGELOG.md).

Corte: 18 de octubre de 2026, aplicación `0.2.2+4`, con resultados modales y generación inicial de 1,5 bolas/s. La evidencia histórica de APK se identifica debajo por commit. Existe una versión jugable y un APK de depuración generado por CI. La aceptación final del MVP en un teléfono físico está pendiente.

## Qué está implementado

| Área | Comportamiento actual | Código principal | Evidencia y límite |
| --- | --- | --- | --- |
| Arranque | Carga el balance, abre el guardado y muestra el taller o una jornada restaurada pausada | [main.dart](../lib/main.dart) | Apertura y restauración revisadas en navegador |
| Tablero | Arena 360 × 560, un generador, un hoyo, bolas circulares, mano individual y escobas recta/en V con un puntero | [Board](../lib/features/board/domain/board.dart), [GardenGame](../lib/features/board/presentation/garden_game.dart) | Empuje y recogida observados; sensación en móvil pendiente |
| Física | Fricción, bordes, separación e impulso entre bolas mediante rejilla espacial | [Board](../lib/features/board/domain/board.dart) | Pruebas de agarre, inercia, orientación, anchura, V y límites; no certifican comodidad en móvil |
| Monedas | Captura genera valor físico, aterrizaje, pulsación inicial y barrido comprado, fusión y límite de pilas | [Board](../lib/features/board/domain/board.dart) | Pruebas de cobro único y conservación del valor |
| Ciclo | Producción, cierre, pausa y noche; 10 + 3 s como base; emisión de 1,5 bolas/s; noche sin límite | [DayCycle](../lib/features/day_cycle/domain/day_cycle.dart), [GameSession](../lib/app/game_session.dart) | Diez ciclos controlados y límite temporal probados |
| Economía | Enteros; ingreso diario separado del ahorro; cierre único; pendientes perdidos | [Economy](../lib/features/economy/domain/economy.dart), [GameSession](../lib/app/game_session.dart) | Cierre repetido y compras inválidas probados |
| Mejoras | Catorce tipos, 44 nodos, costes, niveles y requisitos; efectos al siguiente día | [Catálogo](../lib/features/upgrades/domain/catalog.dart), [CSV](balance.csv) | Validación de catálogo, dependencias y compras |
| Automatización | Un robot que empuja, velocidad mejorable e imán alrededor del dedo activo | [Robot](../lib/features/automation/domain/robot.dart), [Board](../lib/features/board/domain/board.dart) | Casos controlados de robot e imán superados |
| Progreso | Ahorro, niveles, día, récord, último resultado y comparación con el anterior | [Progress](../lib/features/progression/domain/progress.dart) | Guardado/restauración y ciclos probados; no hay historial completo |
| Persistencia | JSON v4, migración v1/v2/v3 y balance 5 con restauración histórica de balances 1–4; cola de escrituras; principal y copia; restauración pausada | [Referencia](persistencia.md) | Recuperación en archivos temporales Linux; falta ensayo en Android real |
| Interfaz | Jornada, pausa, resultados en pop-up bloqueante y árbol progresivo con arrastre/zoom, ficha y compra de 3 s | [game_app.dart](../lib/app/game_app.dart) | Pruebas de widgets de descubrimiento y compra/cancelación; Android físico pendiente |
| Sonido | Clic del sistema al cobrar/comprar, con opción de silencio | [game_app.dart](../lib/app/game_app.dart) | Sin audio propio ni volumen independiente; sonido real no certificado en todos los destinos |
| Entrega | Android vertical y web de apoyo; SDK fijado y lockfile versionado | [Configuración](../pubspec.yaml), [.fvmrc](../.fvmrc) | APK y web compilados; sin validación en teléfono |
| CI | Activación exclusivamente manual, formato, análisis, pruebas, APK, firma y artefactos | [Workflow](../.github/workflows/flutter-manual.yml) | Ejecución manual correcta en `main`; ver [CI](ci.md) |

## Evidencias publicadas

- [PR #8](https://github.com/migdlp/incremental_hole_game/pull/8), `1a8fed7`: agarre, escobas, barrido comprado y guardado v2. [CI 39136783858](https://github.com/migdlp/incremental_hole_game/actions/runs/39136783858): 36 pruebas, APK y firma correctos.
- [PR #10](https://github.com/migdlp/incremental_hole_game/pull/10), `1d71843`: día inicial de 15 segundos totales, generación cuatro veces más lenta y guardado v3. [CI 39138119402](https://github.com/migdlp/incremental_hole_game/actions/runs/39138119402): 41 pruebas, análisis, APK y firma correctos.
- [Descargar APK del balance, antes del árbol](https://github.com/migdlp/incremental_hole_game/actions/runs/39138119402/artifacts/12141030218): `0.2.1+3`, retención hasta el 1 de noviembre de 2026. Ver [CI](ci.md) para regenerarlo.
- [PR #12](https://github.com/migdlp/incremental_hole_game/pull/12), `1720fba`: árbol progresivo y siete pruebas nuevas; [CI 39141075339](https://github.com/migdlp/incremental_hole_game/actions/runs/39141075339) correcta con **48 pruebas**, APK y firma; [descarga actual](https://github.com/migdlp/incremental_hole_game/actions/runs/39141075339/artifacts/12142120297); ver [árbol](arbol-de-mejoras.md) para distinguir descubrimiento y requisitos del CSV.
- [Registro de validación](validacion-prototipo.md): separa la evidencia inicial y la de controles/balance actuales.

Las pruebas de simulación usan objetos controlados. En `0.2.0+2`, la revisión del navegador con generación normal y puntero logró 2 capturas y 4 monedas cobradas, sin errores JavaScript; herramientas compradas se comprobaron con un guardado aislado. El balance de `0.2.1+3` se verificó con cinco pruebas adicionales y CI, sin una nueva sesión manual de balance. Ninguno de esos resultados demuestra rendimiento o comodidad en Android físico.

## Diferencias entre diseño y entrega

| Propuesta del diseño | Situación real |
| --- | --- |
| Árbol con conexiones visuales | Implementado con descubrimiento, zoom y compra por pulsación de 3 s; pendiente aceptación física |
| Audio con recursos propios, concurrencia y volumen | Solo clic del sistema y silencio; `flame_audio` no está instalado |
| Sistema de partículas y carga de 150 partículas | `particle_limit` está en el CSV, pero no existe sistema de partículas ni pools |
| Modelos separados `RunState`, `BoardSnapshot`, `SaveEnvelope` | Se componen mapas JSON desde `GameSession` y `Board`; esas clases no existen |
| Eventos de tablero con IDs y tipos | `BoardEvents` devuelve conteo de capturas e importe recogido; los objetos retirados evitan repetir eventos |
| Coordinación directa de automatización desde sesión | `Board` posee el robot y consulta su controlador puro |
| Tipos de contenido y puertos públicos más amplios | Hay un tipo de bola, once IDs de mejora y un puerto de guardado; sin motor genérico ni archivos públicos de exportación por módulo |
| Suite `integration_test` y perfil en móvil | Existen pruebas de reglas/sesión y widgets; no hay suite `integration_test` ni mediciones físicas |
| Primera bola inmediata en la propuesta económica inicial | El código espera a acumular el intervalo de generación; se ha corregido la explicación de economía |

## Seguimiento de esta tanda

El [plan de cambios](plan-cambios-agarre-escoba.md) registra los bloques implementados, parámetros provisionales, criterios comprobados y APK entregados. Agarre, escobas, compra de barrido, limpieza nocturna y compatibilidad están implementados. La documentación general se actualiza ahora por indicación del usuario; esto no certifica pruebas físicas ni el balance definitivo.

El árbol progresivo ya está implementado; quedan aceptación de su interacción y ajuste de precios/ritmo de progreso. La aspiradora está aparcada; las demás [ideas](ideas-herramientas-bolas.md) no son alcance comprometido.

## Pendiente de aceptación

| Prioridad | Tarea | Evidencia para cerrarla |
| --- | --- | --- |
| Alta | Elegir Android físico y validar entrada, legibilidad y grupos | Registrar modelo, Android, versión/commit, recorrido y problemas observados |
| Alta | Probar guardado nativo e interrupciones | Salir a segundo plano, reabrir, forzar cierre y verificar que no hay doble cobro; documentar pérdida desde el último guardado |
| Alta | Validar economía y progresión | Diez jornadas manuales con el balance nuevo; acordar precios, primera compra y acceso al robot. La hipótesis anterior de 3–5 días no está vigente |
| Alta | Medir rendimiento | Modo profile, 200 bolas y 100 pilas, tres jornadas y revisión tras diez ciclos; objetivo de 60 FPS aún sin verificar |
| Media | Completar audio y volumen | Recursos propios con licencia, silencio y control independiente; prueba real por destino |
| Media | Completar presentación | Aceptación táctil del árbol existente, respuesta visual final e iconos de instalación propios |
| Según necesidad | Ampliar pruebas de integración y robustez | Añadir regresiones de errores observados, recuperación y evolución de esquema antes de declarar garantías más amplias |

La carga de partículas de la especificación solo podrá medirse cuando exista ese sistema. No se registra como prueba realizada.

## Fuera de este MVP

Sin backend, cuentas, nube, clasificación, monetización, prestigio, recompensas por tiempo cerrado, múltiples tableros, varios robots, robot recolector de dinero ni monedas especiales. iOS y escritorio nativo no están configurados como destinos de esta entrega. Una versión firmada para tienda no forma parte de la pipeline actual.
