# BUG-001 — Microlotes y lluvia de monedas (0.18.1+29)

Validado: formato, análisis y **392 pruebas**, compilación Android y firma.
Código compilado `d41b711`; [APK 0.18.1+29 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40118367557/artifacts/12569447730). Incluye AJ-008A y BUG-001.

Funcionalidad implementada, con AJ-008A incluido. **La medición en Android físico
sigue pendiente**: Cloud no tiene dispositivo ni GPU Android conectados. Los
valores visuales son provisionales; no se certifican 60 FPS con estas mediciones.

## Diagnóstico

C01 creaba como máximo un icono por captura. Su importe solo elegía un color;
no se descomponía en monedas. Un pool de 24 podía reducirse a 1 tras cinco frames
lentos y recuperar un puesto cada dos segundos: más de una jornada para volver
a su capacidad inicial. La espera previa de un segundo retenía además los iconos.

## Cambios

- Microlote de **0,2 s de simulación**, iniciado por la primera captura pendiente.
  Al cerrarse se emiten monedas, sin esperar otra captura. La oleada se escalona
  hasta 0,12 s: primera expulsión normal entre 0,2 y 0,32 s. Pausa congela el reloj.
- 34 produce exactamente **3 monedas de 10 y 4 de 1** con capacidad libre.
  Importe cero no produce iconos.
- Desglose entero exacto, consultando las denominaciones existentes. En importes
  grandes se sustituyen monedas grandes por equivalentes menores. Los recuentos
  permanecen acotados a una entrada por denominación, incluso con importes enormes.
- Pool inicial provisional de **192 componentes reutilizables**. 50.000 produce
  más de cien monedas de varios tipos sin agrupación con el pool libre.
- Primero baja el detalle y se simplifican curvas tras muestras sostenidas de
  coste real build/raster; después disminuye el presupuesto. Un pico aislado no
  destruye la capacidad. La recuperación es gradual con muestras saludables.
- Si el pool se llena, se solapan oleadas. Solo al superar la capacidad de espera
  se agrupa, conservando denominación, cantidad e importe de cada paquete. Nunca
  se recolorea una moneda agrupada según su importe total.
- Pendientes representados por cinco contadores, sin listas ilimitadas de trabajos.
  Al cerrar la jornada se procesa el microlote incompleto y se liquida la economía,
  sin esperar animaciones ni bloquear la navegación.
- Se conserva el salto, la curva S y **la pausa de un segundo tras aterrizar**
  aprobada anteriormente. Se elimina el segundo de espera **antes** de expulsar.
  Las monedas siguen sin cuerpos físicos ni interacción táctil.

## Economía, estadísticas y persistencia

`RewardDelivery` continúa registrando una vez cada recompensa autorizada. Los
iconos no calculan, pagan ni multiplican dinero. La recepción usa ese registro;
liquidar, omitir una animación o restaurar no duplica ni pierde ingresos.

El resumen AJ-008A utiliza las denominaciones calculadas por los microlotes,
antes de cualquier agrupación visual. Esto sustituye el desglose por captura
individual de la primera implementación AJ-008A. Se guardan recuentos procesados,
importe y edad del microlote abierto, con validación frente al ingreso generado.
Al restaurar se puede cerrar la presentación sin reproducir todos los vuelos;
el registro económico se liquida exactamente una vez como en C01.

Guardados anteriores sin estos datos conservan el importe y usan un desglose
exacto de su total histórico. JSON v13 continúa compatible. Balance v20 con v19
congelado: jornadas interrumpidas conservan su configuración física/económica.
No se modifican tiers, valor, racha, costes, cuotas, prestigio ni el diseño AJ-008A.

## Configuración y DEBUG

Los parámetros están centralizados en `docs/balance.csv`, validados por
`RewardVisualConfig`. Ventana, objetivo de lluvia, umbral de importe grande,
pendientes antes de agrupar, separación de oleada, espera máxima, pausa, duración,
variación, muestras, umbral y recuperación pueden probarse en DEBUG sin guardar.
`reward_visual_limit` controla el tamaño del pool; 192 es un punto inicial basado
en Cloud y se debe afinar en el dispositivo. DEBUG permite comparar presupuestos
menores sin recompilar, y CSV permite ampliar el pool sin cambiar la lógica.

Tienda → DEBUG → «Monedas automáticas · rendimiento»:

1. Elegir captura inicial de 1/10/50/100/200 bolas y el presupuesto visual.
2. Ajustar parámetros; empezar el día. Comprar herramientas/producción en DEBUG
   permite observar también el tablero cargado y las tandas repetidas.
3. Consultar/exportar p95/p99, máximo de la jornada y frames >16,67 ms, además de
   pico, agrupadas y omitidas. El máximo conserva los picos iniciales aunque salgan
   de la ventana circular de 240 muestras. Raster es un proxy del hilo de raster,
   **no una medición directa de GPU**.
4. Salir de DEBUG restaura la partida real y descarta parámetros y capturas de prueba.

## Medición en Cloud

Antes: código `78abc44`, pool 24, icono por captura. Después: pool 192, microlotes.
`tool/benchmark_reward_visuals.dart` se compiló a ejecutable Dart AOT y se ejecutó
secuencialmente, sin solapar las dos mediciones. 2.880 muestras por caso: una
captura, diez, cincuenta, cien, tandas repetidas y 200 bolas con herramientas.
Las capturas sintéticas de este benchmark aportan 34 cada una, para comparar
densidad visual; el caso real de valor 1 está cubierto por las pruebas.
Las cifras son tiempos transcurridos del modelo/curvas/colisiones en Cloud,
con ruido de planificación del host; **no son tiempo completo de frame Flutter**.

| Caso | Pico de iconos antes → después | p95 modelo antes → después (µs) | p99 antes → después (µs) |
| --- | ---: | ---: | ---: |
| 1 capturas | 1 → 7 | 0 → 1 | 0 → 4 |
| 10 capturas | 10 → 102 | 0 → 3 | 2 → 24 |
| 50 capturas | 24 → 126 | 1 → 2 | 2 → 16 |
| 100 capturas | 24 → 135 | 0 → 2 | 1 → 27 |
| 100 capturas repetidas | 24 → 192 | 0 → 4 | 3 → 52 |
| 100 capturas repetidas + tablero cargado | 24 → 192 | 1890 → 4040 | 3381 → 13133 |

Los JSON completos conservan máximos, RSS y cantidades agrupadas/omitidas:
[antes AOT](performance/bug001-before-aot.json) y
[después AOT](performance/bug001-after-aot.json). RSS incluye el runtime y el
modelo del tablero; no representa solo memoria de las monedas ni un ahorro
certificado. La variación entre ejecuciones impide atribuir cada pico al cambio.

`tool/benchmark_coin_paint.dart` mide registro de comandos y rasterización
asíncrona de imágenes fuera de pantalla a 360×560, con 100 muestras por tamaño,
10 de calentamiento y objetos de moneda reutilizados (cero recreados por frame).
Estos tiempos son de Cloud y **no miden GPU Android ni FPS de pantalla**.

| Iconos | p95 comandos (µs) | p95 raster fuera de pantalla (µs) | p99 raster (µs) | Máx raster (µs) |
| --- | ---: | ---: | ---: | ---: |
| 1 | 104 | 657 | 762 | 1390 |
| 10 | 386 | 1353 | 2177 | 2258 |
| 24 | 245 | 1403 | 1490 | 1591 |
| 50 | 507 | 2038 | 2317 | 5205 |
| 100 | 868 | 4805 | 6032 | 7313 |
| 128 | 923 | 4428 | 5181 | 6194 |
| 192 | 1165 | 6277 | 7043 | 8384 |
| 256 | 2248 | 10188 | 16839 | 21478 |
| 512 | 3438 | 16156 | 18871 | 19745 |

[Datos de dibujo y memoria](performance/bug001-offscreen-paint.json).
192 deja más margen que 256/512 en esta prueba y sigue dando una lluvia abundante.
No se suman estas mediciones separadas para anunciar FPS de la aplicación.

Reproducción del candidato: `dart compile exe tool/benchmark_reward_visuals.dart`
y ejecutar desde la raíz del proyecto; opcionalmente pasar un tamaño de pool.
Dibujo: `flutter test --no-pub tool/benchmark_coin_paint.dart` (opt-in).
Para la referencia anterior se extrajo `78abc44` a una carpeta temporal, usando
su constructor anterior sin el argumento `config`; no se modificó ni reinició
el workspace del juego.

## Archivos principales

`reward_delivery.dart` gestiona microlotes/pool y `coin_plan.dart` el desglose.
`reward_visual_config.dart`, catálogo/CSV y `balance_v19.dart` centralizan y migran
los parámetros. `game_session.dart` registra/persiste la presentación, mientras
`garden_game.dart` y `coin_painter.dart` dibujan sus denominaciones reales.
`game_app.dart` y `reward_frame_metrics.dart` recogen coste de frames; el panel
DEBUG está en `skill_tree_screen.dart`. `coin_rain_test.dart` cubre este contrato;
se actualizan pruebas de versiones y del resumen. Los dos benchmarks opt-in y sus
JSON están en `tool/` y `docs/performance/`. README, estado, relevo, C01, AJ-008A,
CHANGELOG y pubspec reflejan la entrega.

## Pruebas y límites pendientes

Pruebas de igualdad de valor para 0–5.000, importes máximos y denominaciones
alternativas; ventanas y fronteras de 200 ms; siete monedas para 34; variedad en
50.000; saturación, pausa, guardado, final de jornada, estadísticas, aislamiento
DEBUG y retención de picos. Validación: **392 pruebas** completas y el benchmark de dibujo opt-in correctos.
Análisis y pipeline Android correctos en la entrega enlazada al comienzo.

Para cerrar la aceptación de rendimiento se necesita Android físico en modo
profile: CPU y GPU por frame, p95/p99/máximos, frames perdidos, GC y memoria con
DevTools/Perfetto. Repetir 1/10/50/100 capturas, tandas y tablero cargado con
presupuestos 64/128/192 y, si hay margen, ampliar mediante CSV. La APK debug sirve
para pruebas funcionales y visuales, no para certificar rendimiento de producción.
La fidelidad de AJ-008A al mockup original sigue pendiente porque no estaba adjunto.
