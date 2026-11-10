# PRD — Feed the Hole

> **AJ-005B vigente:** la alimentación cuenta exclusivamente bolas capturadas;
> la recompensa monetaria sigue siendo independiente. Cuotas 100/1.000/10.000…
> sin vencimiento, con excedentes y sin derrota.
> [Reglas, crecimiento y migración](aj-005b-cuotas-infinitas.md). Las menciones
> históricas inferiores a alimentación por dinero o derrota quedan sustituidas.


## Ajustes actuales · AJ-001 a AJ-004 (0.16.0+24)

Fuerza de agarre alta desde el inicio, sin niveles ni rama; capacidad 1–6
conservada. Compras de fuerza anteriores devueltas una sola vez. Monedas con
cara/canto/grabado y contador sin fondo. Hoyo en (180,414.4), aproximadamente al 75 % del tablero,
con origen compartido por captura, succión, monedas y estrellas.

JSON v12 / balance v18 con v17 congelado para jornadas ya empezadas. Su siguiente
jornada aplica los cambios. Acercar el hoyo al generador hace posibles capturas
rápidas automáticas: no se compensan cambiando otras mecánicas.
**AJ-005 sigue pendiente de aclarar qué compras activan el crecimiento**: no
existe todavía una rama de nivel del agujero. No inventar esa relación ni añadir
funcionalidades futuras. [Estado y compatibilidad](ajustes-version-actual.md).

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

Revisión: 18 de octubre de 2026 · Referencia: `0.2.1+3` · Reglas acordadas y objetivos pendientes del MVP

Este documento recoge las reglas acordadas y propone el alcance del primer MVP. Los tiempos, costes, cantidades y límites indicados como provisionales deben ajustarse al probar el juego. Las decisiones propuestas no constituyen requisitos ya aprobados.

## Objetivo central aprobado · S01, prototipo

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
S03 aporta ya derrota/reinicio; S02, P02 y BAL01 siguen pendientes; P01 aporta burbujas de estrellas.

## Extensión funcional vigente · M03

[Generador lanzador](m03-generador-lanzador.md): segundo productor físico,
frecuencia independiente y potencia fija. Control de uno/dos dedos, franja
inferior del 25 %, pose persistente, sin retroceso; solo suficiente presión
de contactos lo desplaza lentamente y nunca lo gira. Emisiones obstruidas
consumen intento sin superponer ni acumular. Pausa/recogida congelan; DEBUG
aislado. Precios, requisitos y parámetros provisionales para experimentar.

## Evento funcional vigente · E02

[Agujero negro](e02-agujero-negro.md): sorteos periódicos independientes, varios
objetos sin sensores y 3–6 toques. Amplía atracción sobre bolas libres durante
hasta 10 s, sin ampliar captura ni afectar monedas/herramientas. Otra activación
restablece duración sin acumular fuerza. Recogida retira objetos y efecto; pausa
y restauración conservan el estado. DEBUG aislado; parámetros y estética provisionales.

## Evento funcional vigente · E01

[Gravedad](e01-gravedad.md) aparece aleatoriamente desde la primera jornada
compatible, sin compra: 5 % inicial, un objeto y 3–6 toques para activarlo hasta
10 s de producción mediante inclinación. Afecta bolas y herramientas libres,
no agarres ni monedas. Estado temporal persistente dentro de la jornada, sin
extenderla; DEBUG aislado. Fuerza/aspecto son provisionales; daño por bolas y
composición de futuros eventos siguen abiertos.

## Extensiones funcionales vigentes · M01 y M02

[Paredes rebotadoras](m01-paredes-rebotadoras.md) y [Bate de béisbol](m02-bate-beisbol.md)
son mejoras permanentes del árbol. El bate es independiente de la escoba y usa
uno/dos dedos para trasladar/girar; sus tres niveles solo aumentan potencia activa.
Impulso por movimiento y rotación, rebote pasivo constante y límite técnico
compartido. Sin interacción con monedas ni activaciones especiales adicionales.
No se incluyen otras mecánicas de pinball dentro de M02. Precios, dependencias y
valores físicos de prototipo siguen pendientes de balance y prueba en móvil.

## Identidad comercial — G01

El nombre comercial y visible es **Feed the Hole**. Se aplica al nombre Android,
la interfaz y la versión web. El repositorio sigue siendo
`migdlp/incremental_hole_game` y el identificador Android sigue siendo
`com.migdlp.incremental_hole_game`. No se rediseñan icono, gráficos ni paleta.
Se conservan mecánicas, compras, progreso, claves de guardado y migraciones.
Las referencias de versiones anteriores se conservan como historia.

## 1. Visión

Juego incremental para móvil desarrollado en Flutter. El jugador empuja pequeñas bolas hacia un hoyo y recoge las monedas que salen de él. Cada partida representa un día con tiempo limitado. Por la noche, invierte el dinero recogido en un árbol de mejoras para preparar el siguiente día.

La experiencia debe combinar un gesto agradable de recoger y ordenar, decisiones sencillas de inversión y mejoras que se perciban en el tablero. El ritmo alterna actividad durante el día y planificación sin prisas durante la noche.

## 2. Reglas acordadas

- El generador produce bolas durante el día.
- El jugador empieza agarrando y arrastrando una bola. Después desbloquea escoba recta, anchura y escoba en V para reunir y empujar grupos. Al soltar una bola, su velocidad final determina el lanzamiento.
- Introducir una bola en el hoyo produce monedas físicas en el tablero. El ingreso no se añade automáticamente al saldo.
- Al inicio las monedas se recogen pulsándolas. Recogerlas pasando el dedo por encima requiere comprar la mejora de recogida por barrido.
- El día tiene tiempo limitado y su duración puede mejorarse.
- Al terminar el día, las monedas no recogidas y las bolas restantes desaparecen al pasar a la noche. Cada día nuevo empieza sin bolas ni monedas.
- El dinero recogido y no gastado sí se conserva.
- Por la noche se muestra el resultado del día y se compran mejoras.
- El árbol permite mejorar la interacción manual, la producción, las recompensas y la automatización.
- La noche no tiene límite de tiempo. El jugador inicia el siguiente día cuando quiere.
- Las burbujas u otras monedas especiales quedan fuera de la versión inicial.

## 3. Ciclo de juego

Preparación → comenzar día → generar y empujar bolas → recoger monedas → cierre → resultados y compras nocturnas → siguiente día.

### Día

El tablero muestra el hoyo, el generador, la herramienta, las bolas, las monedas y el robot cuando esté desbloqueado. La interfaz muestra tiempo restante, dinero recogido en ese día y acceso a pausa.

Balance actual para probar: 20 segundos totales, 15 de producción y 5 finales de recogida; emisión inicial cada ⅔ de segundo (1,5 bolas/s). En esos 5 segundos el generador se detiene, pero el jugador y el robot pueden seguir moviendo bolas y recogiendo monedas. Ambos tiempos son provisionales; los 5 segundos forman parte del día y se comunican claramente en pantalla.

La mano transporta una sola bola; las escobas barren grupos con un frente perpendicular al arrastre y giro suavizado. La V reúne por contacto, sin aspirar. El hoyo tiene una pequeña zona de captura para evitar que acertar resulte frustrante. Al inicio hay que pulsar las monedas para cobrarlas: arrastrar para empujar bolas no las recoge. Tras comprar recogida por barrido, pasar el dedo sobre una moneda también la cobra; entonces recogida y empuje pueden compartir gesto, sin cambiar de herramienta.

### Final del día

Al llegar el tiempo a cero se bloquea la interacción, se detienen los robots y se calcula el resultado una sola vez. Las monedas sin recoger desaparecen sin sumarse al saldo.

Regla acordada: al pasar a la noche se retiran todas las bolas y monedas restantes, incluidas las monedas en aterrizaje. El día siguiente comienza sin bolas ni monedas; después funciona el generador con la configuración correspondiente a las mejoras. Se conservan el dinero ya recogido y no gastado y el progreso. Ver [seguimiento de cambios](plan-cambios-agarre-escoba.md).

### Noche

Una pantalla reúne el resumen y el taller por ramas; el árbol progresivo se abre desde el taller y su aceptación táctil sigue pendiente. El resumen muestra monedas recogidas, bolas introducidas, valor de monedas perdidas y récord diario. Si existe un día anterior, muestra la diferencia respecto a él.

La puntuación principal es el dinero recogido ese día, independientemente del saldo ahorrado. El saldo disponible para comprar es el ahorro anterior más el ingreso del día. Cada compra lo descuenta inmediatamente y sus efectos comienzan el siguiente día.

El jugador puede comprar varias mejoras o ahorrar. El botón «Comenzar día» permanece disponible aunque no compre nada.

## 4. Alcance del primer MVP

Objetivo: demostrar que el ciclo manual resulta agradable y que comprar mejoras cambia de forma perceptible el siguiente día. Debe ser una versión jugable con progresión persistente, no solo una demostración de física.

| Incluido | Alcance |
| --- | --- |
| Tablero | Una arena, un hoyo y un generador |
| Movimiento | Mano individual, escoba recta ampliable y escoba en V; un dedo, transporte y lanzamiento |
| Recompensa | Monedas visibles al introducir bolas; recogida por toque y arrastre desbloqueable |
| Ciclo | Día limitado, aviso de cierre, fin del día y noche sin temporizador |
| Resultados | Ingreso diario, bolas introducidas, monedas perdidas, récord y comparación anterior |
| Progresión | Once tipos y 23 nodos con descubrimiento progresivo, conexiones, zoom y compra de 3 s |
| Automatización | Un robot básico que empuja bolas y una mejora de imán para dinero |
| Persistencia | Guardado local del saldo, mejoras, número de día y resultados |
| Controles básicos | Pausa, silencio y explicación breve entregados; volumen independiente pendiente |
| Presentación | Primitivas y animación de monedas; arte/audio final y partículas pendientes |

### Catálogo y descubrimiento actuales

Una partida nueva muestra generador 1; comprar revela sucesores. Los nodos numéricos representan niveles individuales. Las dependencias deben entenderse antes de comprar; cada nodo muestra efecto actual, siguiente efecto, precio y requisito.

| Rama | Nodo | Efecto | Requisito actual |
| --- | --- | --- | --- |
| Control | Escoba recta | Desbloquea barrido de grupos | Nodo inicial |
| Control | Escoba más ancha | Abarca más bolas, también en V | Escoba recta |
| Control | Escoba en V | Reúne bolas hacia el centro | Anchura nivel 1 |
| Control | Recogida por barrido | Permite cobrar monedas al arrastrar por encima; antes solo por pulsación | Nodo inicial |
| Control | Radio de recogida | Recoge monedas desde más distancia | Nodo inicial |
| Control | Imán | Atrae y recoge automáticamente monedas dentro de un radio corto alrededor del dedo activo | Radio de recogida, nivel 1 |
| Producción | Generador más rápido | Reduce el intervalo entre bolas | Nodo inicial |
| Producción | Mayor recompensa | Aumenta el valor recibido por bola | Nodo inicial |
| Producción | Día más largo | Aumenta el tiempo de producción, con límite | Generador, nivel 1 |
| Automatización | Robot básico | Empuja bolas hacia el hoyo durante el día | Anchura, nivel 1 |
| Automatización | Velocidad del robot | Mejora su desplazamiento | Robot desbloqueado |

El catálogo contiene once tipos. El [árbol](arbol-de-mejoras.md) añade requisitos de descubrimiento a los de la tabla y conserva compras antiguas; la primera compra visible es generador 1, por 30 monedas. Mano inicial gratuita; escoba, V, barrido, imán y robot son desbloqueos únicos, las mejoras numéricas tienen tres niveles. Costes y efectos actuales están en [economía](economia.md) y [CSV](balance.csv). La aspiradora y otros métodos del [brainstorming](ideas-herramientas-bolas.md) no amplían automáticamente el alcance.

El robot no recoge monedas. El imán funciona alrededor del dedo apoyado y es independiente del barrido de monedas. Este último requiere compra desde el inicio, sin otros requisitos.

Los precios siguen provisionales. Con el día corto se producen tres bolas base y hasta seis monedas; no se alcanza una compra de veinte en el primer día. Queda redefinir el ritmo de primera compra y robot, en vez de mantener las hipótesis anteriores de compra inmediata y robot en 3–5 días. La duración total mejora a 20/25/30 s y el intervalo a 2,6/2,2/1,8 s.

Las mejoras de recompensa aumentan el valor representado por las monedas, sin multiplicar necesariamente su número físico.

### Qué no entra en el MVP

- Bolas de distintos materiales o rarezas y mejoras para generarlas.
- Robots especiales, varios robots simultáneos y robot recolector de dinero.
- Eventos periódicos, avalanchas y habilidades activables.
- Burbujas, segunda moneda y otros recursos de progresión.
- Prestigio, reinicios con bonificación y progresión sin conexión.
- Varios tableros, obstáculos, niveles y personalización estética.
- Cuentas, nube, clasificación en línea y multijugador.
- Anuncios, compras y otras formas de monetización.
- Árbol extenso, música elaborada y grandes cantidades de partículas.

Esta separación conserva el ciclo completo y una primera automatización. Las bolas mejores se aplazan para poder evaluar primero el efecto de generación y recompensa sin introducir otra variable económica.

## 5. Economía y comportamiento de objetos

- La unidad económica inicial es la moneda. Cada objeto visible puede representar un valor entero mayor que uno.
- El ingreso diario solo aumenta cuando se recoge una moneda. Cada moneda puede cobrarse una sola vez.
- Las monedas cercanas pueden fusionarse en una pila conservando exactamente su valor total y mostrando su importe. No se cobran automáticamente por acumularse.
- El generador espera si se alcanza el límite de bolas; no acumula una cola de aparición que se libere de golpe.
- Al finalizar el día se descartan todos los valores pendientes en el tablero.
- Una compra exige saldo suficiente y sus dependencias. No puede dejar saldo negativo.
- El récord registra el mayor ingreso de un día. La comparación diaria es informativa: no se promete que todos los días superen el anterior.

Antes de ajustar costes debe existir una tabla editable con intervalos de generación, valores de recompensa, precios, efectos y límites por nivel. Se evitarán cifras de balance dispersas en el código.

## 6. Propuesta técnica

Flutter para menús, resultados y árbol; Flame para el tablero, movimiento, colisiones y efectos. Esta opción está implementada; la aceptación de sensación y rendimiento en móvil sigue pendiente. No se incorporará un motor de física adicional hasta comprobar si el movimiento sencillo resulta insuficiente.

Organizar una única aplicación y paquete Dart en módulos funcionales: tablero, ciclo diario, economía, mejoras, automatización y progreso. Cada módulo controla su estado y expone contratos explícitos; las reglas usan Dart puro y no dependen de Flutter, Flame ni almacenamiento. La composición de la aplicación conecta los módulos y coordina compras y cierre sin duplicar recompensas. La estructura y sus límites se detallan en [Arquitectura y stack](arquitectura.md).

Preparar el crecimiento mediante catálogos de contenido, IDs estables y guardado migrable. No implementar funcionalidades futuras ni añadir frameworks, paquetes separados o abstracciones sin una necesidad concreta. El alcance sigue siendo el del MVP; la organización modular se aplica desde el primer prototipo.

### Muchos objetos y rendimiento

- Reutilizar bolas, monedas y partículas mediante pools cuando sea útil.
- Consultar vecinos mediante una partición espacial en vez de comparar todas las bolas entre sí.
- Limitar población de bolas, número de pilas y partículas simultáneas.
- Fusionar monedas cercanas antes de llegar al límite; si se alcanza, integrar nuevas recompensas en pilas existentes conservando su valor.
- Usar efectos visuales ligeros. Reducir partículas no debe cambiar ingresos ni reglas.
- Actualizar la elección de objetivos del robot a intervalos, no mediante una búsqueda completa en cada fotograma.
- Mantener los objetos del tablero dentro de Flame y evitar reconstruir widgets Flutter por cada objeto o movimiento.

Objetivo provisional: 60 FPS en un móvil de gama media acordado para las pruebas. El primer ensayo de estrés usará 200 bolas, 100 pilas de monedas y 150 partículas simultáneas, como carga de prueba y no como capacidad garantizada. Los límites finales se fijarán con mediciones en dispositivo real.

### Guardado e interrupciones

Se guardan localmente las compras y el cierre de cada día, además del estado necesario para reanudar una jornada interrumpida: tiempo restante, objetos y valores, ingresos y estado del robot. Al poner la aplicación en segundo plano se pausa la simulación y se toma una instantánea; al volver se ofrece continuar. No existe progreso mientras la aplicación está cerrada.

El cierre del día y su ingreso deben registrarse de forma consistente para impedir un cobro duplicado al reabrir la aplicación. El guardado tendrá versión de formato para permitir futuras migraciones. Las limitaciones ante un cierre abrupto deberán verificarse y documentarse en la implementación.

## 7. Entrega por partes

| Parte | Resultado revisable | Condición para continuar |
| --- | --- | --- |
| 1. Prototipo de interacción | Tablero, mano, escobas, bolas, hoyo y monedas | Empujar grupos y recoger resulta cómodo con un dedo; prueba inicial de carga |
| 2. Ciclo completo | Temporizador, cierre, noche, saldo y resultados | Ninguna moneda pendiente pasa al día siguiente y el ingreso se calcula una sola vez |
| 3. Progresión | Árbol, mejoras existentes y desbloqueo de barrido, robot e imán | Comprar cambia el siguiente día y las dependencias se entienden |
| 4. MVP verificable | Guardado, pausa, primera experiencia y ajuste de rendimiento/economía | Varias jornadas consecutivas funcionan sin bloquear la progresión ni perder el estado |

La primera entrega técnica es la parte 1; el primer MVP comprende las cuatro partes. No se comprometen fechas hasta validar interacción, plataformas y herramientas.

## 8. Criterios de aceptación del MVP

1. El jugador puede completar al menos diez ciclos consecutivos de día y noche, comprar mejoras y ahorrar sin bloqueos.
2. Una bola capturada produce su recompensa una sola vez y desaparece del tablero.
3. Al inicio solo pulsar recoge monedas; arrastrar solo las recoge tras comprar barrido. El toque sigue funcionando y cada valor se cobra una sola vez.
4. Al terminar el día, todas las bolas y monedas pendientes desaparecen al pasar a la noche. Las monedas no recogidas no se suman al saldo, las bolas retiradas no producen recompensa y cada día nuevo empieza sin bolas ni monedas.
5. El saldo sin gastar se conserva entre días y al reiniciar la aplicación.
6. Las mejoras existentes y el nuevo desbloqueo de barrido respetan los precios, dependencias y efectos que se definan; robot e imán funcionan durante el día.
7. Se valida jugando el ritmo de ahorro, primera compra y acceso al robot con el día corto; los precios se ajustarán tras esa revisión.
8. Pausar o salir a segundo plano detiene el temporizador y la simulación; reanudar no duplica ingresos.
9. La agrupación de monedas conserva su valor incluso al alcanzar el límite de objetos.
10. El tablero mantiene el objetivo de rendimiento en el dispositivo y carga acordados, incluidos los últimos segundos del día.

La validación combinará pruebas de economía y transiciones de estado con partidas manuales en móvil. La diversión, comodidad del gesto y claridad del árbol requieren observación de jugadores; no se dan por demostradas mediante pruebas automáticas.

## 9. Posibles ampliaciones

Prioridad orientativa después de validar el MVP:

1. Bolas mejores: materiales con distinta recompensa y probabilidades mejorables.
2. Robot recolector de dinero: automatización independiente con velocidad y alcance.
3. Robots especiales: activaciones vinculadas a cada día, con situaciones que justifiquen su utilidad.
4. Nuevos tableros y decisiones de especialización en el árbol.
5. Burbujas que salen del hoyo y se explotan para obtener otro recurso o mejoras, tras definir su función económica.
6. Prestigio y progreso sin conexión, únicamente si mejoran la experiencia a largo plazo.

## 10. Decisiones abiertas y recomendación

Android vertical y web de apoyo ya están configurados. iOS queda fuera de esta entrega; falta fijar un teléfono Android de referencia.

Validar agarre suave/fuerte, orientación y anchura de escobas, V, interferencia con monedas y el día inicial de 15 segundos. La limpieza nocturna y las migraciones cuentan con pruebas automáticas; falta aceptación física. El árbol progresivo ya está implementado; su aceptación táctil y el ajuste de precios siguen pendientes. Ver [estado actual](estado-actual.md) y [plan de cambios](plan-cambios-agarre-escoba.md).
