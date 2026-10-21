# Cambios futuros: mecánicas y árbol de mejoras

Actualizado el **21/10/2026**, contrastado con el último APK **0.9.0+17**, a partir del brainstorm del proyecto, ahora llamado Feed the Hole. Aquí se mantienen únicamente cambios pendientes. El [contexto del proyecto](contexto-proyecto-para-ideas.md), el [árbol vigente](arbol-de-mejoras.md) y [balance.csv](balance.csv) describen lo implementado.

## Cómo priorizar al retomar

- Leer el [relevo](relevo-contexto.md) y el [estado actual](estado-actual.md) antes de elegir trabajo. La siguiente petición del usuario determina la tarea; esta lista no es una orden de implementar todas las ideas.
- **Dirección deseada, diseño incompleto:** CF-16 (tiers) y CF-17 (potenciadora). Concretar primero CF-16; no inventar valores, colores o migraciones definitivas.
- **Mecánica existente por revisar:** CF-18 (combos). Probar el balance vigente; no volver a implementarla como si faltara.
- **Ideas sin reglas aprobadas:** CF-19 a CF-24. Duplicadora y bomba/impulso siguen pendientes de discusión; no cerrar sus reglas solo para poder implementarlas.
- La validación física y económica del último APK sigue pendiente. No confundir pruebas automáticas correctas con aceptación del usuario en un móvil.

## Dirección de diseño

Combinar un incremental con físicas arcade y una fábrica sencilla y configurable. El jugador empieza manipulando bolas con el dedo y progresa hacia grupos, bolas especiales y mecanismos que puede coordinar.

La automatización puede agrupar, empujar, orientar y preparar bolas, pero la participación manual debe seguir mejorando claramente el resultado. Los cuatro ejes son generar más bolas, capturar un porcentaje mayor, conseguir bolas de mayor tier/valor y recoger eficazmente las monedas.

Inicio: capturas individuales y mejora de capacidad. Fase temprana: transporte y lanzamiento de grupos y descubrimiento de combos. Juego medio propuesto: tiers, potenciación y sinergias físicas. Juego avanzado propuesto: configurar mecanismos mientras se sigue apuntando y activando manualmente. Las elecciones de habilidades y un posible prestigio son opciones de largo plazo todavía sin decidir.

## CF-16 · Sustituir Valor I–V por tiers individuales

**Pendiente de concretar antes de implementar.** Cada bola tendrá su propio tier; este determinará su valor al capturarla. Las mejoras podrán desbloquear tiers de generación, modificar sus probabilidades o facilitar su evolución. No se han decidido número de tiers, valores, colores ni probabilidades.

- Definir la tabla de tiers y cómo se identifica cada uno en móvil.
- Rediseñar la rama Valor I–V y sus conexiones, costes y efectos. No sustituir las compras existentes sin acordar cómo migrarlas.
- Mantener las monedas físicas de 1/10/50/100/500 y representar recompensas mediante combinaciones de esas denominaciones.
- La dorada multiplica ×10 el valor de **su propio tier**. La probabilidad actual del 1 % es la referencia hasta revisar balance.
- Una bola del tier máximo no puede ser dorada; el generador tampoco podrá emitir esa combinación.
- **Decisión expresamente abierta:** qué pasa cuando una bola ya dorada intenta evolucionar al tier máximo. Opciones por debatir: impedir la evolución, quitar el estado dorado u otra regla. No elegir una sin discutirla.
- Definir cómo se componen valor del tier, dorada y combo, y cómo se conservan las jornadas anteriores al migrar.

**Comprobaciones futuras:** identidad y valor persistentes por bola; generación sin doradas del tier máximo; evolución con límites; migración sin perder saldo/compras; contabilidad exacta de capturas y monedas. Mientras no exista esta tabla, la recompensa global actual sigue vigente.

## CF-17 · Bola potenciadora

**Depende de CF-16.** Una bola especial eleva el tier de las bolas con las que entra en contacto. Se busca que el jugador provoque contactos estratégicos; no modifica monedas que ya se han generado.

Antes de implementarla hay que decidir:

- Número de bolas que puede potenciar, cargas y si se consume.
- Qué cuenta como contacto nuevo para evitar potenciar cada fotograma.
- Si puede afectar a otras bolas especiales y si hay cadenas.
- Cómo afecta a doradas y qué ocurre al llegar al tier máximo.
- Aparición, aspecto, disponibilidad en el árbol y costes.

**Comprobaciones futuras:** no superar el tier máximo ni crear ciclos infinitos; un contacto persistente no consume cargas ni mejora sin límite; reglas de mano, pausa y guardado coherentes.

## CF-18 · Revisar balance y progresión de combos

La mecánica básica y su desbloqueo mediante compra ya están en el código: Racha requiere Mano I y cuesta 40. Incluye indicador con capturas, multiplicador y barra temporal desde la primera captura. Estos cambios son posteriores al APK 0.6.0+13. Falta probar su balance y decidir posibles ampliaciones:

Ya hay instrumentación en el código posterior al APK 0.6.0+13: el panel debug
permite consultar y copiar informes temporales con pico de combo, emisiones,
capturas/doradas y monedas generadas/cobradas/perdidas. Falta obtener y comparar
resultados de juego; la instrumentación no fija nuevos parámetros ni completa
esta propuesta.

- Medir si la ventana de 1 segundo y los multiplicadores ×1/×2/×3 ofrecen un ritmo divertido.
- Revisar la decisión provisional de que todas las capturas, incluidas las asistidas por robot, continúen la racha. El sistema actual no distingue quién causó una captura.
- Diseñar posibles mejoras del árbol: ventana, recompensas u otras variantes, con precios, límites y requisitos todavía por decidir.
- Evaluar combinaciones con tiers, doradas, doble emisión y futuros mecanismos.
- Mantener descubrimiento por feedback visual: no publicar en la interfaz los umbrales ni la fórmula.

## CF-19 · Elección entre tres habilidades aleatorias

**Idea futura por definir.** Después de cierto número de noches o de un hito, presentar tres habilidades y permitir elegir una. Es un sistema adicional al árbol.

- Definir frecuencia, condiciones de aparición y si se puede posponer o rechazar la elección.
- Decidir si las habilidades duran una jornada, varias o son permanentes; si se acumulan y si hay máximos.
- Definir rarezas, probabilidades y catálogo según progresión; no fijar por defecto común/rara/épica como sistema final.
- Candidatas: lanzamiento más potente, rebote mejorado, ventana de combo y control adicional de bolas.
- Diseñar guardado de la oferta y de la elección para que reabrir no vuelva a sortear ni conceda dos premios.

Objetivo: variar estrategias sin reemplazar las decisiones del árbol ni generar una opción siempre superior.

## CF-20 · Flippers y bumpers de pinball

**Ideas futuras por definir.**

- **Flippers:** paletas activadas manualmente mediante zonas táctiles para golpear bolas. Valorar mejoras de fuerza, tamaño y recuperación. Decidir colocación, controles y convivencia con mano/escoba antes de añadir botones o gestos.
- **Bumpers:** objetos circulares que impulsan bolas al chocar. Estudiar colocación, potencia y radio; su rendimiento debe depender de su posición y de las trayectorias que aprovecha el jugador.

**Comprobaciones futuras:** evitar impulsos repetidos ilimitados por contacto persistente, atascos y controles que compitan con recoger monedas. Comparar manejo y rendimiento en móvil físico.

## CF-21 · Barreras, deflectores y fábrica configurable

**Ideas futuras por definir.** Barreras inclinables, embudos y piezas físicas que orienten grupos hacia el hoyo. Considerar pocos anclajes y configuración entre jornadas para mantener cómodo el uso en móvil.

Otras candidatas, todavía sin reglas ni precios:

- Aros que eleven el tier al atravesarlos: dependen de CF-16 y necesitan límites para no generar evolución infinita.
- Núcleos que atraigan y agrupen bolas.
- Aspas giratorias que empujen bolas.
- Cañones con almacenamiento limitado que requieran apuntar y disparar manualmente.
- Generadores por ráfagas activados por el jugador.

Definir por mecanismo su control, colocación, capacidad, límites, requisitos, interacción con otras piezas y comportamiento al pausar/restaurar. No conceder dinero por activarlo: la recompensa sigue pasando por captura y recogida de monedas.

## CF-22 · Bola duplicadora

**Idea abierta, no implementable aún con las reglas disponibles.** Al contactar con otra bola puede crear una copia.

Definir objetivos válidos, qué se copia (tier, estado dorado y tipo especial), número de copias/cargas, cadenas permitidas, recompensa y regla cuando se alcanza el límite de 200 bolas. Decidir si se cancela, se aplaza o se consume el intento cuando no hay espacio. No crear copias infinitas ni ingresos por duplicar sin capturar.

## CF-23 · Bola bomba o bola de impulso

**Idea abierta.** Una colisión inicia una cuenta atrás roja de **3, 2, 1**. Queda por escoger entre:

- Explosión que destruye bolas cercanas.
- Onda expansiva que impulsa bolas sin destruirlas.

No elegir todavía uno de los dos comportamientos. Definir radio, potencia/destrucción, reinicio o no de la cuenta atrás, interacciones con otras bolas especiales, monedas y mano; consecuencias económicas y límites de reacciones en cadena. Pausa y guardado deben conservar el tiempo sin detonar ni duplicar efectos al restaurar.

## CF-24 · Nuevos controles táctiles

**Opciones para estudiar.** La escoba ya tiene control con dos puntos en el código posterior al APK 0.6.0+13: un dedo traslada y dos dedos orientan. Falta validar el tacto en Android. El lanzamiento mediante gesto rápido ya existe; cualquier ampliación debe aportar algo respecto a su inercia y capacidad actuales.

- Lanzamiento más potente o mejorable.
- Disparo de grupos con patrón concentrado o en abanico.
- Tirachinas de precisión.
- Escoba con empujón cargado.

Definir gesto, límites, feedback y relación con los controles existentes. Evitar multiplicar botones, gestos incompatibles y recogida accidental de monedas con la mano ocupada.

## Validación y límites comunes pendientes

- Probar controles, legibilidad, guardado e interrupciones en un Android físico.
- Medir ingresos, pérdidas y jornadas entre compras antes de ajustar precios y ritmo. `balance.csv` sigue siendo la fuente vigente de costes y requisitos.
- Respetar inicialmente las 200 bolas y evitar cadenas infinitas de duplicación o potenciación.
- Evaluar el volumen de monedas físicas cuando se combinen tier, dorada y combo. Actualmente hay 1000 monedas visibles y una reserva por denominación; la reserva no se cobra sola y se pierde si no llega a recogerse.
- Mantener inicialmente las cinco denominaciones, su tamaño uniforme y la identificación por color.
- Conservar la separación entre captura, generación de monedas y dinero recogido. No crear ingresos directos por activar mecanismos sin una regla económica definida.
- Mantener clara la diferencia entre el agarre de bolas y el imán de monedas; la mano ocupada bloquea todo cobro y atracción de monedas.

## Cómo continuar

Para cada propuesta, concretar reglas, impacto económico, requisitos del árbol, guardado, casos límite y un plan de pruebas por fases. Las decisiones expresamente abiertas se discutirán antes de fijarlas. Al completar una tarea, se quitará de este documento y se actualizarán las referencias de lo implementado.

## Calibración pendiente M01

La especificación funcional de Paredes rebotadoras ya está implementada y no es
un diseño abierto. Solo quedan probar precios, dependencias exactas y calibración
final: ×0,40/×1,10/×1,35/×1,60 y 380 u/s son provisionales. Para comprar en pruebas
se usan 40/100/220 y Mano I, también provisionales. M01 no completa los flippers,
bumpers ni otras piezas de CF-20. [Estado M01](m01-paredes-rebotadoras.md).

## Calibración pendiente M02

Bate de béisbol implementado como prototipo con tres niveles, control de dos
puntos e impulso por traslado/giro. Quedan validar en móvil precios, dependencia
del árbol y parámetros físicos provisionales del CSV; no ampliar tamaño, velocidad
ni capacidad por nivel. Comprobar comodidad, sonido/háptica y sinergia con paredes.
[Estado y pruebas M02](m02-bate-beisbol.md). No incluye las demás herramientas
ni cierra las decisiones abiertas de CF-20/CF-24.

## Experimentación pendiente E01

Gravedad queda implementada como prototipo: probar en Android físico fuerza,
respuesta, amortiguación, aspecto y feedback de daño. Siguen sin decidirse daño
por choques con bolas, reglas de otros eventos aleatorios simultáneos y balance
del catálogo futuro. Probabilidad inicial 5 % y máximo 10 s de producción; no
ampliar duración ni convertir estas hipótesis en reglas definitivas.
[Estado y prueba E01](e01-gravedad.md).
