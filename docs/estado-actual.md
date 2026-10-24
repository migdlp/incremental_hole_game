# Estado actual de Feed the Hole

> **AJ-005B:** [cuotas infinitas por bolas capturadas](aj-005b-cuotas-infinitas.md), sin vencimiento ni
> derrota por cuotas, con excedentes, crecimiento AJ-005A y eventos P01. JSON v14.
> Esta actualización prevalece sobre las reglas históricas de alimentación.

## AJ-007 · Feedback audiovisual (0.19.0+30)

Audio offline centralizado con plops variables, absorción y rodadura compartidas,
cascadas musicales de monedas y cristal/estrellas. Háptica agrupada independiente,
volumen persistente y controles DEBUG. Cada bola se hunde bajo el borde del hoyo;
reacciones agrupadas y compatibles con su crecimiento. Sin cambios económicos.
Escucha, vibración y rendimiento en Android físico pendientes de calibración.
[Arquitectura, recursos, pruebas y límites](aj007-feedback-audiovisual.md).


Validado en GitHub Actions: formato, análisis, **410 pruebas**, compilación Android
y firma correctos. Código `46b623a`.
[Descargar APK 0.19.0+30 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40140079810/artifacts/12578322298).
Comparación de firma con APK anterior no ejecutada; no certifica actualización.

## BUG-001 · Lluvia de monedas (0.18.1+29)

Microlotes de 200 ms, siete monedas para 34, expansión exacta y variada para
recompensas grandes, pool reutilizable y agrupación solo bajo presión. Los
recuentos del resumen AJ-008A proceden del microlote, no de los iconos agrupados.
Salida normal en 0,2–0,32 s; se mantiene la pausa tras el salto. Pool inicial
provisional de 192 basado en medidas de Cloud; rendimiento Android físico
pendiente, sin certificación de 60 FPS. Balance v20, con v19 congelado.
Incluye el rediseño AJ-008A. [Detalles y mediciones](bug001-lluvia-monedas.md).

Validado: formato, análisis y **392 pruebas**, compilación Android y firma.
Código compilado `d41b711`; [APK 0.18.1+29 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40118367557/artifacts/12569447730). Incluye AJ-008A y BUG-001.

## AJ-008A · Resultados animados (0.18.0+28)

Nuevo modal con monedas por denominación hacia el monedero real, seguido del
progreso del hoyo; Tienda aparece al finalizar. Saltos por bloque, movimiento
reducido y scroll móvil. Contabilidad de presentación separada del cobro real.
Paleta 1/10/50/100/500: bronce/plata/oro/verde/rojo. Sin cambios económicos.
Mockup y vídeo no adjuntos: fidelidad visual pendiente de cotejar; pruebas en
Android físico pendientes. [Detalles, archivos y validación](aj008a-resultados.md).

## AJ-005A · Crecimiento por cuota (0.17.0+27)

Cada cuota completada aumenta el **área de captura un 16 %**, una sola vez:
radio = radio base × √(1,16^cuotas). El dibujo y la captura usan el mismo radio.
Se aplica en la jornada actual y persiste entre jornadas y reinicios; se pierde
al terminar la partida normal, como el resto de su progresión temporal.
No depende de compras, no añade nodos y conserva el centro al 22 % de altura.
JSON v13 registra número de crecimientos y última cuota aplicada. Los guardados
anteriores conservan su progreso y empiezan a crecer con la siguiente cuota;
las cuotas ya completadas no se vuelven a premiar. Balance v19 sin cambios.
Los tiempos y la estética de monedas de 0.16.2 se conservan.
**Decisión consultada aún abierta:** tamaño al llegar a los bordes. No se añade
un tope de balance sin aprobación; se mantiene el crecimiento solicitado del 16 %.

Validado: formato, análisis y **369 pruebas**, compilación Android y firma.
Código compilado `9615d08`; [APK 0.17.0+27 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40111416219/artifacts/12566373126). Prueba táctil en Android físico pendiente.

## Tiempos de monedas · 0.16.2+26

Se conserva el dibujo, el salto de salida y el recorrido de las monedas.
Tras aterrizar quedan inmóviles **1 segundo** y después vuelan al monedero
con un inicio más lento y aceleración progresiva, manteniendo el final suave.
El cobro visual espera también esa pausa; importes, liquidación al cerrar,
restauración y ausencia de física/interacción permanecen iguales.
Incluye la corrección del hoyo al 22 % de altura descrita debajo.

Validado: formato, análisis y **360 pruebas**, compilación Android y firma.
Código compilado `e409af8`; [APK y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39861748135/artifacts/12462915831). Sin prueba táctil en Android físico.

## Posición actual · 0.16.1+25

Por nueva indicación del usuario, el hoyo pasa del 74 % al **22 % de altura**:
centro **(180,123.2)**, con la horizontal en 180. Captura, succión, monedas y
estrellas comparten la posición. Balance v19 con v18 congelado; las jornadas
ya empezadas conservan su configuración y la siguiente usa el 22 %.
La aclaración posterior AJ-005A vincula el crecimiento a cuotas; esta entrega histórica solo cambió la posición.

## Entrega anterior · AJ-001 a AJ-004 (0.16.0+24)

Fuerza de agarre alta desde el inicio, sin niveles ni rama; capacidad 1–6
conservada. Compras de fuerza anteriores devueltas una sola vez. Monedas con
cara/canto/grabado y contador sin fondo. Hoyo en (180,414.4), aproximadamente al 75 % del tablero,
con origen compartido por captura, succión, monedas y estrellas.

JSON v12 / balance v18 con v17 congelado para jornadas ya empezadas. Su siguiente
jornada aplica los cambios. Acercar el hoyo al generador hace posibles capturas
rápidas automáticas: no se compensan cambiando otras mecánicas.
**Aclaración posterior AJ-005A:** el crecimiento corresponde a cuotas completadas;
no se añade una rama de nivel del agujero. [Estado y compatibilidad](ajustes-version-actual.md).

## P01 · Estrellas y burbujas físicas (0.15.0+23)

Completar una cuota expulsa burbujas físicas; agarrarlas y lanzarlas contra paredes
o herramientas permite romperlas y cobrar estrellas permanentes. Un premio por
cuota y un cobro por identidad, separados del vuelo visual. Pendientes reaparecen
entre jornadas, con un límite de cuerpos activos que no elimina recompensas.
**Al morir o prestigiar se pierden las pendientes; las cobradas se conservan.**
Esta regla P01 sustituye la conservación opaca provisional descrita en la entrega
S03 inferior. No se convierten pendientes en saldo automáticamente.

JSON v11 / balance v17 con v16 congelado. DEBUG permite forzar premios y ajustar
todos los parámetros provisionales. Gravedad/succión se comparan mediante
interruptores experimentales en DEBUG; su integración final sigue abierta.
P02 y BAL01 continúan pendientes. [Contrato y pruebas](p01-estrellas-burbujas.md).

## Entrega anterior S03 · Prestigio y derrota (0.14.0+22)

**Decisión expresa del usuario:** activar derrota en juego normal con las cuotas
provisionales actuales. Al incumplir el quinto día se termina la partida y aparece
**DERROTA**, sin estadísticas. Continuar abre la tienda de prestigio; Nueva partida
vuelve al día 1. Se reinician monedas, mejoras, herramientas y alimentación, y se
conservan estrellas cobradas, compras permanentes, descubrimientos y datos P01 pendientes.

Nodo Prestigio visible desde el comienzo al explorar, mayor y girado 45°, tanto en
normal como DEBUG. Su compra exige confirmación y reinicia inmediatamente, sin
botón posterior. Configuración de prueba: 10.000 monedas, Generador V + Valor V +
Duración V, esquina avanzada (48,48). **No son decisiones finales de BAL01.**

La tienda muestra estrellas y permite nueva partida, sin catálogo P02 ni premios
P01 inventados. Morir no concede estrellas. JSON v10 / balance v16, con v15 congelado.
Checkpoint permanente independiente, dos copias actuales y barrera de revisión:
una copia normal antigua no puede reabrir una partida terminada. DEBUG es temporal.
[Contrato, integración y pruebas](s03-prestigio-metaprogresion.md).

S03 sustituyó las cuotas sin derrota. P01 ya añade burbujas; P02 y BAL01 siguen pendientes.

## C01 · Cobro automático vigente (0.13.0+21)

Cada captura calcula una única recompensa completa (Valor, dorada y racha),
alimenta inmediatamente y registra el importe garantizado. Tras aproximadamente
1 s, una moneda decorativa salta del hoyo y vuela en curva al monedero; el saldo
visible aumenta al recibirse. No hay colisiones, recogida manual ni fase final
de recogida: producción base 15 s y cierre directo con liquidación íntegra.

Barrido, Área, Imán y Atracción salen del catálogo activo. El usuario autorizó
retirar sus compras **sin reembolso**; no se altera saldo ni otras mejoras.
Robot conserva solo Escoba ancha II como requisito, confirmado por el usuario.
JSON v9 / balance v15, con v14 congelado para física de jornadas antiguas.
Registros económicos y pool visual independientes; agrupación u omisión visual
no pierde dinero. Restaurar liquida directamente lo pendiente, una sola vez.
[Implementación, DEBUG y medición pendiente](c01-cobro-automatico.md).

Las referencias anteriores a recogida manual o fase final describen versiones
históricas y quedan sustituidas por C01.

Actualizado: **24/10/2026**. Referencia de APK entregado: **0.18.1+29**. La revisión `d41b711` incluye AJ-008A, microlotes BUG-001 y crecimiento AJ-005A por cuota, pausa y aceleración de monedas, hoyo al 22 %, AJ-001–AJ-004, P01 Estrellas y burbujas, S03 Prestigio, C01 Cobro automático y S01 Alimentación y cuotas, M03 Generador lanzador, E02 Agujero negro, E01 Gravedad, M02 Bate de béisbol y M01 Paredes rebotadoras y conserva interfaz simplificada, feedback visual opcional desactivado por defecto, racha comprable, especiales, escoba de dos puntos y botón DEBUG. Este documento describe lo que existe; las propuestas pendientes están en [cambios futuros](cambios-futuros-arbol-mejoras.md). Para continuar en otro chat, empieza por el [relevo de contexto](relevo-contexto.md).

## Juego y dirección

Juego incremental móvil con físicas arcade. El jugador manipula bolas para meterlas en un agujero, cobra automáticamente sus recompensas y compra mejoras permanentes entre jornadas. La automatización debe ayudar a agrupar y dirigir bolas, manteniendo una ventaja clara para quien juega activamente.

Los cuatro ejes de progresión son generar más bolas, capturar una proporción mayor, aumentar el valor de las capturas y aprovechar sus recompensas. El sistema de tiers individuales y la fábrica configurable son dirección futura, todavía no sistemas implementados.

## Jornada y tablero vigentes

- Arena lógica de 360 × 560. **Hoyo al 22 % de altura** en (180, 123.2) y **generador abajo** en (180, 480), con salida y velocidad inicial de las bolas hacia arriba. Ajuste de posiciones en código posterior al APK del commit `046ebb0`; pendiente de comprobar en móvil. Se retira la leyenda del jardín del tablero y la frase «Tu jardín te espera» de la pausa.
- Base de **15 s de producción sin fase final de recogida**, con una sola barra en el mismo sitio: verde durante producción; contador pequeño encima y alineado a la derecha, sin rótulos de fase. Las mejoras de duración dan 18/21/24/27/30 s de producción; cierre directo con liquidación completa.
- Emisión inicial de **1,5 bolas/s**: primera bola tras aproximadamente ⅔ s. Generador y Doble emisión aumentan la producción.
- Durante producción se controlan bolas y las recompensas vuelan automáticamente al monedero. Al terminar se liquidan todas las pendientes antes de resultados.
- Al terminar, lo pendiente se cobra íntegramente. El tablero siguiente reexpulsa las burbujas de estrellas pendientes y conserva saldo y mejoras.
- Límite de **200 bolas**; monedas solo decorativas con pool configurable y agrupación. Presupuesto inicial provisional 24, pendiente de medir en Android.
- Pausa y segundo plano detienen la simulación. No hay ingresos por tiempo con el juego cerrado.

## Paredes rebotadoras · M01

Las cuatro paredes rebotan desde el inicio (×0,40). La mejora permanente tiene tres compras: I ×1,10, II ×1,35 y III ×1,60; límite global de bolas 380 u/s. Todas las bolas, incluidas doradas, usan la misma respuesta; las monedas no cambian y las bolas siguen congeladas al recoger. Las paredes mejoradas muestran línea elástica, deformación y ondas transitorias.

Las compras se conservan al reiniciar y se aplican desde la jornada siguiente. Requisito Mano I y costes 40/100/220, multiplicadores y límite son **provisionales de prueba**, no balance aprobado. [Detalle de implementación y pruebas](m01-paredes-rebotadoras.md).

## Bate de béisbol · M02

Prototipo **0.8.0+16**, incluido en el APK enlazado abajo. Bate I desbloquea un
objeto físico independiente de la escoba; II–III solo aumentan el impulso activo.
Un dedo traslada, dos trasladan/giran y soltar conserva la pose. Se comparte
control de dos puntos con la escoba. El impulso usa velocidad relativa y giro;
rebote pasivo constante y límite final 380 u/s. No repite bonificación en contacto
continuo, no afecta monedas ni activa especiales directamente. Recogida congela
el bate. Se guardan compras y pose de la jornada; DEBUG no altera el progreso real.

Precios 60/120/240, Mano I y potencias ×1/×1,35/×1,70 son **provisionales de prueba**.
Destellos sujetos a Feedback visual; clic sujeto a Sonidos del sistema y nueva
preferencia Vibración, activada inicialmente. Impactos agrupados y limitados a
una respuesta cada 120 ms. [Física, guardado y pruebas](m02-bate-beisbol.md).

## Alimentación y cuotas · S01

Cada captura alimenta con toda su recompensa, incluidos racha y dorada ×10.
**Captura total sigue la misma regla**, por decisión expresa del usuario.
No hace falta recoger las monedas y alimentar no descuenta dinero.
Anillo alrededor del hoyo y resumen entre jornadas; períodos de cinco jornadas,
sin cierre anticipado al cumplir; P01 añade las burbujas de estrellas. Al empezar el siguiente período
se reinicia la alimentación y aumenta la cuota.

El usuario aprobó **cuotas provisionales también en juego normal**: objetivo
inicial 10 y aumento 10 por período, centralizados en `balance.csv`. Son valores
para probar, pendientes de BAL01, no balance definitivo. S03 activa ahora la derrota al incumplir, también en juego normal por autorización
expresa del usuario; los valores continúan provisionales hasta BAL01.
DEBUG permite simular un fallo reversible sin modificar la partida real.
JSON v8 / balance v14, con v13 congelado y sin inventar capturas históricas.
[Alcance y prueba](s01-alimentacion-cuotas.md).

## Generador lanzador · M03

Prototipo **0.11.0+19**: segundo emisor independiente, desbloqueable en rama de
Producción, con frecuencia propia y potencia fija. Se traslada con un dedo y gira
con dos; cuerpo/cañón completos limitados al 25 % inferior. Sigue disparando
agarrado, sin retroceso. Tres bolas no lo mueven; suficiente presión real de
contactos puede desplazarlo lentamente sin girarlo. Salida bloqueada descarta el
intento sin superposición ni ráfaga posterior. Pose entre jornadas/reinicios,
reloj/RNG en jornada, pausa/recogida congelados y DEBUG aislado. Desbloqueo tras
Generador II, costes y física **provisionales**. [Contrato y pruebas](m03-generador-lanzador.md).

## Agujero negro · E02

Prototipo **0.10.0+18**: 5 % independiente cada 3 s de producción, sin sensores;
pueden coexistir varios objetos. Necesitan 3–6 toques. Succión ampliada hasta 10 s
solo en bolas libres, sin cambiar captura, monedas ni herramientas. Otra
activación restablece 10 s sin acumular radio/potencia. Pausa y restauración
conservan objetos, daños y duración. Recogida retira todos los objetos y el
efecto, por decisión del usuario. DEBUG → Agujero negro fuerza 1–3 objetos
temporales. Parámetros, estética y sonido finales pendientes de pruebas.
[Contrato y guía E02](e02-agujero-negro.md).

## Gravedad · E01

Prototipo **0.9.0+17**, incluido en el APK enlazado abajo. Evento aleatorio desde la primera
jornada compatible: probabilidad configurable 5 %, un objeto móvil durante
producción y 3–6 pulsaciones para romperlo. Activa inclinación del teléfono hasta
10 s o hasta recogida, con anuncio breve. La detección Android exige
lecturas válidas; sin hardware compatible no aparece en juego normal.

Mueve bolas y escoba/bate libres, con fuerza gradual y límite técnico existente.
No afecta agarres ni monedas. Pausa/segundo plano congelan el tiempo; guardar y
cargar conserva estado y duración sin repetir activación. DEBUG → Gravedad permite
forzar y simular inclinaciones sin escribir progreso normal. No añade compras ni
nuevas bolas o herramientas. Física y aspecto provisionales; daño por bolas y
reglas de futuros eventos simultáneos siguen abiertos. [Detalle E01](e01-gravedad.md).

## Mano, escoba y robot

- Mano base de una bola. Mano I cuesta **13** y permite dos; los cinco niveles alcanzan 2/3/4/5/6 bolas.
- La primera bola se agarra manualmente. Solo una mano ya ocupada atrae bolas adicionales cercanas, hasta su capacidad. Conservan movimiento físico, retraso e inercia y pueden soltarse con tirones fuertes.
- Fuerza de agarre I–V acelera la aproximación y refuerza la sujeción de las bolas adicionales. No aumenta capacidad ni recoge monedas.
- La escoba se desbloquea tras Mano II. Es un objeto físico que se puede agarrar; Anchura y V modifican esa misma herramienta. Empuja bolas y no cobra monedas.
- La escoba muestra dos puntos de agarre. Un dedo traslada conservando orientación; dos dedos fijan traslado y giro, sin estirar la herramienta. Al levantar uno se conserva el otro agarre; pausa/cancelación/recogida liberan ambos. El giro mantiene límite físico de 3 rad/s. La V usa el mismo control.
- Un robot desbloqueable empuja bolas hacia el agujero; su velocidad se mejora. No recoge monedas.
- **Mientras haya alguna bola agarrada, se bloquean tanto el cobro como la atracción de monedas.**

## Monedas, recompensa y combos

- Cobro automático completo, independiente de animaciones, sin toque/barrido ni monedas físicas.
- Valor global 1/2/3/5/8/13, dorada ×10 y racha conservados. Alimentación al capturar.
- Salida visual tras aproximadamente 1 s, arco y vuelo al monedero; saldo visible al llegar.
- Cierre liquida pendientes; pausa congela animaciones. Restaurar liquida sin duplicar.
- Barrido, Área, Imán y Atracción retirados sin reembolso, autorizado por el usuario.
- Resultados muestran ingreso íntegro, sin recuento de monedas físicas ni pérdidas por no recoger.
- Racha comprable en el árbol (`combo`): requiere Mano I y cuesta **40**. Sin comprarla no hay racha ni multiplicadores. Una vez desbloqueada: ventana inclusiva de **1 s**; capturas 1–4 **×1**, 5–9 **×2**, desde la décima **×3**. La quinta y décima usan ya su nuevo multiplicador. No se modifican premios anteriores.
- Se combinan Valor × dorada × combo. Toda recompensa se cobra automáticamente. Todas las capturas, incluidas las asistidas, cuentan provisionalmente.
- La racha termina al superar la ventana o terminar producción. Pausar y restaurar no consumen tiempo. Un indicador muestra «Racha lista», contador desde la primera captura, multiplicador y barra de tiempo restante. No se explican los umbrales ni la fórmula en pantalla.

## Habilidades especiales comprables

**Balance provisional de prueba**, ajustable desde `balance.csv`:

| Mejora | Requisito | Coste | Efecto |
| --- | --- | --- | --- |
| Captura total | Racha | 120 | Captura todas las bolas presentes al activar. |
| Recarga de captura I / II | Captura total | 160 / 280 | Carga de 12 → 10 → 8 s. |
| Aceleración especial | Generador I | 100 | Generación ×2 durante 4 s. |
| Potencia de aceleración | Aceleración | 220 | Generación ×3 mientras está activa. |
| Duración I / II | Aceleración | 140 / 240 | Duración de 4 → 5 → 6 s. |
| Recarga de aceleración I / II | Aceleración | 140 / 240 | Carga de 10 → 8 → 6 s. |

Los botones «Captura» y «Turbo» muestran carga/lista y duración activa. Se empieza
cada día sin carga; solo carga el tiempo de producción simulado. La aceleración
recarga después de terminar su efecto. No se pueden activar en pausa ni en
recogida final. Captura total sin bolas conserva la carga. Solo captura las bolas
presentes al pulsar, no futuras emisiones; genera monedas físicas y usa los combos
si se han comprado. No cobra dinero directamente. La aceleración respeta el
límite de 200 bolas y los obstáculos de salida. Las jornadas debug permiten
comprarlas y probarlas sin escribir progreso real. No son las tres habilidades
aleatorias propuestas en CF-19, que siguen pendientes.

## Árbol e interfaz

**60 nodos en 23 tipos**, incluido el nodo de acción Prestigio, con Generación verde, Valor dorado, Control violeta, Tiempo naranja, Automatización coral y la acción especial de Prestigio. Mapa y requisitos completos: [árbol vigente](arbol-de-mejoras.md). Precios y efectos exactos: [balance.csv](balance.csv).

- Pantalla independiente, sin título, botón visible de atrás ni botones de zoom. Navegación con arrastre y pellizco.
- Descubrimiento progresivo: comprados y siguientes nodos accesibles. La partida nueva comienza mostrando Mano I.
- Nodos comprados con icono y color de categoría; pendientes apagados, comprables con iluminación blanca suave. Conexiones de tramos rectos horizontales, verticales o diagonales.
- Sin ficha inicial. Tocar un nodo muestra una frase esquemática, cantidades destacadas en verde, coste y requisitos. La compra exige mantener su botón **1 s**; soltar antes, mover, interrumpir o usar otro dedo cancela.
- Resultados → botón único «Tienda» → tienda → «Comenzar día». La bienvenida de una partida nueva conserva su inicio directo.

## Debug implementado

Acceso directo: botón **DEBUG**, arriba a la izquierda del árbol. Un toque abre el panel; el saldo ya no requiere ni reconoce una pulsación mantenida para entrar.

- Vista completa: encuadra los 60 nodos. Permite comprar gratis cualquier nodo y adquirir también sus requisitos, o comprar todo (excluye Prestigio para no terminar la prueba).
- Vista del jugador: descubrimiento y compras normales usando saldo y mejoras de prueba. Ambas vistas comparten esa configuración; para ver el principio hay que reiniciar la prueba desde cero.
- Añadir 1000 monedas de prueba, reiniciar, jugar jornadas de prueba y salir.
- La prueba es temporal: no sobrescribe el progreso normal. Salir o reabrir recupera la partida real. Durante una jornada de prueba se muestra DEBUG y un botón de salida.
- [Instrucciones detalladas](modo-debug.md).

**Incluido en el último APK:** el panel debug muestra el informe
de la última jornada y permite copiar los últimos 20: emisiones efectivas,
capturas, doradas, pico de combo y recompensas generadas/abonadas. Estos
datos son temporales y se descartan al reiniciar la prueba o salir. Incluido desde la revisión `4d815d9` y conservado en el último APK. Las nuevas bolas aún no se
han implementado: está pendiente discutir las reglas del prototipo.

## Entrega y comprobaciones

**[Descargar APK 0.18.1+29 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40118367557/artifacts/12569447730)**. Descomprimir `feed-the-hole-debug.apk`; es un APK de depuración para pruebas, no una publicación en tienda. Los artefactos de GitHub tienen retención limitada y pueden requerir iniciar sesión.

[Pipeline de esa entrega](https://github.com/migdlp/incremental_hole_game/actions/runs/40118367557): formato, análisis, **392 pruebas**, compilación Android y verificación de firma correctos. Código compilado: `d41b711`. Incluye AJ-001–AJ-004, P01 Estrellas y burbujas, S03 Prestigio, C01 Cobro automático, S01 Alimentación y cuotas, M03 Generador lanzador, E02 Agujero negro, E01 Gravedad, M02 Bate, M01 Paredes rebotadoras, Racha comprable, especiales, escoba de dos dedos, informes de prueba, botón DEBUG y el ajuste de posiciones.

Las pruebas del debug de esa entrega comprobaron acceso por botón, presencia y encuadre de los 60 nodos, compra de un nodo profundo, ambas vistas, restauración del progreso y pantalla pequeña. Las de juego cubren capturas, grupos, escoba, robot, monedas, ciclo y guardado. **No equivalen a una prueba en Android físico.** El usuario dijo que el «modo dibujo» no funcionaba en un APK anterior; se trató como el modo debug del árbol. No consta aún una confirmación manual del último APK.

La revisión entregada pasa 359 pruebas automáticas, además de análisis sin avisos.
Incluyen compra y persistencia de Racha, cargas/activaciones de especiales,
compatibilidad con jornadas anteriores, eventos reales de dos dedos y pantalla
de 320 × 568 con texto al 150 %. La pausa permite desplazar su panel si el
espacio es reducido. La pipeline genera el APK, pero no sustituye la prueba física.

La pipeline estándar verifica la firma de esta APK, pero no resuelve la incompatibilidad con la firma de APK anteriores detectada en [G01](g01-feed-the-hole.md). No desinstalar la anterior si se quiere conservar su progreso.

Pendiente de validar en móvil: acceso debug con dedo, legibilidad del árbol y fichas, tacto y rendimiento con carga, guardado/segundo plano/cierre y diversión del nuevo tablero. Falta medir ingresos y jornadas entre compras para ajustar el balance.

## Persistencia y alcance técnico

Flutter/Dart con Flame, Android vertical y web de apoyo. Juego individual sin cuentas, backend ni dependencia de conexión.

Guardado JSON **v13** y balance vigente **v20** son números diferentes. Se conservan saldo y compras; las jornadas activas con balances 1–16 mantienen su configuración económica y tiempos hasta terminar. El siguiente día usa el balance actual. Los guardados anteriores a combos terminan esa jornada sin introducirlos a mitad. Una jornada antigua con racha gratuita conserva su comportamiento hasta terminar; en la siguiente jornada se requiere comprar Racha. No se eliminan ni regalan compras para aplicar el cambio. Las cargas y activaciones pendientes de las especiales se guardan; una pausa o reapertura no concede tiempo ni ejecuta dos veces Captura total. S03 permite reiniciar expresamente la partida al incumplir cuota o comprar Prestigio tras confirmar, conservando la metaprogresión.

No hay tiers individuales, potenciadora, duplicadora, bomba, cartas, flippers, bumpers, fábrica configurable, catálogo permanente de P02 ni progreso offline. Sus reglas pendientes están en [cambios futuros](cambios-futuros-arbol-mejoras.md).

## Orden de lectura y continuación

1. [Relevo](relevo-contexto.md) y este estado actual.
2. [Cambios futuros](cambios-futuros-arbol-mejoras.md): pendientes y decisiones abiertas, no lista de tareas ya terminadas.
3. [Árbol](arbol-de-mejoras.md), [economía](economia.md) y [balance.csv](balance.csv) para cambiar reglas concretas.
4. Documentos de implementación, persistencia e historial cuando la tarea lo requiera. Los planes antiguos contienen decisiones reemplazadas; no deben prevalecer sobre este estado y el código.

El último APK se construyó desde `build/apk-0.6.0+13`; no asumir que está integrado en `main`. Para este relevo importan el comportamiento vigente y las decisiones futuras, no reconstruir el historial de commits.

## Simplificación de gameplay incluida en `4d815d9`

No se muestra el número de día en gameplay, resultados ni al comenzar. El saldo
total (saldo guardado más lo recogido durante producción/recogida) y la pausa
negra se superponen dentro del tablero; al terminar no se suman dos veces los
ingresos. Se retiran instrucciones de agarre/cobro, nombres de fases y la
leyenda GENERADOR. El tablero conserva proporciones y gana espacio al compactar
la cabecera. La racha conserva su indicador dentro del tablero.

Los ajustes normales incluyen Sonidos del sistema y Feedback visual. Este último
empieza desactivado y se guarda. Solo controla círculos de pulsación, alcance del
imán y marcas/líneas de agarre; no cambia la física, el alcance ni los controles.
La pausa muestra icono de pausa, Juego pausado, ajustes y Continuar.

## G01 — identidad comercial

El nombre comercial pasa a Feed the Hole en `0.6.0+14`: Android, pantalla de
bienvenida, título de aplicación, errores de inicio y manifiesto/título web.
El package ID, repositorio, nombres internos, rutas de guardado y migraciones
se mantienen. La renombración no toca compras, progreso, físicas ni balance.
Se conserva el historial anterior. La aceptación de actualización requiere
comparar firma y paquete con la APK anterior y comprobarla en un dispositivo.

**Resultado G01:** código de marca publicado en `fd3d8f2`; el APK compila y su
nombre/paquete son correctos. La comparación con la última APK detectó firmas
diferentes y detuvo la publicación. Falta localizar y reutilizar el keystore
original para cumplir la actualización conservando datos.
[Diagnóstico y evidencia de G01](g01-feed-the-hole.md).

**Entrega posterior G01 (21/10/2026):** APK Feed the Hole `0.6.0+14` generada
con la pipeline habitual sobre `4f100fc`, a petición del usuario.
[Descarga](https://github.com/migdlp/incremental_hole_game/actions/runs/39557666293/artifacts/12326019753).
Pasaron formato, análisis, 154 pruebas, compilación y validación del nombre,
paquete y firma del binario. Se omitió la comparación de actualización con la
APK anterior: el conflicto de firma previamente confirmado sigue pendiente.
No presentar esta entrega como actualización que conserve el progreso instalado.

## M01 — Paredes rebotadoras

Las paredes mejoradas y sus tres compras ya están implementadas. Base ×0,40,
I ×1,10, II ×1,35, III ×1,60, límite inicial 380 u/s. Precios y dependencia
Mano I provisionales, sujetos a validación. Compra persistente y aplicación
desde la siguiente jornada; balance v9 con v8 congelado. Efectos elásticos
acotados, independientes de las monedas y de los controles de activación de
especiales. [Especificación implementada y pruebas](m01-paredes-rebotadoras.md).
