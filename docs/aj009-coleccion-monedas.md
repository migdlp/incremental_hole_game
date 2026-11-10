# AJ-009 — Colección de monedas de la jornada

Versión: **0.20.0+33**. Implementación sobre BUG-001, BUG-002 y AJ-007.
El usuario aprobó el aspecto de las pilas el 25-10-2026: «Exacto así».
[Imagen aprobada del render de Cloud](previews/aj009-pilas-aprobadas.png).
No es una captura Android; el helper de previsualización usa una fuente de Cloud.

## Presentación aprobada

Se elimina el saldo numérico del gameplay y su destino de vuelo anterior.
Una franja fija queda inmediatamente bajo el temporizador y sobre el tablero.
No aparece texto, otro contador ni un roadmap. Tienda y resultados conservan
sus saldos necesarios para comprar y presentar las recompensas.

Las monedas **se superponen**, en lugar de formar filas de círculos separados.
Cada pila mantiene el mismo eje horizontal: la siguiente moneda queda 2,5 unidades
más arriba, mostrando las capas inferiores. Sus caras se dibujan ovaladas para
simular monedas sobre una mesa, con profundidad hecha en 2D. Se utiliza el pintor
original y se conservan colores, denominaciones y orden de llegada; no se ordenan
por valor. La moneda se adapta suavemente a esa perspectiva al terminar el vuelo.

Referencia actual: hasta diez capas por pila, adaptadas al espacio disponible.
Diámetro de cara 16, escala vertical 0,55; la separación vertical es menor que su
altura para que no existan huecos. Al completar la pila se comienza otra a la
derecha, con separación horizontal constante. La franja tiene su altura reservada
desde el inicio, incluso vacía: no desplaza el tablero al recibir monedas.
Estos valores son iniciales, no un balance definitivo de rendimiento.

## Reservas y llegada

Cada objeto visual emitido por BUG-002 reserva un índice consecutivo. Un paquete
que representa varias monedas por rendimiento ocupa una sola posición, guardando
su cantidad representada. El índice se convierte en columna/capa en O(1).
La expulsión angular, microlotes, denominaciones y reglas de agrupación no cambian.

Se conservan el salto de salida, la pausa de un segundo y el vuelo curvo acelerado.
El destino es ahora el centro exacto de la capa reservada. Las duraciones variables
se alinean mínimamente para que las llegadas sigan el orden de emisión, sin huecos
en el prefijo colocado. Las monedas anteriores no se recolocan al llegar otra.
Varias pueden seguir volando a la vez; BUG-002 continúa limitando nuevas salidas a
una por fotograma real. Los eventos de llegada alimentan AJ-007 una única vez.

El render de vuelo utiliza una capa Flutter sobre Flame, porque el destino queda
fuera del recorte del tablero. `IgnorePointer` deja pasar los gestos; pausa,
herramientas y estrellas conservan sus controles. El modal de pausa queda por
encima de los vuelos. La capa de monedas posee su propio `RepaintBoundary`.

## Ciclo de jornada y economía

La colección es exclusivamente visual. `DailyCoinCollection` no tiene acceso al
saldo ni acredita dinero. El registro económico y el plan BUG-001 siguen siendo
la fuente de importes y del desglose de resultados. Los objetos visuales no son
unidades económicas: ni contarlos ni sumar las caras modifica los ingresos.

- Nueva jornada: nuevo objeto de presentación e identidad `runId:día`; comienza
  vacía en la primera capa, conservando el dinero bancado.
- Compras: solo cambian el saldo económico; la colección no se reduce.
- Prestigio: elimina la colección temporal y sus vuelos conforme al reinicio ya
  existente, sin modificar estrellas ni reglas permanentes.
- Pausa/segundo plano: detienen reloj, reservas, colocación y transición visual.
- Fin de producción: cobra lo pendiente con el registro económico, corta nuevas
  emisiones y abre resultados inmediatamente. Los vuelos existentes pueden
  completar hasta 0,45 s durante la transición; después se resuelven sus reservas.
  No se crea una fase de recogida, no se bloquea el cierre y no se crean objetos
  adicionales para lo que todavía no había sido emitido.
- Empezar otra jornada cancela cualquier transición anterior. La identidad de
  jornada rechaza llegadas antiguas, aunque coincidan sus índices.

El resumen AJ-008A conserva su animación independiente y su propio monedero. Usa
su colocación de reserva cuando ya no existe el antiguo anclaje del gameplay;
sus importes, saltos y navegación no se rediseñan.

## Persistencia

Balance **v20** y formato raíz **JSON v14** conservados. La extensión opcional
`run.rewardPresentation.collection` guarda identidad, prefijo colocado y pares
`[denominación, cantidad representada]` en el orden real de emisión.

Restaurar conserva las monedas ya emitidas y resuelve sus reservas en la colección,
sin repetir vuelos antiguos, sonidos ni pagos. Las siguientes emisiones reservan
índices posteriores. No se reconstruye a partir del saldo total. Lo que aún no
había sido emitido conserva la política de liquidación económica anterior.

Un guardado anterior sin colección mantiene todo su dinero/progreso y comienza
la colección con nuevas emisiones; no se inventa el orden que no estaba guardado.
Los datos visuales se validan contra denominaciones y recuentos de la jornada.
Si esta extensión opcional está dañada o pertenece a otro día, se descarta solo
la colección, conservando el guardado económico válido. Las validaciones
financieras y de progreso existentes permanecen intactas.

## Saturación visual y rendimiento

No hay cuerpos físicos ni widgets por moneda. El pool de vuelos de BUG-002 se
reutiliza, independiente de las monedas ya colocadas. La colección estática usa
un `Picture` reutilizable: solo se registra de nuevo al cambiar el prefijo visible,
la geometría, la jornada o el nivel de detalle. La calidad gráfica existente puede
simplificar detalles sin cambiar monedas, colores ni importes.

No se implementan compactación, otro contador, escalado al llenarse ni scroll.
Al exceder las celdas completas visibles se recorta la presentación: los datos
siguen registrados en orden y el dinero permanece intacto. El diseño definitivo
del desbordamiento sigue **fuera de alcance**. Cambiar de resolución recalcula
la geometría; la llegada de monedas no cambia el tamaño del tablero.

La duración de jornada y el máximo de una emisión por paso limitan las reservas
reales; la colección se libera al cambiar de jornada o reiniciar. Restaurar aplica
además un límite de seguridad de 100000 registros visuales, superior a los que
pueden emitirse durante las jornadas válidas, sin limitar dinero ni recompensas.

## Archivos

- `daily_coin_collection.dart`: reservas, prefijo ordenado, identidad, validación y geometría.
- `reward_delivery.dart`: enlace de cada vuelo con su reserva y cierre visual.
- `collection_painter.dart`: pilas, cache estática y vuelo hacia capas reservadas.
- `game_app.dart`: franja adaptable, retirada del saldo y capa de render/transición.
- `game_session.dart`: ciclo, notificación de pintura, restauración y liquidación.
- `garden_game.dart`: delega las monedas al overlay externo en el gameplay normal.
- `daily_coin_collection_test.dart`: once pruebas nuevas de dominio, integración y UI.
- Pruebas actualizadas del HUD anterior: `automatic_reward_ui_test.dart`,
  `star_bubbles_test.dart`, `ui_economy_test.dart`, `version_adjustments_test.dart`,
  `visual_feedback_test.dart`.
- Herramientas: `benchmark_daily_collection.dart`, `benchmark_daily_collection_paint.dart`,
  `preview_daily_collection.dart`; perfiles y captura bajo `docs`.
- Versión/documentación: `pubspec.yaml`, README, estado, relevo y CHANGELOG.

## Validación

Pipeline completa correcta con el apilado aprobado: **424 pruebas**, formato,
análisis, compilación Android y verificación de firma. Once pruebas nuevas de
colección; previsualización y benchmark de pintura correctos.

Validación publicada: **424 pruebas correctas**, formato, análisis, compilación y firma.
Código `6f83f479b1d2e82d5c8e33fa538fb05956822c0d`, con `046ebb0` conservado en el historial.
[APK 0.20.0+33 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40184781696/artifacts/12596006493) · [Pipeline](https://github.com/migdlp/incremental_hole_game/actions/runs/40184781696) · [Registros](https://github.com/migdlp/incremental_hole_game/actions/runs/40184781696/artifacts/12596281025).
Prueba de actualización sobre APK anterior omitida por la configuración habitual;
compatibilidad de instalación entre APKs no verificada en esta ejecución.


Se prueban primera capa, columna siguiente, superposición sin huecos, distintos
colores, orden, captura masiva, 500 reservas, clipping, cache, final de jornada,
segundo plano, restauración, compras, prestigio y resoluciones 280×480, 320×568,
360×800 y 432×960. Las pruebas económicas existentes siguen verificando ausencia
de cobros dobles y pérdida de recompensas.

### Medidas Cloud

Los JSON completos están en `docs/performance/aj009-collection-model.json` y
`aj009-collection-paint.json`. AOT, serializar 500 monedas: p95 231 µs,
p99 317 µs, pico 341 µs, JSON de 3636 bytes. Para 2000: p95 606 µs,
p99 811 µs, pico 1123 µs y 14437 bytes. Son costes de la colección, no de todo
el guardado. RSS incluye el proceso y sus asignaciones de prueba.

La pintura mide comandos y raster de imágenes fuera de pantalla, con 60 muestras
por cantidad y calentamiento. Para 500 registros se dibujan 200 celdas visibles;
la imagen estática se registra una sola vez mientras no cambia su contenido.
P95 de comandos: 652 µs; p99/pico: 7922 µs. Raster asíncrono: p95 8953 µs,
p99/pico 38480 µs. Se conservan esos picos: no permiten certificar 60 FPS.
RSS del proceso Flutter de esa muestra: 166,64 MB, incluyendo motor y caches;
no equivale a memoria atribuible a la colección ni a consumo Android.

```sh
dart --suppress-analytics compile exe tool/benchmark_daily_collection.dart -o /tmp/collection-bench
/tmp/collection-bench
flutter test tool/benchmark_daily_collection_paint.dart
flutter test tool/preview_daily_collection.dart
```

Pendientes: pruebas de movimiento, FPS, CPU/GPU y memoria en Android físico.
Los tiempos de Cloud no son GPU del teléfono ni una garantía de estabilidad.
