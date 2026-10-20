# Incremental Hole Game — contexto para proponer ideas

## Qué es el proyecto

**Incremental Hole Game** es un juego incremental para móvil, en desarrollo activo. El jugador dirige bolas por una arena y trata de meterlas en un hoyo. Cada bola capturada genera monedas; recogerlas permite comprar mejoras permanentes y preparar jornadas más productivas. El placer central combina una interacción física sencilla con el crecimiento visible de la economía y nuevas formas de controlar o automatizar el tablero.

El proyecto se conoce también como **Jardín Mecánico** en el APK actual. La versión del código en esta revisión es **0.6.0+11**; la última entrega APK documentada es **0.5.0+10**. El juego es individual y no depende de conexión, cuentas ni servicios en línea.

## Bucle principal

1. Comienza una jornada con el tablero vacío y las mejoras compradas ya activas.
2. El generador emite bolas durante la fase de producción. El jugador las agarra, las mueve y las lanza para que entren en el hoyo.
3. Cada captura genera una recompensa representada por monedas físicas. Las monedas no se suman al saldo hasta que el jugador las recoge.
4. Al acabar la producción comienza una fase independiente de recogida final. Dura **5 segundos** de base; durante ella se recogen monedas, pero no se mueven bolas ni funcionan las herramientas de bolas.
5. El resultado diario muestra lo ganado y las monedas recogidas por denominación. Desde ahí se abre el árbol de mejoras.
6. En el árbol se compran mejoras con el saldo acumulado y se pulsa **«Comenzar día»** para iniciar la siguiente jornada.

La jornada base tiene **15 segundos de producción y 5 segundos de recogida**. Las barras de ambas fases son independientes. Las bolas y monedas que queden al terminar la recogida no se conservan; el saldo bancado, las mejoras y el progreso sí.

## Control de bolas y tablero

- La arena contiene un generador abajo, un hoyo arriba y bolas que rebotan entre sí y contra los bordes. El generador emite hacia arriba. El hoyo atrae las bolas cercanas y las captura al entrar en su radio.
- La mano inicial puede llevar una bola. La primera se agarra directamente con el dedo. Al comprar capacidad, se pueden transportar hasta **2, 3, 4, 5 y 6 bolas**. Con una bola ya agarrada, las siguientes cercanas son atraídas hacia la mano; no se teletransportan y conservan movimiento e inercia.
- La rama **Fuerza de agarre** hace que las bolas adicionales se acerquen y se sujeten con más fuerza. No aumenta la capacidad ni es el imán de monedas.
- La escoba se desbloquea como herramienta física; después se amplía y puede transformarse en V. Empuja bolas, no las recoge ni genera dinero.
- El robot es una automatización posterior que empuja bolas hacia el hoyo. No recoge monedas.
- El límite técnico actual es de **200 bolas** en el tablero.

## Economía y monedas

- Cada bola normal capturada genera **$1** de valor base. El saldo aumenta al cobrar la moneda, no en el instante de captura.
- Hay una probabilidad del **1 %** de que una bola generada sea dorada; su captura da diez veces la recompensa normal de esa jornada.
- Solo existen monedas de **$1, $10, $50, $100 y $500**. Todas tienen las mismas dimensiones y no llevan cifras ni texto; el color indica la denominación. Las recompensas se representan como combinaciones de esas monedas.
- El importe se muestra en la interfaz con el icono de moneda, sin el símbolo `$` delante. El resumen diario cuenta las monedas por denominación, de mayor a menor.
- Al principio se recogen monedas pulsándolas. La mejora opcional **Barrido** permite recogerlas también arrastrando. La rama **Área** permite recoger varias monedas cercanas al pulsar; el **Imán**, más adelante, atrae monedas alrededor del dedo activo.
- Si el jugador tiene una o más bolas agarradas, se bloquean la recogida y la atracción de monedas. Las monedas pendientes al final de la noche se pierden.
- La base genera 1,5 bolas por segundo durante 15 segundos. El valor final cobrado depende de las capturas, las bolas doradas y de cuánto consiga recoger el jugador.

## Combos de capturas

Los combos están disponibles desde el principio en las nuevas jornadas. Cada captura dentro de un segundo de la anterior continúa la racha: las capturas 1–4 dan ×1, la quinta ya da ×2 y desde la décima se aplica ×3. Los premios anteriores no cambian. Superar la ventana reinicia la racha; una pausa no consume tiempo. La racha termina al entrar en recogida final y cada jornada comienza con una nueva.

El multiplicador se aplica al valor normal vigente y al ×10 de las doradas. Por ejemplo, una dorada de valor normal 3 capturada con combo ×3 genera 90, representados mediante monedas válidas que aún hay que recoger. Todas las capturas cuentan, incluidas las asistidas por robot; es una decisión provisional para probar. La interfaz muestra **COMBO ×2** o **COMBO ×3**, sin explicar umbrales ni fórmula.

La ventana, el balance, posibles mejoras del árbol y la decisión sobre capturas asistidas siguen abiertos a revisión. Las jornadas guardadas antes de los combos conservan sus reglas originales hasta terminar.

## Árbol de mejoras actual

Hay seis categorías con colores: **Generación** (verde), **Valor** (dorado), **Recogida de monedas** (azul), **Control de bolas** (violeta), **Tiempo** (naranja) y **Automatización** (coral). Los nodos comprados muestran el color de su categoría; los bloqueados aparecen apagados y los comprables tienen un brillo blanco suave. Las conexiones expresan requisitos; comprar un nodo no compra sus descendientes.

El árbol contiene 49 nodos en 15 tipos de mejora. Sus ramas principales son:

```text
CONTROL · Mano I (13) → capacidad hasta 6 bolas
  ├─ Fuerza de agarre I–V
  ├─ Generador I–V
  │    ├─ Doble emisión (requiere Generador III y Anchura III)
  │    └─ Día más largo I–V (requiere Generador II)
  ├─ Valor I–V
  ├─ Barrido de monedas (opcional)
  ├─ Área de recogida I–V
  │    └─ Imán (requiere Área III) → Atracción I–III
  └─ Mano II → Mano III–V
       └─ Desbloquear escoba → Anchura I–V
            ├─ Escoba en V
            └─ Robot (requiere Anchura II y Barrido) → Velocidad I–V
```

Las compras se hacen entre jornadas. Mano I cuesta **13**; Valor aumenta la recompensa normal por captura a **2/3/5/8/13**; el Imán cuesta **300** y requiere Área III. Los demás costes y efectos están en [`balance.csv`](balance.csv), que es la fuente vigente para cifras y requisitos. El ritmo de precios aún debe probarse jugando.

## Presentación y controles del árbol

El árbol es una pantalla independiente. Se navega arrastrando y con pellizco; no muestra título, botón atrás ni controles de zoom. Al abrirlo no hay ninguna mejora seleccionada. Tocar un nodo muestra una descripción esquemática, el coste y los requisitos. Para comprar hay que mantener pulsado el botón de compra durante un segundo; mover el dedo o interrumpir la acción cancela la compra. **«Comenzar día»** inicia directamente la siguiente jornada.

## Modo de depuración para probar ideas

En el árbol, mantener el saldo pulsado durante tres segundos abre un modo temporal de pruebas. Permite ver todo el mapa, comprar cualquier nodo gratis con sus requisitos, comprar todas las mejoras y comenzar jornadas de prueba. También permite activar la **Vista del jugador**, que usa el descubrimiento progresivo, precios y estados normales sobre las compras y saldo de prueba. Reiniciar la prueba sirve para inspeccionar la progresión desde cero. Al salir o reabrir se recupera la partida normal; las pruebas no se guardan sobre ella.

## Estado del proyecto

La entrega **0.5.0+10** pasó formato, análisis, 116 pruebas, compilación Android y verificación de firma en CI. La revisión de código **0.6.0+11** añade combos y modo de depuración; pasa 134 pruebas; su entrega APK aún no está registrada. Esto no sustituye la prueba de controles y legibilidad en un teléfono físico. También falta validar jugando el ritmo real de ingresos y compras.

El diseño futuro apunta a una fábrica sencilla y configurable que ayude sin sustituir al jugador. Los cuatro ejes son generación, porcentaje de captura, valor/tier de las bolas y recogida de monedas. La rama Valor global actual se quiere sustituir por tiers individuales, pero todavía faltan sus valores, colores, probabilidades y migración. Las doradas deberán valer ×10 de su tier y nunca existir en el tier máximo. Sigue abierta la regla de una dorada que intenta evolucionar a ese máximo. Una bola potenciadora podría elevar tiers por contacto cuando se concreten sus cargas y límites.

También se estudian habilidades aleatorias a elegir entre tres, flippers manuales, bumpers, barreras y deflectores configurables, aros, núcleos, aspas, cañones y generadores por ráfagas. Todas necesitan reglas antes de implementarse. Dos conceptos de bolas adicionales siguen abiertos:

- **Bola duplicadora:** al chocar con otra bola, la duplica. Falta definir selección del objetivo, cadenas, límites y comportamiento cuando el tablero está lleno.
- **Bola bomba o de impulso:** al chocar inicia una cuenta atrás roja de 3, 2, 1. Aún no se ha elegido entre destruir bolas cercanas o impulsarlas con una onda expansiva. También faltan radio, objetos afectados, reglas de la cuenta atrás y límites.

No asumas que las ideas anteriores son decisiones cerradas. El diseño está abierto a cambios que mejoren la diversión, la claridad, las decisiones interesantes y el ritmo incremental, manteniendo el control cómodo en pantalla táctil y evitando recompensas confusas o dinero generado sin una regla clara.

## Encargo sugerido para quien proponga mejoras

Usa este contexto para proponer ideas nuevas y concretas. Para cada idea, explica qué experiencia mejora, cómo se juega, dónde encaja en el bucle o el árbol, qué requisitos tendría, cómo afecta al balance, qué casos límite introduce y cómo se podría probar con un prototipo sencillo. Separa las propuestas en **pequeñas mejoras**, **mecánicas nuevas** y **preguntas que conviene resolver primero**. No trates las ideas de bola duplicadora o bomba como aprobadas: puedes desarrollarlas como opciones para decidir.

## Documentos de referencia

- [Modo de depuración](modo-debug.md)
- [Árbol de mejoras vigente](arbol-de-mejoras.md)
- [Balance de costes, efectos y requisitos](balance.csv)
- [Economía y monedas](economia.md)
- [Cambios futuros y decisiones abiertas](cambios-futuros-arbol-mejoras.md)
