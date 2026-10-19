# Economía y monedas

Referencia de la implementación 0.3.3+8. La única tabla editable de precios, efectos y requisitos es [balance.csv](balance.csv). El ritmo de compra sigue siendo provisional.

## Valor y denominaciones

Una bola capturada genera **$1 de base**. El dinero se ingresa al recoger la moneda, no al capturar la bola. Saldo, precios y estadísticas muestran importes en dólares del juego; las monedas físicas no llevan cifras, cantidades, símbolos ni texto en la cara.

| Denominación | Color |
| --- | --- |
| $1 | Amarillo/dorado `#EAB308` |
| $10 | Verde esmeralda `#10B981` |
| $50 | Azul `#3B82F6` |
| $100 | Violeta `#A855F7` |
| $500 | Coral `#F43F5E` |

No existe moneda de $25. Las pilas conservan un importe entero y se representan descompuestas en estas denominaciones, de mayor a menor. Una pila de $61 muestra monedas de $50, $10 y $1; una de $25 contiene dos de $10 y cinco de $1. Se dibujan hasta tres capas por denominación para acotar el coste visual, sin truncar el importe. El dibujo no muestra contadores.

Las pilas cercanas se agrupan y, si se alcanza el límite técnico, se acumulan sin perder valor. Se conserva el área lógica de recogida alrededor de su posición; tocar o barrer una pila recoge su importe completo una sola vez. Guardar y restaurar conserva el valor exacto. La paleta está en [coin_painter.dart](../lib/features/board/presentation/coin_painter.dart) y la descomposición en [coin_denomination.dart](../lib/features/board/domain/coin_denomination.dart).

Cada bola que emite el generador tiene una probabilidad independiente del 1 % de ser dorada. Al capturarla genera diez veces el valor normal de esa jornada: con la base de $1 produce una moneda de $10. Las mejoras de recompensa también se multiplican por diez. Las denominaciones superiores siguen representando el importe exacto, incluido el premio dorado. La mejora de recompensa existente mantiene sus efectos del CSV: aumenta el importe por captura, que se representa mediante denominaciones válidas. La progresión definitiva de Valor y posibles desbloqueos especiales siguen abiertos en [cambios futuros](cambios-futuros-arbol-mejoras.md).

## Duración, producción y cobro

La jornada base tiene **10 segundos de producción + 3 de recogida final = 13 segundos**. Estadísticas y árbol no tienen temporizador. La recogida final congela bolas, escoba y robot; solo permite cobrar monedas y conserva el oscurecimiento del tablero, manteniendo la cabecera y el tiempo sin oscurecer.

La producción base sigue siendo 1,5 bolas/s. Sin bloqueos, intenta emitir quince bolas en diez segundos: **$15 generados con quince bolas normales** si se capturan todas. Las doradas aumentan ese importe; $15 ya no es un máximo absoluto. El ingreso se banca únicamente al cobrar las monedas. Bloqueos del generador, bolas sin capturar y monedas sin recoger reducen el ingreso. Estas cifras no miden la experiencia real del jugador.

Generador, duración y recompensa son mejoras independientes. Los precios y efectos por nivel se consultan en el CSV; sus conexiones se explican en el [árbol actual](arbol-de-mejoras.md). Las compras se aplican al siguiente día. No se modifican automáticamente los precios ni los valores de recompensa comprados al reducir la base a $1.

## Balance y contabilidad

- El valor generado es igual al recogido más el pendiente en el tablero.
- El valor generado es igual al valor normal por bola multiplicado por `(capturas normales + 10 × capturas doradas)`.
- El cierre banca una sola vez lo recogido; el resto se pierde y se vacía el tablero para la jornada siguiente.
- La representación por denominaciones no cambia estos cálculos ni crea dinero.
- No hay ingresos mientras el juego está cerrado.

Las nuevas jornadas usan balance 5. Las jornadas guardadas con balance 1–4 mantienen su configuración original y su valor hasta terminar, aunque la presentación use ya los nuevos colores. El siguiente día adopta el CSV actual. Ver [persistencia](persistencia.md).

## Ajuste pendiente

El cambio a $1 reduce el ingreso inicial respecto al balance 4, que daba dos monedas por captura. Los precios se mantienen por ahora y siguen pendientes de revisión jugando. Registrar capturas, valor generado/cobrado/perdido, duración y días entre compras antes de recalibrar. No se promete una compra en el primer día ni un plazo fijo para llegar al robot.
