# BUG-002 — Expulsión secuencial y dispersión orgánica

Versión **0.19.1+31**. Implementado sobre AJ-007/BUG-001.
Balance v20 conservado. BUG-002 no modifica el formato de guardado; conserva
el JSON v14 incorporado por AJ-005B en la rama remota. No cambian los importes,
las denominaciones, el plan de monedas, las cuotas ni el resumen AJ-008A.
Validación artística y medición en Android físico pendientes.

## Causa encontrada

`RewardCoin.reset` alternaba el signo horizontal según paridad y el vertical
según módulo tres: unas pocas familias de dirección dominaban la salida.
`RewardVisuals._drain` llenaba todos los huecos en un bucle y repetía el retraso
cada 24 objetos. Cada microlote volvía a iniciar ese patrón. Además, varios pasos
de simulación podían coincidir dentro de un fotograma real.

## Solución

Un emisor único consume los recuentos pendientes compartidos por denominación.
Cada emisión tiene identidad, instante y ángulo propios. Se inicia como máximo
un objeto por actualización y por fotograma de Flame, incluso si ese fotograma
procesa varios pasos de física. No se recuperan retrasos emitiendo muchas monedas
a la vez. Las que ya salieron siguen volando simultáneamente.

La carga pendiente suavizada acelera progresivamente la cadencia y el giro.
Tandas pequeñas usan pasos angulares variables y evitan las tres direcciones
recientes. La transición a la rotación es gradual; las tandas densas avanzan
siempre en sentido horario con velocidad angular configurable y variación leve.
Una pausa real entre oleadas permite otro comienzo aleatorio. Los microlotes
nuevos se integran en la secuencia existente sin reiniciar su ángulo.

Los orígenes giran dentro de la geometría actual del hoyo. Distancia, origen y
salto varían; cerca de los bordes se limitan los desplazamientos y la curvatura
para mantener visibles las monedas. Se conservan el dibujo, el salto, la pausa
inmóvil de un segundo y el vuelo curvo acelerado al monedero. No hay física de
monedas ni nuevos cuerpos, widgets por moneda o colisiones.

Los eventos de salida y llegada siguen entregando cantidades representadas a
AJ-007, que aplica sus límites de voces, agrupación y háptica. No se reproduce
un sonido independiente por cada unidad económica.

## Economía, saturación y guardado

`planCoins` y el registro económico no se modifican. Los recuentos del resumen
siguen siendo los calculados por BUG-001. Los paquetes agrupados conservan su
cantidad y valor; el número de iconos no acredita dinero.

La cola es un mapa acotado por el número de denominaciones, no una lista de
objetos de tamaño ilimitado. La agrupación tiene en cuenta capacidad física del
pool, vida de la animación y la restricción de una salida por fotograma. Se puede
agrupar con monedas de la misma denominación aún en salto/reposo; no se cambia
el aspecto ni se teletransporta una moneda que ya vuela al monedero.

Una corriente pequeña continua no se agrupa por llevar mucho tiempo activa:
la presión se calcula con cantidad pendiente y capacidad de servicio. Se prueba
expresamente que 300 monedas pequeñas consecutivas salen como 300 objetos.
La espera deja de crecer al cesar las capturas y la cola se vacía; el cierre de
jornada no espera a la cola: liquida el registro económico y descarta sus efectos.

Pausa: reloj, próximo instante, ángulo, cola y animaciones permanecen congelados.
Restauración en frío: conserva la política anterior de liquidar recompensas
pendientes una sola vez, sin volver a emitir sus animaciones ni sus sonidos.
No se introduce un segundo registro de pagos ni se reproduce el pasado.

## Parámetros provisionales y DEBUG

`RewardVisualConfig` centraliza parámetros y rangos. Los nuevos parámetros son
solo de presentación y no se añaden a los ajustes guardados de jornada; los
valores v20 y el CSV de balance permanecen idénticos a la versión publicada.

- Intervalos iniciales: 8,3–75 ms, limitados además por los fotogramas disponibles.
- Giro inicial: 2–24 rad/s; carga de referencia 24 monedas pendientes.
- Variación angular: 12 %; separación pequeña: 0,85 rad.
- Salto inicial: 38 unidades, con variación y adaptación a bordes.
- Pool inicial: 192, provisional. DEBUG permite probar capacidad hasta 1024.
- Presión temporal de agrupación inicial: 5 s de servicio estimado y edad media
  ponderada por denominación. Es un umbral,
  no una garantía exacta de latencia por captura.
- El presupuesto sigue reduciendo detalles/curvas antes de limitar objetos según
  los tiempos de renderizado; se recupera con histéresis cuando mejora la carga.

A 60 FPS, una sola salida por fotograma permite como máximo 60 nuevos objetos/s;
500 salidas individuales necesitan al menos 8,33 s. En el bucle actual la física
avanza a 60 Hz, que también limita el máximo en pantallas más rápidas. Bajo una
entrada superior se agrupan representaciones preservando el plan completo.
No se intenta aparentar simultaneidad creando centenares de salidas en un frame.

DEBUG está en el botón superior izquierdo de Tienda. Los controles de lluvia
incluyen capacidad, cadencia, giro, separación, dispersión y vuelo. Los cambios
son temporales y no alteran la partida real. Se mantienen los presets de captura
existentes; no se añaden denominaciones ni se modifica su catálogo.

## Archivos

- `reward_delivery.dart`: emisor, direcciones, cola y curvas reutilizadas.
- `reward_visual_config.dart`: parámetros, rangos y validación.
- `game_session.dart`: límite por fotograma, geometría real y parámetros DEBUG.
- `skill_tree_screen.dart`: valores DEBUG de configuración exclusivamente visual.
- `sequential_coin_emitter_test.dart`: pruebas nuevas de secuencia/integración.
- `coin_rain_test.dart`, `currency_test.dart`: esperan expulsión progresiva en
  lugar de todos los objetos dentro del primer microlote; conservan las
  comprobaciones económicas y de denominaciones.
- `tool/benchmark_sequential_coins.dart`: medidas del emisor con el plan real.
- `docs/performance/bug002-*.json`: perfiles comparativos y de carga.
- `pubspec.yaml`, README, estado, relevo y CHANGELOG: versión y entrega.

## Validación y pendientes

Las pruebas comprueban una salida por fotograma, captura aislada a 200 ms,
siete monedas exactas para 34, cobertura angular, variación por oleada, giro
horario y su velocidad efectiva, continuidad entre microlotes, origen en hoyos
de varios tamaños, bordes, reutilización, saturación, pausa, cierre,
restauración, configuración y aislamiento de DEBUG. Se conserva la batería
anterior de economía, sonido y resultados.

Las pruebas Cloud no sustituyen Android físico: pendientes FPS reales, tiempo
GPU/CPU del dispositivo, memoria, frame pacing y valoración visual/sonora.
El límite inicial no constituye un balance definitivo ni una certificación
universal de 60 FPS.

## Revisiones automáticas y alternativa aplicada

La revisión automática rechazó ampliar presets DEBUG de capturas al interpretarlo
como un cambio de denominaciones; se conservaron los presets anteriores.
También rechazó crear una versión de balance para congelar ajustes antiguos,
por riesgo de cambiar la persistencia fuera del alcance. La alternativa aplicada
mantiene el balance y el formato de guardado intactos, separando los parámetros
nuevos de presentación. No se aplicaron los cambios rechazados ni quedó una
migración pendiente necesaria para utilizar la función.

Validación local antes de integrar cambios remotos: 422 pruebas completas,
13 pruebas del emisor y 27 económicas correctas, análisis y formato correctos.
La imagen de diagnóstico usa `tool/preview_sequential_coins.dart` con el pintor
real de monedas; es un render de Cloud, no una captura Android.


Integración: durante el trabajo la rama avanzó hasta `2407458` (PR #19,
AJ-005B). Se integró mediante merge, conservando sus cuotas, crecimiento,
prestigio y migración v14. Los conflictos de documentación conservan ambas
entregas; el bucle mantiene tanto la detección de cuotas como el límite de una
emisión visual por fotograma. Se repite la validación sobre el conjunto integrado.


## Validación integrada y medidas Cloud

Sobre AJ-005B: **412 pruebas completas** correctas, análisis sin incidencias y
formato correcto. Las 13 pruebas nuevas del emisor siguen presentes; la cantidad
total cambia respecto al conjunto anterior porque AJ-005B sustituye pruebas de
las antiguas reglas de cuotas/derrota. La previsualización fuera de pantalla
pasó además como prueba optativa del pintor real.

Comparación AOT con `2407458` como base, 2880 muestras por escenario.
Tiempos de pared de CPU del modelo, curvas y, donde se indica, tablero con
200 bolas/escoba/bate/lanzador; no son tiempos GPU ni FPS Android:

| Escenario | Antes p95 / p99 / pico (ms) | Después p95 / p99 / pico (ms) |
|---|---:|---:|
| Capturas repetidas, monedas | 0.003 / 0.042 / 1.256 | 0.011 / 0.048 / 34.905 |
| Con tablero cargado | 2.707 / 4.754 / 91.778 | 3.920 / 13.255 / 466.510 |

Se conservan los picos, incluido **466,5 ms** del modelo cargado posterior.
Estas medidas de un host Cloud compartido no permiten atribuir cada pausa al
emisor ni certificar ausencia de tirones. El emisor aislado, con el plan real,
midió p95 25 µs, p99 58 µs y pico 662 µs en la corriente de importe 3400 cada
200 ms. No se cambió la física para alterar el benchmark.

- 4 monedas aisladas: cuatro objetos, última salida a 0,45 s.
- Corriente pequeña de 300: 300 objetos, cero agrupaciones ni omisiones.
- Corriente extrema: 38850 monedas planificadas se representaron mediante
  1111 objetos a lo largo de 15 s de capturas y su cola posterior. Pico de
  120 objetos activos, una salida máxima por fotograma, sin omisiones y sin
  pendientes al terminar la prueba de 25 s. Última salida a 18,87 s.
- Los recuentos agrupados más los objetos emitidos conservan siempre la cantidad
  del plan. La cola tardía agrupa por edad media de cada denominación, evitando
  tanto la espera creciente como agrupar una corriente pequeña solo por durar.
- RSS del proceso aislado hasta 9,73 MB; no es memoria Android ni atribución exacta
  a las monedas. Los JSON conservan CPU, colas, simultaneidad y RSS completos.

Reproducción:

```sh
dart --suppress-analytics compile exe tool/benchmark_reward_visuals.dart -o /tmp/coin-model
/tmp/coin-model
dart --suppress-analytics compile exe tool/benchmark_sequential_coins.dart -o /tmp/coin-sequence
/tmp/coin-sequence
flutter test tool/preview_sequential_coins.dart
```

La última orden escribe `/tmp/bug002-preview.png`, un diagnóstico del emisor y
pintor. No sustituye la revisión del movimiento, GPU, FPS y sonido en Android.


## Entrega

Código compilado: `038f026356f0df429cb723ebd780bc199666149c`.
[Pipeline 40142624007](https://github.com/migdlp/incremental_hole_game/actions/runs/40142624007):
**correcta**, con 412 pruebas, formato, análisis, compilación Android y firma.

[APK 0.19.1+31 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40142624007/artifacts/12578883845).
Artefacto `feed-the-hole-debug-apk`, 147054756 bytes, caduca 2026-11-07.
[Registros](https://github.com/migdlp/incremental_hole_game/actions/runs/40142624007/artifacts/12579123483).
Identificador Android `com.migdlp.incremental_hole_game` conservado; la comparación
de actualización con APK anterior se omitió por no pasar referencia, por lo que
verificar la firma actual no certifica compatibilidad con otra instalación.

`046ebb0` permanece como antecesor y AJ-005B (`2407458`) está integrado. Publicación
normal, sin force push ni reinicio del workspace. Escucha, movimiento real y
medidas de GPU/FPS/memoria en Android físico continúan pendientes; los parámetros
siguen siendo provisionales.
