# Economía y monedas

Referencia de la implementación 0.6.0+11 (código; última entrega APK documentada: 0.5.0+10). La única tabla editable de precios, efectos y requisitos es [balance.csv](balance.csv). El ritmo de compra sigue siendo provisional.

## Valor y denominaciones

Una bola capturada genera **$1 de base**. El dinero se ingresa al recoger la moneda, no al capturar la bola. Saldo, precios y estadísticas muestran el importe acompañado de un icono de moneda, sin el símbolo `$`; las monedas físicas no llevan cifras, cantidades, símbolos ni texto en la cara.

| Denominación | Color |
| --- | --- |
| $1 | Amarillo/dorado `#EAB308` |
| $10 | Verde esmeralda `#10B981` |
| $50 | Azul `#3B82F6` |
| $100 | Violeta `#A855F7` |
| $500 | Coral `#F43F5E` |

Solo existen esas cinco denominaciones. Cada moneda visible tiene exactamente uno de esos valores, la misma anchura/altura y ninguna cifra en su cara. Se retira la fusión por proximidad y el dibujo de pilas de distintas alturas. Una recompensa de $13 crea una moneda de $10 y tres de $1; nunca una moneda de $13. Una de $25 crea dos de $10 y cinco de $1.

Cada moneda se cobra una sola vez. El límite visible nuevo es de 1000 objetos; si se llena, una reserva de cinco contadores por denominación conserva lo que falta por emitir y lo coloca cuando se libera espacio. No hay importes ocultos sumados a una moneda visible. La reserva cuenta como dinero pendiente y se guarda; al cerrar el día, lo no cobrado se pierde igual que las monedas del tablero. Las pilas históricas se descomponen al cargar conservando el valor total.

El resumen guarda el recuento real por denominación, ordenado 500 → 100 → 50 → 10 → 1, y omite cantidades cero. La barra verde anterior (cobrado/generado) se elimina. Un día histórico sin recuento conserva su ingreso y muestra que falta el desglose, sin inventarlo.

Cada bola que emite el generador tiene una probabilidad independiente del 1 % de ser dorada. Al capturarla genera diez veces el valor normal de esa jornada: con la base de $1 produce una moneda de $10. Las mejoras de recompensa también se multiplican por diez. Las denominaciones superiores siguen representando el importe exacto, incluido el premio dorado. La mejora de recompensa existente mantiene sus efectos del CSV: aumenta el importe por captura, que se representa mediante denominaciones válidas. El ajuste definitivo de precios y posibles desbloqueos especiales siguen abiertos en [cambios futuros](cambios-futuros-arbol-mejoras.md).

## Duración, producción y cobro

La jornada base tiene **15 segundos de producción + 5 de recogida final = 20 segundos**. La barra del día mide solo producción; al agotarse, queda vacía y aparece una segunda barra para recogida. El contador muestra el tiempo de la fase activa. Estadísticas y árbol no tienen temporizador. La recogida final congela bolas, escoba y robot; solo permite cobrar monedas y conserva el oscurecimiento del tablero, manteniendo la cabecera y el tiempo sin oscurecer.

La producción base sigue siendo 1,5 bolas/s. Sin bloqueos, intenta emitir quince bolas en diez segundos: **$15 generados con quince bolas normales** si se capturan todas. Las doradas aumentan ese importe; $15 ya no es un máximo absoluto. El ingreso se banca únicamente al cobrar las monedas. Bloqueos del generador, bolas sin capturar y monedas sin recoger reducen el ingreso. Estas cifras no miden la experiencia real del jugador.

Generador, duración y recompensa son mejoras independientes. Los precios y efectos por nivel se consultan en el CSV; sus conexiones se explican en el [árbol actual](arbol-de-mejoras.md). Las compras se aplican al siguiente día. Mano I cuesta 13. Los niveles de Valor dan 2/3/5/8/13 por captura normal: multiplicar el valor entero anterior por 1,65 y redondear al entero más próximo. Los factores efectivos iniciales varían por el redondeo. Sus precios se mantienen en 40/70/110/180/300.

## Recogida y progresión del imán

El área manual se abre tras Mano I: radios 24/30/36/42/48, con costes 30/50/80/130/220. Permite recoger varias monedas cercanas en una pulsación sin comprar imán ni barrido. Barrido sigue siendo opcional y permite arrastrar para cobrar. El imán se desbloquea tras Área III y cuesta 300; sus mejoras posteriores de alcance siguen en el CSV.

Con una o más bolas agarradas se bloquean todos los cobros de monedas y su atracción. Al quedar la mano vacía vuelven a estar disponibles. El imán de monedas se distingue del agarre de bolas y de las mejoras de fuerza.

## Balance y contabilidad

- El valor generado es igual al recogido más el pendiente en el tablero y su reserva de monedas por emitir.
- El valor generado es la suma de cada captura: `valor normal × (dorada ? 10 : 1) × multiplicador del combo`. Las jornadas anteriores a los combos mantienen el multiplicador ×1.
- El cierre banca una sola vez lo recogido; el resto se pierde y se vacía el tablero para la jornada siguiente.
- La representación por denominaciones no cambia estos cálculos ni crea dinero.
- No hay ingresos mientras el juego está cerrado.

Las nuevas jornadas usan balance 6. Las jornadas guardadas con balance 1–5 mantienen su configuración original y su valor hasta terminar, aunque la presentación use ya los nuevos colores. El siguiente día adopta el CSV actual. Ver [persistencia](persistencia.md).

## Ajuste pendiente

El cambio a $1 reduce el ingreso inicial respecto al balance 4, que daba dos monedas por captura. Mano I se reduce a 13 y el Imán pasa a 300; los demás precios se conservan y siguen pendientes de revisión jugando. Registrar capturas, valor generado/cobrado/perdido, duración y días entre compras antes de recalibrar. No se promete una compra en el primer día ni un plazo fijo para llegar al robot.

## Combos — revisión 0.6.0+11

Las jornadas nuevas tienen combos desde el inicio: capturas 1–4 ×1, 5–9 ×2 y desde la décima ×3. La ventana de un segundo entre capturas es inclusiva; superarla reinicia la racha sin modificar recompensas pasadas. El reloj usa tiempo de simulación: la pausa no lo consume y guardar/restaurar no lo reinicia. Entrar en recogida final termina la racha. Los parámetros son provisionales para pruebas de balance.

Cuentan todas las capturas, también las asistidas por robot, provisionalmente. Si varias ocurren en el mismo paso de simulación, se procesan en el orden estable de las bolas del tablero; cada una utiliza el multiplicador que le corresponde. No se agrupan primero las doradas, ya que eso cambiaría el premio de la quinta o décima captura.

Los premios se generan como monedas físicas de las cinco denominaciones y necesitan recogerse. No se conceden ingresos directamente al saldo. La UI muestra el multiplicador activo al alcanzar ×2/×3 y lo retira al romperse la racha, sin publicar los umbrales. La regla del 1 % dorado, Valor I–V y el CSV no cambian; su sustitución por tiers depende del diseño pendiente.
