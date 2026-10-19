# Cambios futuros: árbol de mejoras

> **Entrega CF-09 a CF-15 — 19 de octubre de 2026:** [PR #18](https://github.com/migdlp/incremental_hole_game/pull/18) integrada en `main`, código `34ea6d66e884903e6fd4d47c02883e3f31b48f74`. **[Descargar APK 0.5.0+10 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39292311120/artifacts/12206371751)**, disponible hasta el 2 de noviembre de 2026. [Pipeline 39292311120](https://github.com/migdlp/incremental_hole_game/actions/runs/39292311120) correcta: formato, análisis, **116 pruebas**, compilación Android y firma v2 verificada. Descomprimir e instalar `jardin-mecanico-debug.apk`. No incluye las ideas de bolas duplicadoras/bomba. Validación en Android físico y ajuste de precios jugando pendientes.

> **Entrega CF-06 a CF-08 — 19 de octubre de 2026:** [PR #17](https://github.com/migdlp/incremental_hole_game/pull/17) integrada en `main`, código `1cd7b8761a9e1e4eea19761385086e92ec470438`. **APK 0.4.0+9:** [descargar APK y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39223285776/artifacts/12173036451), disponible hasta el 2 de noviembre de 2026. [Pipeline 39223285776](https://github.com/migdlp/incremental_hole_game/actions/runs/39223285776) correcta: formato, análisis, **107 pruebas**, compilación Android y firma v2 verificada. Incluye estadísticas visuales, árbol compacto de ocho direcciones y cinco niveles de fuerza de agarre. Descomprimir e instalar `jardin-mecanico-debug.apk`. Validación en Android físico y ajuste definitivo de precios pendientes.

## Próximas mejoras — 19 de octubre de 2026

**CF-09 a CF-15 integrados en `main` y entregados en el APK 0.5.0+10.** Estos requisitos detallan las nuevas peticiones para UI, economía y recogida. Deben poder implementarse leyendo esta sección junto al [árbol actual](arbol-de-mejoras.md) y el [balance](balance.csv). Los valores de balance aquí indicados son objetivos acordados; cualquier precio nuevo que no esté especificado queda por ajustar al implementar.

### CF-09 · Mostrar dinero sin el símbolo «$»

- [x] Quitar el carácter `$` que precede a los importes en toda la interfaz: saldo, fichas y precios de mejoras, estadísticas, recompensas, tiendas y cualquier otra pantalla o aviso.
- [x] En cada sitio que muestre dinero, acompañar el importe con el icono de moneda que corresponda. Mantener el número para expresar la cantidad o el precio; quitar solamente el símbolo `$`.
- [x] No alterar los valores guardados, los cálculos ni el formato interno de la economía. El cambio es de presentación: por ejemplo, saldo «[icono de moneda] 120», precio «[icono de moneda] 13».
- [x] Comprobar que importes de distinta longitud siguen cabiendo en pantallas estrechas y que el icono conserva el color de su denominación.

### CF-10 · Todas las monedas con las mismas dimensiones

- [x] Dar a todas las monedas físicas la misma anchura y altura, independientemente de su denominación.
- [x] Usar el color como diferencia visual entre denominaciones; el color indica su valor. No cambiar el tamaño para sugerir que una moneda vale más.
- [x] Mantener las monedas sin cifras ni texto sobre la cara. El valor se comunica mediante el color y, fuera de la moneda, por el icono y el importe cuando la interfaz necesite expresar una cantidad.
- [x] Revisar las monedas en el tablero y en el resumen, con sus tamaños aparentes consistentes en distintas escalas de pantalla.

### CF-11 · Limitar estrictamente las denominaciones

- [x] Solo pueden existir monedas de **$1, $10, $50, $100 y $500**. No crear ni entregar denominaciones de $2, $4, $25 u otros valores.
- [x] Cada objeto de moneda siempre corresponde exactamente a una de esas cinco denominaciones. Si una recompensa tiene otro importe, representarla como combinación de monedas permitidas; por ejemplo, $3 son tres monedas de $1 y $12 son una de $10 y dos de $1. Nunca crear una moneda individual de $2, $3, $4 u otro valor fuera de la lista.
- [x] Dar un color distintivo y constante a cada denominación, conservando el dorado/amarillo para $1 y la paleta ya documentada en CF-01 para las demás.
- [x] Aplicar la restricción en todos los caminos que generan, guardan, muestran, atraen o recogen monedas, no solo en su dibujo. Revisar partidas guardadas para que ningún valor inválido se convierta silenciosamente en una denominación nueva.

### CF-12 · Resumen diario: quitar la barra y desglosar monedas

- [x] Retirar la barra verde del resumen del día; no mostrarla como indicador de progreso.
- [x] Aclaración del indicador actual: representa la proporción del valor cobrado respecto del valor total generado durante el día (`dinero cobrado / dinero generado`). No representa el tiempo del día, el avance hacia una meta ni el número de monedas. Registrar esta explicación para identificar el indicador que se retira; no sustituirlo por otra barra.
- [x] Añadir al resumen un recuento diario por denominación: mostrar las monedas conseguidas con su icono y cantidad, ordenadas de mayor a menor valor ($500, $100, $50, $10, $1); omitir las denominaciones cuya cantidad sea cero.
- [x] El desglose debe permitir entender la cuenta del día. Mostrar cada cantidad de monedas por separado para que no se confunda con el valor total en dinero.
- [x] Verificar tanto un día sin monedas como uno con varias denominaciones, así como importes y recuentos en una pantalla de móvil estrecha.

### CF-13 · Barras y fases independientes para el día y la recogida

- [x] Mostrar el tiempo del día y el tiempo de recogida final con barras independientes; no reutilizar la misma barra para ambas fases.
- [x] Mientras transcurre el día, avanzar únicamente la barra del día. Al completarse, cerrar esa barra y entonces empezar la fase nocturna/de recogida con su propia barra desde el inicio.
- [x] El tiempo inicial de recogida continúa siendo de 3 segundos, como se acordó en CF-02, salvo que un cambio futuro documentado lo modifique.
- [x] La transición entre fases debe ser visible e inequívoca: la barra de noche no debe avanzar mientras avanza la del día. Reflejar pausa, cierre y fin de fase correctamente.

### CF-14 · Recogida manual por área antes del imán

- [x] Permitir mejorar primero el área de recogida manual de monedas. Al pulsar una moneda, el área mejorada permite recoger las monedas que queden dentro de su radio en esa acción, varias a la vez, sin poseer el imán.
- [x] Dar a esta progresión sus niveles y radio en el árbol/balance. Debe estar disponible antes del desbloqueo del imán de monedas; conservar el gesto de pulsar monedas y explicar en el árbol que el área permite recoger un grupo cercano.
- [x] Mover el imán de monedas más adelante en la rama y encarecer su desbloqueo respecto a la recogida manual por área, para que sea una automatización posterior. Ajustar los requisitos y la disposición del árbol sin crear conexiones imposibles ni perder compras guardadas.
- [x] Desactivar **toda** recogida de monedas mientras el jugador tenga una bola agarrada en la mano: ni el imán ni una pulsación/área manual deben cobrar monedas en ese estado. Cuando no tenga ninguna bola en la mano, vuelven a funcionar según sus mejoras.
- [x] La condición de mano ocupada debe aplicarse también durante la atracción y al completar la recogida para que una moneda no termine cobrada después de empezar a agarrar una bola.

### CF-15 · Balance inicial y curva entera del valor de monedas

- [x] Bajar el precio de la primera mejora, **Mano I**, de $20 a **$13**. Este es el precio inicial de prueba solicitado. Actualizar la fuente de balance y la ficha del árbol; no confundirlo con el coste de los niveles Mano II–V.
- [x] Revisar la rama Valor completa para que cada nivel aumente el valor respecto al nivel anterior mediante una progresión aproximadamente exponencial, con factor objetivo de **1,6 a 1,7** por nivel.
- [x] Redondear cada valor de mejora a un número entero de dólares antes de ofrecerlo o guardarlo. Nunca mostrar ni otorgar valores fraccionarios como $3,3; aplicar una regla de redondeo única y documentada.
- [x] No arrancar con un salto de ×3 para después reducir los incrementos: cada nivel nuevo se calcula a partir del valor entero del nivel anterior aplicando el factor objetivo y redondeando. Debido a los enteros, el redondeo puede apartar puntualmente el factor efectivo; mantener la tendencia creciente y no compensarlo con una bajada posterior.
- [x] Actualizar efectos, topes, costes, resumen de cada nodo y guardados de forma compatible; no alterar el valor base de $1 por bola ni permitir denominaciones inválidas (CF-11). Los costes de esta rama no están fijados por esta petición y deben quedar como decisión de balance explícita al implementarla.

### Ideas de nuevos tipos de bola — aún no listas para implementar

Estas propuestas son conceptos, no requisitos completos: no incorporarlas al juego, al árbol ni al balance hasta concretar su comportamiento y aprobar una tarea implementable.

- **Bola duplicadora:** al chocar con otra bola, la duplica. Quedan por decidir qué bola se duplica, si hay límite por choque/cadena, cómo interactúa con el límite de bolas y si hay efectos visuales o sonoros.
- **Bola bomba:** al chocar con otra bola empieza a ponerse roja y muestra una cuenta atrás de 3, 2, 1; después explota y destruye las bolas cercanas. Quedan por decidir el radio, el momento y las reglas de la cuenta atrás, el tratamiento de monedas u objetos cercanos, límites de destrucción y efectos visuales/sonoros.

**Estado:** CF-06, CF-07 y CF-08 se entregaron en el APK 0.4.0+9; CF-09 a CF-15 están implementados y verificados en la revisión 0.5.0+10. Integración y entrega Android verificadas en la pipeline 39292311120, enlazada al principio de este documento. Las dos ideas de bolas son exploratorias y no deben contabilizarse como tareas aprobadas para implementar.


### Resultado y decisiones de CF-09 a CF-15

- **UI:** importes sin `$`, icono de moneda sin texto y geometría idéntica para los cinco colores. Resumen sin barra verde, con recuento real por denominación en orden 500 → 100 → 50 → 10 → 1; las filas con cero se omiten.
- **Monedas físicas:** las recompensas se descomponen al generarlas en monedas individuales de denominación válida. No se fusionan por proximidad ni se dibujan pilas de distinta altura. El límite nuevo de 1000 monedas visibles tiene una reserva de cinco contadores por denominación; si se llena, se emiten monedas al liberarse espacio, manteniendo la contabilidad sin crear objetos de valor arbitrario.
- **Tiempo:** diez segundos base de día en su barra; al llegar a cero queda completa/vacía y aparece una segunda barra de tres segundos de recogida. El contador muestra solo el tiempo de la fase activa.
- **Recogida:** el área manual queda disponible tras Mano I, sin comprar Barrido ni Imán; mantiene radios de 24/30/36/42/48 unidades. Barrido conserva su rama opcional y su gesto. El imán requiere Área III y cuesta 300; toda recogida y atracción quedan bloqueadas con una o más bolas agarradas.
- **Economía:** Mano I cuesta 13. Valor I–V da 2/3/5/8/13 por bola, partiendo de 1 y aplicando ×1,65 con redondeo al entero más próximo en cada paso; los primeros factores efectivos varían por el redondeo. Los precios de Valor se conservan en 40/70/110/180/300. Los importes se materializan mediante las cinco denominaciones, sin monedas individuales de 2, 3, 4, 8 o 13.
- **Guardados:** JSON v5 y balance 6. Las jornadas antiguas conservan su balance 1–5; se congela también el CSV de balance 5. Se mantienen compras de imán anteriores sin regalar Área II/III. Las pilas antiguas se descomponen conservando el valor pendiente. Los días antiguos sin recuento guardado muestran que no hay desglose disponible, conservando sus importes.
- **Verificación:** 116 pruebas correctas, análisis sin incidencias, revisión visual con fuentes reales y pantalla de 320 × 568 con texto al 150 %. La aceptación en un Android físico sigue pendiente. Ninguna de las dos ideas de bolas se ha implementado.

## Tanda anterior entregada — CF-06 a CF-08

**CF-06, CF-07 y CF-08 implementados y entregados en el APK 0.4.0+9.** Estas tres tareas corresponden a la tanda anterior; el usuario ha autorizado implementarlas, integrarlas y entregar un APK. La numeración identifica requisitos y no fija un orden de prioridad.

### CF-06 · Estadísticas más visuales y minimalistas

- [x] Rediseñar la pantalla de estadísticas para que se entienda de un vistazo y tenga una presentación mucho más visual.
- [x] Reducir el texto: eliminar explicaciones que no aporten y datos secundarios o irrelevantes para el jugador.
- [x] Dar protagonismo a los resultados importantes, con una jerarquía visual clara y poco ruido.
- [x] Mantener una presentación sencilla y el acceso al árbol de mejoras. La selección concreta de indicadores y el diseño se decidirán al implementar, sin añadir métricas nuevas por defecto.

### CF-07 · Árbol aún más cercano y con ocho direcciones

- [x] Acercar los nodos **bastante más que en la compactación CF-05 ya publicada**. Esta es una nueva reducción de distancia, no la descripción del ajuste anterior.
- [x] Colocar los nodos respecto a sus conexiones usando únicamente ocho direcciones, separadas por 45°: arriba (norte), arriba-derecha (noreste), derecha (este), abajo-derecha (sureste), abajo (sur), abajo-izquierda (suroeste), izquierda (oeste) y arriba-izquierda (noroeste).
- [x] Usar esas posiciones cercanas de forma consistente, con separación suficiente para distinguir y pulsar los nodos y entender sus conexiones.
- [x] Conservar los nodos, requisitos y compras existentes; esta tarea trata de su disposición visual.
- [x] Dejar para una revisión posterior si algunas ramas deben extenderse más hacia ciertos lados. Por ahora se busca una distribución muy próxima, sin fijar una preferencia lateral ni distancias numéricas todavía.

```text
       NO     N     NE
         ↖    ↑    ↗
       O ←  nodo  → E
         ↙    ↓    ↘
       SO     S     SE
```

### CF-08 · Fuerza de agarre de la mano

- [x] Añadir una línea de mejoras de fuerza, dentro de Control de bolas (violeta), independiente de la capacidad de mano y del imán de monedas.
- [x] Mientras ya se lleva una bola, atraer y sujetar las siguientes bolas más rápido al entrar en el alcance del imán de la mano.
- [x] Mantener el agarre manual de la primera bola, la capacidad comprada y el alcance actual. La mejora refuerza la sujeción física, sin teletransportar ni atraer desde una mano vacía.
- [x] Hacer la progresión comprable, persistente y visible en el árbol; los niveles más altos deben responder antes y resistir mejor los tirones.

La tanda anterior comprendía CF-06, CF-07 y CF-08. Se han completado los tres bloques; no quedan funciones sin implementar dentro de esa lista. Las ideas históricas, los repartos laterales que CF-07 aplaza y la validación física de Android conservan su estado propio; no se atribuye su aprobación a esta lista.

### Resultado de la implementación de esta tanda

- **Estadísticas:** dinero ganado como cifra principal, bolas al hoyo y dinero sin recoger; barra visual del importe cobrado, saldo en cabecera y un único acceso al árbol. Se retiran textos explicativos, récord y comparación como datos secundarios de esta pantalla, conservando sus datos de progreso.
- **Árbol:** cuadrícula de 64 unidades y objetivos táctiles de 64 × 64, iconos de 52; posiciones y segmentos solo en ocho direcciones. Los precios siguen en la ficha y en las descripciones accesibles. La cuadrícula reserva rutas con al menos 30 unidades de distancia respecto a los nodos ajenos a cada conexión.
- **Fuerza de agarre:** nueva línea `hand_grip`, cinco niveles de ×1,25 / ×1,5 / ×1,8 / ×2,1 / ×2,5. Costes iniciales de prueba de $25 / $50 / $90 / $160 / $280 en el CSV. Requiere Mano I y cada nivel anterior. Refuerza la fuerza del muelle, ajusta la amortiguación para responder antes y tolera algo más de estiramiento antes de soltar una bola.
- El árbol conserva sus 44 nodos anteriores y añade cinco de fuerza: **15 tipos y 49 nodos**. No se retiran compras ni se cambian los requisitos anteriores.
- Esquema JSON v4 y balance 5 conservados: sin comprar fuerza no se añade ninguna clave nueva a la configuración de una jornada antigua. La fuerza anterior equivale a ×1; no se concede la mejora gratis. La compra guarda `hand_grip` y el efecto de la jornada `hand_grip_strength`.
- **107 pruebas correctas**, incluidas velocidad progresiva de acercamiento, agarre sin teletransporte, resistencia a un tirón, consistencia a 30/60/120 Hz, persistencia, direcciones y rutas sin atravesar nodos. Vista de 320 × 568 con texto al 150 % correcta; capturas visuales del resumen y de la ficha revisadas.
- Pendientes de aceptación: sensaciones y legibilidad en Android físico, y ajuste definitivo de precios jugando. Estas comprobaciones no se dan por aprobadas por compilar el APK.

### Comprobación de lo último entregado

- Mano con peso e inercia: implementada y subida en `9c79dd3`.
- Cabecera y tiempo sin oscurecer durante la recogida final; bolas doradas con probabilidad del 1 % y valor ×10 (base $10): implementados y subidos en `8f92527`.
- Primera compactación del árbol (CF-05): integrada en `91b10cb`; la [CI 39182903655](https://github.com/migdlp/incremental_hole_game/actions/runs/39182903655) pasó 101 pruebas y generó el APK. Ese APK anterior no incluye CF-06 a CF-08; su entrega actual se registra al principio de este documento.


> **Entrega CF-05 — 19 de octubre de 2026:** PR #16 integrada en `main`, commit `91b10cb0d5ff57ee0c69e02e17c1145d48d53c4d`. [APK 0.3.3+8 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39182903655/artifacts/12156897149), disponible hasta el 2 de noviembre de 2026. [Pipeline 39182903655](https://github.com/migdlp/incremental_hole_game/actions/runs/39182903655) correcta sobre ese commit: formato, análisis, **101 pruebas**, compilación Android y firma v2 verificadas. Incluye el árbol compacto, ficha al seleccionar y compra de 1 s, junto con los cambios que ya había en `main`. Las notas de preparación inferiores son históricas. Prueba en Android físico pendiente.


> **Entrega Android — 19 de octubre de 2026:** PR #15 integrada en `main`, commit `27b3950146389f2db3f63cf708ffb289ed908859`. Versión **0.3.1+6**. [Pipeline 39181076818](https://github.com/migdlp/incremental_hole_game/actions/runs/39181076818) correcta: formato, análisis, 88 pruebas, compilación Android y firma verificada. [Descargar APK y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39181076818/artifacts/12155843676), disponible hasta el 2 de noviembre de 2026. Descomprimir e instalar `jardin-mecanico-debug.apk`. La prueba en Android físico y el ajuste de balance siguen pendientes. Las notas de preparación inferiores conservan el estado anterior a esta entrega.


**Referencia viva v1.1 · CF-01 a CF-08 entregados; CF-09 a CF-15 entregados; APK actual: 0.5.0+10.**

El usuario autorizó implementar este mapa el 19 de octubre de 2026. El [árbol actual](arbol-de-mejoras.md) documenta su ejecución y [balance.csv](balance.csv) contiene los costes y efectos. Las dos instrucciones más recientes prevalecen sobre el boceto original: Mano I permite llevar **dos** bolas (no tres), cada nivel añade una y la escoba solo aparece tras comprar su desbloqueo. El resto del mapa se implementa con sus cinco niveles, colores y requisitos cruzados.

El mapa de ramificaciones se conserva. Esta revisión implementa CF-01 a CF-04 y la aclaración de monedas sin cifras: base de $1, recogida final de 3 s, estadísticas → árbol → comenzar día y nodos apagados/blancos/coloreados según estado. Los precios y las mejoras de Valor existentes se conservan; su ajuste de ritmo sigue pendiente de sesiones reales. No hay nuevas probabilidades ni desbloqueos de denominaciones inventados.

## Aclaración de representación — 19 de octubre de 2026

Petición posterior del usuario: ninguna moneda muestra su valor sobre la cara, ni siquiera la de $1. La moneda normal sigue siendo amarilla/dorada. El saldo, los precios y las estadísticas sí muestran importes en dólares del juego.

Se autoriza implementar CF-01 a CF-04, conservando el mapa y las compras existentes. El resultado se registra con sus comprobaciones antes de darlo por entregado.

## CF-05 · Árbol compacto y ficha bajo demanda — 19 de octubre de 2026

**Implementado en la rama `feat/compact-upgrade-tree`, pendiente de integrar.** Esta petición sustituye el tiempo anterior de tres segundos y los controles visibles del árbol; conserva el mapa de mejoras, efectos, precios, requisitos y compras existentes.

- [x] Cabecera sin botón de atrás ni título «Árbol de mejoras»; solo monedas y saldo arriba a la derecha.
- [x] Eliminar los botones de acercar, alejar y centrar. Mantener arrastre y zoom por pellizco; el botón inferior «Comenzar día» se conserva.
- [x] No seleccionar ninguna mejora al abrir: la ficha y la compra aparecen únicamente tras tocar un nodo.
- [x] Mostrar el efecto en una frase breve: «La mano agarra **2** bolas». La cantidad o capacidad mejorada se destaca en verde `#22C55E`.
- [x] Conservar precio, estado y requisitos. El desglose de nivel, efecto, valor anterior → nuevo y porcentaje sigue en la información contextual del resumen al mantenerlo pulsado, además de las descripciones accesibles.
- [x] Comprar únicamente desde su botón, manteniéndolo **1 segundo**. Tocar o mantener un nodo consulta, sin comprar. Soltar antes, mover el dedo, añadir otro o interrumpir la aplicación cancela el progreso.
- [x] Acercar nodos: salto vertical de 96 unidades en lugar de 180; lienzo de 880 × 1120 en lugar de 3150 × 2150, sin cambiar las conexiones de desbloqueo.
- [x] Dibujar conexiones mediante tramos rectos horizontales, verticales o diagonales, sin curvas. Los requisitos cruzados recorren pasillos libres para no atravesar otros nodos.

Comprobaciones: 95 pruebas correctas, incluida ausencia de ficha inicial, compra única tras un segundo, cancelación, colores, separación de objetivos táctiles y pantalla de 320 × 568 con texto ampliado al 150 %. No se acredita experiencia física en Android ni se genera APK en esta revisión.

## Cambios añadidos — 19 de octubre de 2026

**Requisitos implementados en esta revisión; pendientes de revisión táctil en Android y de integración de la rama.** La numeración identifica cambios, no un orden de prioridad. Estas reglas sustituyen cualquier cifra o presentación contradictoria de propuestas anteriores. Se conservan las decisiones vigentes sobre mano y escoba de la nota inicial.

### CF-01 · Valor base y denominaciones de monedas

- [x] Una bola capturada en el hoyo genera **$1 de valor base**, representado por una moneda normal de un dólar.
- [x] Mostrar el dinero en dólares del juego, distinguiendo el importe de la cantidad de monedas físicas.
- [x] Usar únicamente denominaciones de **$1, $10, $50, $100 y $500**. No habrá moneda de $25.
- [x] Cada denominación tendrá un color propio. Las monedas no llevarán números, cantidades, símbolos de moneda ni texto dibujados sobre ellas; se identificarán visualmente por su color. El saldo y las estadísticas sí mostrarán importes.

| Denominación | Apariencia | Color HEX | Decisión |
| --- | --- | --- | --- |
| **$1** | 🟡 Dorada; moneda normal | `#EAB308` | Dorado indicado por el usuario. |
| **$10** | 🟢 Verde esmeralda | `#10B981` | Paleta propuesta. |
| **$50** | 🔵 Azul | `#3B82F6` | Paleta propuesta. |
| **$100** | 🟣 Violeta | `#A855F7` | Paleta propuesta. |
| **$500** | 🔴 Rojo coral | `#F43F5E` | Paleta propuesta. |

El color de una moneda representa su denominación; el color de un nodo del árbol representa el tipo de mejora. Son dos leyendas independientes.

**Implementado para las pilas:** cada importe se descompone en denominaciones válidas de mayor a menor. Por ejemplo, $61 se representa como $50 + $10 + $1; no se dibuja una moneda de $61. Las agrupaciones conservan el total y se cobran una sola vez, con hasta tres capas visuales por denominación para limitar el dibujo. Las denominaciones mayores aparecen al acumular suficiente valor en una pila, sin añadir premios aleatorios.

**Pendiente de diseñar juntos:** desbloqueos especiales de denominaciones, si se desean, y progresión final de Valor. No se presupone que cada bola vaya a generar una moneda de $500 ni se fijan probabilidades. El cambio a $1 obliga a recalcular el ritmo de ingresos y los precios futuros; no se mantienen como balance aprobado las cifras basadas en dos monedas por bola.

### CF-02 · Recogida final inicial de tres segundos

- [x] La fase nocturna de recogida de monedas empieza con **3 segundos de duración base**.
- [x] Tres segundos sustituye a la cifra de dos segundos mencionada y corregida en la petición, y a los cinco segundos de propuestas anteriores.
- [x] Esta duración corresponde solo a la fase de recogida final, no al tiempo de producción ni al tiempo para consultar estadísticas o comprar mejoras.

Se conserva el comportamiento previsto de recogida final con el resto del tablero detenido. Con una base de 10 segundos de producción, el ciclo activo inicial es de **13 segundos en total**. No se define todavía una mejora para ampliar la recogida; si se añade, partirá de esos tres segundos.

### CF-03 · Estadísticas → árbol independiente → siguiente día

- [x] El pop-up de estadísticas tendrá **un único botón: «Ir al árbol de mejoras»**.
- [x] El árbol de mejoras será una **pantalla independiente**.
- [x] Esa pantalla tendrá el botón **«Comenzar día»**, que inicia directamente el siguiente día.
- [x] El pop-up de estadísticas dejará de ofrecer «Comenzar día»; el recorrido ya no obliga a regresar al resumen para iniciarlo.

```text
DÍA EN JUEGO
     ↓
RECOGIDA FINAL · 3 s de base
     ↓
POP-UP DE ESTADÍSTICAS
[Ir al árbol de mejoras]
     ↓
PANTALLA DEL ÁRBOL
[Comenzar día]
     ↓
SIGUIENTE DÍA
```

### CF-04 · Estilo visual del árbol según estado

- [x] Rediseñar el estilo del árbol para distinguir los tipos de mejora y el estado de cada nodo.
- [x] **Comprada:** mostrar el icono y el color de su tipo o grupo.
- [x] **Sin comprar y no disponible para compra:** mostrar el nodo apagado, con icono y contorno atenuados.
- [x] **Sin comprar y comprable:** iluminar el nodo con una luz blanca suave, como una activación parcial. Exige requisitos cumplidos y dinero suficiente.
- [x] Mantener visibles las conexiones necesarias para entender las ramificaciones, respetando el descubrimiento progresivo.

| Estado | Icono y presentación |
| --- | --- |
| Comprada | Icono visible con el color de su tipo; marca de compra complementaria. |
| Sin comprar, bloqueada o sin dinero | Apagada, gris y con poco brillo; el motivo se indica al consultar. |
| Comprable | Icono y borde en blanco suave, con resplandor moderado; aún no usa la presentación de comprada. |

Los tipos mantienen la paleta del apartado «Tipos y colores». El brillo blanco indica que puedes comprar; el color de categoría identifica lo que ya has adquirido.

### Comprobaciones de la implementación

- Una captura sin mejoras genera exactamente $1; recogerla aumenta el saldo una sola vez en $1.
- Solo aparecen denominaciones permitidas y cada una conserva su importe al agrupar o cobrar.
- Una partida nueva dispone de tres segundos de recogida final, sin cambiar por error la duración de producción.
- El pop-up tiene una única acción y el recorrido estadísticas → árbol → comenzar día funciona sin regresar al pop-up.
- Los estados comprado, apagado y comprable se distinguen; al comprar se pasa de blanco suave al icono con el color del tipo.

## Objetivo

Empezar manipulando pocas bolas y recogiendo monedas a mano. Las mejoras aumentan la producción, el valor y la capacidad de manejar y cobrar lo producido. Escobas, imán y robot cambian la manera de jugar y abren especializaciones.

La primera compra permite llevar dos bolas. La primera se agarra manualmente y, mientras se lleva alguna, las siguientes se atraen al acercarse hasta llenar la capacidad comprada.

## Tipos y colores

| Tipo | Color | Incluye |
| --- | --- | --- |
| GEN · Generación de monedas | 🟢 Verde · `#22C55E` | Más bolas por segundo y, más adelante, por emisión. Las bolas generan monedas al entrar en el hoyo. |
| VAL · Valor de monedas | 🟡 Dorado · `#EAB308` | Más monedas por bola capturada. |
| REC · Recolección de monedas | 🔵 Azul · `#3B82F6` | Barrido, radio e imán. |
| CON · Control de bolas | 🟣 Violeta · `#A855F7` | Capacidad y fuerza de mano, escobas y anchura. |
| TIE · Tiempo de producción | 🟠 Naranja · `#F97316` | Días con más tiempo para producir. |
| AUT · Automatización | 🔴 Coral · `#F43F5E` | Robot y velocidad. |

Cada subrama hereda el color de su tipo, aunque nazca de otro tipo. El color identifica el efecto. Un candado indica bloqueo, una marca indica compra y el brillo indica disponibilidad, para no sustituir el color de categoría por el estado.

## Mapa para móvil

Cada flecha exige comprar el nivel anterior. Las bifurcaciones permiten avanzar por todos los caminos; no hay elecciones excluyentes. Una conexión indica acceso, no una compra gratuita.

```text
🟣 MANO I · 20 monedas
Puedes llevar 2 bolas (+1)
│
├─ 🟣 FUERZA DE AGARRE I → II → III → IV → V
│
├─ 🟢 GENERADOR I
│  Produce un 25 % más rápido
│  └─ Generador II
│     ├─ Generador III → IV → V
│     │  └─ 🟢 DOBLE EMISIÓN
│     │     2 bolas por emisión
│     └─ 🟠 DÍA MÁS LARGO I
│        └─ II → III → IV → V
│
├─ 🟡 VALOR I
│  3 monedas por bola
│  └─ Valor II → III → IV → V
│
├─ 🔵 BARRIDO DE MONEDAS
│  Recoger deslizando el dedo
│  └─ 🔵 RADIO I
│     ├─ Radio II → III → IV → V
│     └─ 🔵 IMÁN
│        └─ ATRACCIÓN I → II → III
│
└─ 🟣 MANO II · 30 monedas
   Puedes llevar 3 bolas
   ├─ Mano III → IV → V
   │  4 → 5 → 6 bolas
   └─ 🟣 DESBLOQUEAR ESCOBA · 20 monedas
      └─ 🟣 ANCHURA I
         ├─ Anchura II
         │  ├─ Anchura III → IV → V
         │  └─ 🔴 ROBOT AYUDANTE
         │     └─ VELOCIDAD I
         │        └─ II → III → IV → V
         └─ 🟣 TRANSFORMAR ESCOBA EN V
```

**Requisitos adicionales:** Doble emisión requiere también Anchura III, para que la mejora de producción tenga una herramienta de control disponible. Robot requiere también Barrido de monedas, para haber introducido la recogida por deslizamiento antes de automatizar el empuje. Comprar el robot no automatiza la recogida de monedas.

Estas dos conexiones adicionales forman parte del mapa aunque no se repitan como líneas cruzadas en la versión estrecha para móvil. Doble emisión cambia todas las emisiones a dos bolas; no se suma con otra mejora de cantidad.

## Primeros pasos del jugador

1. Sin mejoras: mano de una bola, 1,5 bolas/s, $1 por captura, 10 s de producción y 3 s de recogida final.
2. Primera compra: Mano I por 20 monedas. Poder transportar dos bolas cambia el control antes de aumentar la carga del tablero.
3. Se abren cuatro decisiones: producir más, ganar más por captura, recoger deslizando o ampliar la mano.
4. Mano II abre la compra de la escoba; esta compra abre las mejoras de anchura; Generador II abre el tiempo de producción. Valor I está disponible pronto y no obliga a invertir primero en varios niveles de producción.
5. Anchura I abre la escoba en V; Anchura II y Barrido permiten llegar al robot.
6. Generador III y Anchura III abren Doble emisión: salto de producción tras invertir en control.

La mano recoge hasta su capacidad cerca del punto de agarre y mantiene el grupo durante el arrastre. El lanzamiento libera las bolas con la velocidad del gesto. La escoba empuja grupos sin usar la capacidad de mano. Radio de recogida se refiere siempre a monedas, no a bolas.

La escoba aparece como objeto físico únicamente después de comprar su desbloqueo. Una vez comprada, la mano siempre puede agarrarla. La V transforma esa misma escoba; no añade otra herramienta ni un selector separado. Esto aplica la corrección más reciente del usuario.

La mejora pendiente de mano para recoger dos monedas cercanas es una mecánica de recolección distinta de transportar más bolas. Sigue pendiente en el seguimiento y aún debe decidirse dónde conectarla en este mapa; no se considera sustituida por Mano I.

## Costes del mapa implementado — pendientes de revisión con CF-01

Los precios son una primera hipótesis de balance, no cifras ya probadas jugando.

Para una línea de niveles:

**Coste del nivel n = precio inicial × 1,65^(n−1), redondeado a la decena más cercana.**

Se redondea al final, no a partir del precio ya redondeado del nivel anterior. Los desbloqueos de mecánicas tienen precio propio.

| Línea | I | II | III | IV | V |
| --- | --- | --- | --- | --- | --- |
| Mano | 20 | 30 | 50 | 90 | 150 |
| Generador | 30 | 50 | 80 | 130 | 220 |
| Valor | 40 | 70 | 110 | 180 | 300 |
| Radio de recogida | 30 | 50 | 80 | 130 | 220 |
| Anchura de escoba | 40 | 70 | 110 | 180 | 300 |
| Día más largo | 80 | 130 | 220 | 360 | 590 |
| Velocidad del robot | 100 | 170 | 270 | 450 | 740 |

| Desbloqueo | Coste | Requisitos |
| --- | --- | --- |
| Desbloquear escoba | 20 | Mano II |
| Barrido | 25 | Mano I |
| Escoba en V | 160 | Anchura I |
| Imán | 180 | Radio I |
| Robot ayudante | 300 | Anchura II + Barrido |
| Doble emisión | 500 | Generador III + Anchura III |
| Atracción I / II / III | 80 / 130 / 220 | Imán; después, nivel anterior |

Atracción usa la misma fórmula, con precio inicial 80. Los precios son por nodo, no acumulados.

## Efectos actuales del mapa

| Línea | Progresión propuesta |
| --- | --- |
| Mano | Capacidad = 1 + n: 2, 3, 4, 5, 6 bolas. |
| Generador | Frecuencia = 1,5 × 1,25^n bolas/s antes de Doble emisión: 1,88; 2,34; 2,93; 3,66; 4,58. |
| Valor | Base $1; niveles comprados conservados: $3, $4, $5, $8 y $11 por captura. Balance definitivo pendiente. |
| Radio | 18 + 6n: 24, 30, 36, 42, 48 unidades lógicas. |
| Anchura | 80 + 16n: 96, 112, 128, 144, 160 unidades lógicas. |
| Día más largo | Producción = 10 + 3n: 13, 16, 19, 22, 25 s. Mantiene 3 s de recogida final. |
| Velocidad del robot | 45 × 1,15^n: aproximadamente 52, 60, 68, 79, 91 unidades/s. |
| Imán | Desbloquea atracción alrededor del dedo activo, con radio 65 unidades. |
| Atracción | Radio del imán = 65 + 10n: 75, 85, 95 unidades. |

Los valores sustituyen a los del nivel anterior. La mano, la anchura, el radio y el tiempo crecen de forma moderada: su límite es el espacio y la interacción. La producción y el valor aportan el crecimiento exponencial.

Los cinco niveles dibujados son el alcance inicial de esta revisión. Las ramas pueden recibir nuevos niveles y bifurcaciones; todavía no se define un bucle infinito ni un sistema de prestigio.

## Cómo comprobar que la progresión funciona

Ingreso teórico por día:

**Bolas/s × bolas por emisión × segundos de producción × monedas por bola × proporción capturada × proporción cobrada.**

En la tabla de Generador, «bolas/s» equivale a emisiones/s antes de Doble emisión. Esta mejora duplica las bolas por emisión sin cambiar el intervalo. Los dos últimos factores de la fórmula están entre 0 y 1: producir más no equivale automáticamente a cobrar más.

Con CF-01 implementado en esta revisión, la referencia inicial es **1,5 bolas/s × 10 s × $1 = $15 por día**, antes de pérdidas. La recogida final base dura tres segundos. Las jornadas antiguas conservan su configuración hasta terminar; no se modifica retroactivamente su ingreso.

Las estimaciones antiguas de 30, 56, 278 y 557 monedas por jornada no fijan el nuevo balance. Se recalcularán cuando se defina la mejora de Valor y el acceso a las denominaciones superiores.

Objetivos para el primer ensayo:
- Mano I alcanzable en aproximadamente 1–2 jornadas de aprendizaje.
- Primeras compras pequeñas cada 1–3 jornadas con una recogida razonable.
- Desbloqueos de mecánicas más espaciados, con un objetivo inicial de 3–6 jornadas de ahorro.
- Evitar que subir generación empeore sistemáticamente lo que se cobra por saturación del tablero.
- Comparar generación, valor y recogida para que ninguna sea siempre la mejor compra.

Se ajustarán costes, multiplicadores y requisitos después de medir ingresos reales y tiempo entre compras. La fórmula de precios por sí sola no garantiza estos ritmos.

## Pendiente de validar o ampliar

- Medir costes, ingresos reales y tiempo entre compras jugando en móvil.
- Situar la mejora de recoger dos monedas: es una mecánica distinta de llevar varias bolas y sigue pendiente.
- Ensayar sensación de control y rendimiento en Android físico. La prueba de saturación con 200 bolas comprueba límites y estabilidad numérica, no certifica FPS.
- Añadir futuras ramas o niveles solo con una nueva decisión de diseño.

Los guardados antiguos conservan las compras sin añadir mejoras gratis. Las jornadas activas usan sus valores históricos hasta terminar; las nuevas usan el CSV del mapa. Las compras posteriores sí exigen los requisitos nuevos.

## Ficha para añadir nodos juntos

| Campo | Qué definimos |
| --- | --- |
| ID | Identificador estable, por ejemplo `hand:1`. |
| Nombre | Texto visible. |
| Tipo y color | Efecto principal y color heredado. |
| Efecto | Fórmula o desbloqueo concreto. |
| Coste | Precio de esa compra. |
| Padres | Todos los requisitos, incluidos los de otra rama. |
| Desbloquea | Siguientes nodos. |
| Rango máximo | Nivel final de esta revisión. |

## Historial

- **v0.1:** propuesta inicial sin verificar.
- **v0.2:** referencia del árbol real del código, conservada en documento separado.
- **v0.3:** propuesta con capacidad de mano, seis tipos con color, especializaciones, cinco niveles y crecimiento multiplicativo.
- **v0.4:** se establece como referencia viva de cambios futuros; respeta escoba inicial y transformación en V, distingue mejora de dos monedas de capacidad de bolas y conserva el árbol actual por separado. Balance y detalles pendientes de revisión.

- **v0.5 · 2026-10-19:** CF-01 valor base de $1 y denominaciones con colores; CF-02 recogida final base de 3 s; CF-03 estadísticas → árbol → comenzar día; CF-04 iconos y colores de mejoras compradas, apagadas o iluminadas en blanco al poder comprarlas. Requisitos registrados y pendientes.
- **v0.6:** mapa implementado por petición del usuario, con Mano I de dos bolas, capacidad +1 por nivel y escoba comprada. Doble emisión, alcance, cinco niveles, colores por tipo y migración forman parte de 0.3.0+5. CF-01 a CF-04 se conservan pendientes.

- **v0.7 · 2026-10-19:** monedas sin cifras ni símbolos, CF-01 a CF-04 implementados para revisión; esquema JSON v4 conservado y balance 5 para jornadas nuevas. Balance 4 congelado para recuperar jornadas interrumpidas. No se genera APK ni se acredita prueba en Android físico en esta revisión.

- **CF-05 · 2026-10-19:** interfaz compacta, ficha bajo demanda y compra de un segundo, implementadas en rama para revisión. Las notas históricas de compra de tres segundos quedan sustituidas por CF-05.

- **v0.8 · 2026-10-19:** se registran CF-06 (estadísticas visuales y minimalistas) y CF-07 (nodos aún más cercanos y colocación en ocho direcciones). Se comprueba que las últimas mejoras de mano, cabecera y bolas doradas ya están en `main`; esta revisión solo documenta el trabajo siguiente.

- **v0.9 · 2026-10-19:** CF-06 a CF-08 implementados por autorización del usuario, con estadísticas visuales, geometría de ocho direcciones y cinco mejoras de fuerza de mano. 107 pruebas locales y en CI correctas; APK 0.4.0+9 entregado en la pipeline 39223285776.

- **v1.0 · 2026-10-19:** CF-09 a CF-15 registrados como siguientes tareas de UI, monedas, recogida y balance; duplicadora y bomba anotadas como ideas aún sin especificar.
- **v1.1 · 2026-10-19:** CF-09 a CF-15 implementados por petición del usuario, sin las ideas de bolas. Guardado v5, balance 6, 116 pruebas correctas; ver decisiones y evidencias al principio.
