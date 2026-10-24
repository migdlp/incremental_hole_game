# AJ-008A — Resultados animados (0.18.0+28)

Validado: formato, análisis y **392 pruebas**, compilación Android y firma.
Código compilado `d41b711`; [APK 0.18.1+29 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40118367557/artifacts/12569447730). Incluye AJ-008A y BUG-001.

Implementado conforme a la especificación textual. La imagen del mockup y el
vídeo de referencia no estaban adjuntos en esta tarea: **pendiente comparar
fidelidad visual con esos originales**, además de la validación en Android físico.

## Presentación

Tablero congelado y oscurecido, modal azul marino, dos tarjetas, tipografía clara,
recompensas doradas y alimentación menta. Se conserva la posición del monedero
mediante el anclaje real del HUD; el contador anterior queda oculto durante el
modal. No existe otro monedero dentro de las tarjetas.

Las cinco denominaciones reales siguen valiendo 1/10/50/100/500. La paleta
compartida pasa a bronce/plata/oro/verde/rojo. No se inventa una sexta denominación.
No se modifican el salto ni la pausa ni la física de las monedas del gameplay.

## Integración posterior BUG-001 (0.18.1+29)

El desglose por captura descrito en la primera implementación se sustituye por
el desglose de microlotes de 200 ms. La agrupación visual del gameplay no cambia
los recuentos del resumen ni su total. El diseño y la secuencia de este documento
se conservan. [Funcionamiento y rendimiento](bug001-lluvia-monedas.md).

## Datos y contabilidad

`ResultsData` toma una copia inmutable de `DayResult`, `FeedingProgress` y saldo.
Los días nuevos registran el desglose de cada recompensa mediante
`CoinDenomination.split`, sumado por denominación y guardado junto a la jornada.
Los días históricos que guardaron recuentos usan esos recuentos. Las jornadas
anteriores sin ese detalle representan su importe histórico mediante una
descomposición exacta del total, sin inventar cantidades económicas.
La suma de subtotales debe coincidir con el ingreso o se rechaza el desglose.

El monedero mostrado comienza en saldo final menos ingreso de la jornada y
avanza hasta el saldo final. **La presentación no accede a pagos ni a guardados**.
Reabrir, saltar, completar o abandonar la secuencia no vuelve a acreditar dinero.
Si se reabre un resultado histórico después de gastar su ingreso, el monedero
conserva el saldo actual durante la reproducción, sin simular un saldo negativo.

El anillo interpola alimentación previa (`points - runNormal - runInstant`) y
actual, dividida por el objetivo y limitada visualmente a 1. Los puntos reales
conservan cualquier exceso. El contador de bolas usa `DayResult.captured`, no
puntos ni dinero. Se muestra el objetivo siguiente únicamente al terminar un
período cumplido. Las reglas de cuotas, derrota, prestigio y crecimiento AJ-005A
permanecen intactas; una derrota conserva su pantalla S03 existente.

## Secuencia

1. `opening`: apertura suave de 0,22 s.
2. `coins`: filas en orden creciente, 1,2 s por denominación con cantidad no nula.
   Revelación/icono, conteo, y hasta seis paquetes visuales por fila. Cada paquete
   representa una parte exacta de su subtotal; su llegada produce el incremento
   visual correspondiente y un pulso del monedero. Las curvas se recalculan con
   los rectángulos reales de origen y destino. No existe una cola ilimitada.
3. `hole`: aparece la segunda tarjeta; durante 1,4 s caen hasta cinco bolas
   decorativas, aumenta su contador y avanza el anillo desde el valor anterior.
4. `completed`: cifras definitivas y botón Tienda dorado que abre la navegación
   existente, sin cambiar las reglas de compra ni el inicio de la siguiente jornada.

Tocar el modal completa solo el bloque activo. Identidad de fase y un intervalo
breve de protección evitan saltos dobles por toques simultáneos, rápidos o en un
cambio automático. El botón tiene su propio gesto, sin activar el salto del padre.
Movimiento reducido revela el resultado completo sin animaciones. Segundo plano
congela el ticker; dispose libera ticker, controlador y scroll.

La tarjeta se desplaza para mantener visible la fila activa y, al terminar, el
bloque del hoyo. Tienda permanece fuera del scroll. Cifras grandes usan formato
español y representación compacta, sin cambiar su valor interno.

## Archivos

- `lib/features/results/domain/results_data.dart`: copia y desglose de resultados.
- `lib/features/results/domain/results_sequence.dart`: fases, conteos y saltos.
- `lib/features/results/presentation/results_overlay.dart`: tarjetas, HUD y hoyo.
- `lib/features/results/presentation/results_transfer.dart`: vuelos entre anclajes.
- `lib/app/game_session.dart`: recuentos de presentación por captura y su persistencia, sin pagos adicionales.
- `lib/app/game_app.dart`: integración, ocultación del HUD anterior y retirada del resumen antiguo.
- `lib/features/board/presentation/coin_painter.dart`: nueva escala cromática.
- `test/features/results_redesign_test.dart`: pruebas específicas de secuencia y UI.
- `test/features/day_results_test.dart`, `test/features/ui_economy_test.dart`,
  `test/features/feeding_test.dart`, `test/widget_test.dart`: expectativas actualizadas.
- `pubspec.yaml`, `CHANGELOG.md`, `README.md`, `docs/estado-actual.md`,
  `docs/relevo-contexto.md` y este documento: versión y entrega.

## Validación y pendientes

Pruebas de orden, cantidades grandes, ingreso cero, alimentación previa/exceso,
objetivo siguiente, saldo intacto, saltos, movimiento reducido, posición real de
los iconos y navegación. Captura revisada en formato 390×844; layout comprobado
en 320×568 con texto ampliado. Rendimiento de CPU/GPU y fluidez en Android físico
pendientes; no se afirma una medición real de 60 FPS.
