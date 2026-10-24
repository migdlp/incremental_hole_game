# BUG-002 — Expulsión secuencial y dispersión orgánica

Versión **0.19.1+31**. Implementado sobre AJ-007/BUG-001.
Balance v20 y guardados JSON v13 sin cambios. No cambian los importes,
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
- Presión temporal de agrupación inicial: 5 s de servicio estimado. Es un umbral,
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
