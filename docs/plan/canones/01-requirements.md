# Requisitos · Generadores-cañón

## Flujos

### Flujo 1: primera jornada con cañón manual

1. El jugador pulsa «Comenzar día». El cañón G1, arriba en el centro, oscila en un arco de 150° apuntando hacia abajo.
2. El texto de ayuda dice «Toca el cañón para disparar bolas».
3. El jugador toca el cañón. Sale una bola desde la boca en la dirección actual, a 520 u/s, y el cañón muestra la recarga de 1 s.
4. La bola rebota en paredes y otras bolas. Si pasa rápida por el hoyo, no cae. Si llega despacio, cae y genera monedas.
5. El jugador alterna entre disparar, llevar bolas al hoyo con la mano y pulsar monedas.
6. Al acabar la producción, el cañón se congela y deja de responder. Durante la recogida, los toques solo cobran monedas.

### Flujo 2: automatizar G1

1. En el árbol, el jugador compra «Cañón 1 · Automático».
2. En la jornada siguiente, G1 dispara solo cada 1,5 s y muestra un indicador de automático.
3. Si el jugador toca G1 con la recarga lista, dispara al momento y reinicia el reloj del automático.

### Flujo 3: añadir cañones

1. Después de comprar «Cañón 1 · Automático», el jugador puede comprar «Cañón 2». Aparece en el lateral izquierdo, en (20, 150), apuntando a la derecha. Llega manual y con 150° de arco.
2. Cañón 3, en el lateral derecho (340, 150), se compra tras Cañón 2. Cañón 4, abajo en el centro (180, 540), tras Cañón 3.
3. Cada cañón tiene sus ramas propias de Automático, Velocidad automática y Puntería.

Estados visuales del cañón: listo (cuerpo verde con brillo), recargando (anillo de progreso), bloqueado (gris durante 0,3 s), automático (anillo exterior ámbar) y congelado (oscurecido en la recogida).

## Requisitos funcionales

| ID | Requisito | Prioridad | Criterio de aceptación |
| --- | --- | --- | --- |
| RF-01 | Cada cañón oscila a velocidad angular constante en un arco centrado en su dirección base. El ciclo de ida y vuelta dura `cannon_sweep_period` (2 s). | Must | Test: con arco 150° y periodo 2, el ángulo a t=0 es base−75°, a t=0,5 es base, a t=1 es base+75° y a t=2 vuelve a base−75°. |
| RF-02 | Tocar un cañón activo durante la producción dispara una bola si su recarga es 0. Tras disparar, la recarga vale `cannon_cooldown` (1 s). | Must | Test: dos toques separados 0,5 s producen 1 bola; separados 1 s producen 2. |
| RF-03 | La bola sale desde la boca, en la dirección actual, a `cannon_shot_speed` (520 u/s). Tiene un 1 % de probabilidad de ser dorada. | Must | Test: la velocidad de la bola nueva mide 520 ± 0,001 y apunta al ángulo del cañón. La prueba de probabilidad dorada sigue pasando con disparos. |
| RF-04 | Si hay `ball_limit` bolas o hay una bola a menos de 13,2 unidades de la boca, el cañón no dispara, no consume recarga y se muestra bloqueado 0,3 s. | Must | Test: con la boca tapada, `fireCannon` devuelve `false`, la recarga sigue en 0 y no se crea ninguna bola. |
| RF-05 | Los cañones solo disparan y oscilan durante la producción. En la recogida, la pausa y la noche no hacen nada. Un toque sobre un cañón durante la recogida se trata como toque de recogida de monedas. | Must | Test: tras `enterClosing`, `fireCannon` devuelve `false` y el ángulo no cambia. |
| RF-06 | Una bola libre solo cae en el hoyo si su velocidad es ≤ `hole_capture_speed` (140 u/s). Las bolas agarradas por la mano caen solo por posición, como hoy. | Must | Test: una bola a 400 u/s que cruza el centro del hoyo no se captura. Una bola en reposo dentro del radio sí. Una bola agarrada se captura al soltarla encima aunque se mueva rápido. |
| RF-07 | La velocidad máxima de las bolas libres es `max_ball_speed` (600 u/s). El rebote en las paredes conserva `wall_restitution` (0,55) de la componente normal. | Must | Test: una bola que choca con la pared a 500 u/s sale a 275 u/s en la componente normal. |
| RF-08 | El cuerpo de cada cañón activo es un obstáculo circular de radio 16. Las bolas libres rebotan en él con `wall_restitution`. | Must | Test: una bola lanzada contra el cuerpo no queda a menos de 16 + radio de bola de su centro. |
| RF-09 | Una bola rápida empuja a las bolas libres con las colisiones actuales. No suelta las bolas agarradas por la mano. | Must | Test: una bola a 520 u/s contra una bola agarrada no la saca de la mano. |
| RF-10 | La mejora «Automático» de un cañón le hace disparar cada `gN_auto_interval` segundos. La recarga se comparte: un disparo manual reinicia el reloj automático y un disparo automático pone la recarga a `min(cannon_cooldown, gN_auto_interval)`. | Must | Test: en automático, 3 s de producción sin toques producen 2 disparos con intervalo 1,5. Un toque a t=1 hace que el siguiente disparo automático sea a t=2,5. |
| RF-11 | Las mejoras «Velocidad automática» reducen `gN_auto_interval` según `balance.csv`. | Must | Test de catálogo: los niveles de G1 dan 1,3 / 1,1 / 0,95 / 0,8. |
| RF-12 | Las mejoras «Puntería» reducen el arco `gN_arc` según `balance.csv`. El arco afecta también al disparo automático. | Must | Test de catálogo: los niveles de G1 dan 135 / 120 / 110 / 100 / 90. |
| RF-13 | Hay cuatro huecos fijos: G1 (180, 60) a 90°, G2 (20, 150) a 0°, G3 (340, 150) a 180° y G4 (180, 540) a 270°. G1 existe siempre. G2–G4 se compran en orden y llegan manuales con arco de 150°. | Must | Test: sin compras, el tablero tiene 1 cañón. Con `g2_unlock:1`, tiene 2, con el segundo en (20, 150). |
| RF-14 | Cada cañón tiene mejoras propias, sin efectos globales. | Must | Test: comprar `g1_aim:1` no cambia `g2_arc`. |
| RF-15 | Se eliminan «Generador rápido» (`generator`) y «Doble emisión» (`double_spawn`), con sus filas y las bases `spawn_interval` y `balls_per_spawn`. «Día más largo» pasa a requerir `g1_auto_speed:1` (con `reward:2` como requisito temporal entre E02-T03 y E03-T02). | Must | Test: el catálogo no contiene esos IDs y `duration:1` requiere `g1_auto_speed:1` (tras E03-T02). |
| RF-16 | El guardado pasa a versión 6. Las partidas guardadas con versiones 1–5 se ignoran sin aviso y la partida empieza de cero. Se borra todo el código de migración y los balances congelados. | Must | Test: cargar un JSON con `"version": 5` deja día 1, saldo 0, sin mejoras y `recoveryMessage == null`. |
| RF-17 | Una jornada interrumpida guarda y restaura el reloj de barrido y, por cañón, su recarga y su reloj automático. | Must | Test: guardar a mitad de recarga, restaurar y comprobar que ángulo y recarga coinciden. |
| RF-18 | El tablero dibuja cada cañón activo: base, cañón rotado al ángulo actual, guías tenues en los extremos del arco, anillo de recarga, gris al bloquearse, anillo ámbar si es automático y retroceso de 0,12 s al disparar. Se quita el rótulo «GENERADOR». | Must | Test de widget o render: no aparece el texto `GENERADOR`. Revisión visual en web. |
| RF-19 | Textos de ayuda: si la jornada no ha generado dinero y no hay bolas, «Toca el cañón para disparar bolas». La pantalla de inicio dice «Dispara con el cañón, lleva las bolas al hoyo y recoge sus monedas.» | Must | Test de widget que encuentra ambos textos. |
| RF-20 | El árbol incluye las ramas G1–G4 en las posiciones de `02-architecture.md`, con segmentos en ocho direcciones y sin solapes, en un lienzo de 864 × 1120. | Must | Las pruebas existentes de geometría del árbol pasan con los nodos nuevos. |

## Reglas de negocio

- RF-21: Tocar un cañón tiene prioridad sobre agarrar una bola, coger la escoba o cobrar monedas si el toque cae a ≤ 28 unidades del centro de un cañón activo y la jornada está en producción. Ese gesto no cobra monedas al soltar ni al arrastrar.
- RF-22: Las monedas no colisionan con las bolas, la escoba ni el robot. El cuerpo del cañón no afecta a la escoba ni al robot, que pasan por encima.

## Casos límite

| ID | Situación | Comportamiento |
| --- | --- | --- |
| RF-23 | El automático toca disparar con la boca tapada | No dispara, mantiene el reloj automático y reintenta en cada paso hasta poder disparar. Se muestra bloqueado. |
| RF-24 | La producción termina con la recarga a medias | La recarga se congela. El día siguiente crea cañones nuevos con recarga 0. |
| RF-25 | Se toca el cañón llevando bolas en la mano | No ocurre: el tablero usa un único puntero y el toque inicial ya fijó el gesto. Arrastrar la mano por encima de un cañón no dispara. |
| RF-26 | Hay una bola en reposo dentro del radio de toque de un cañón | El toque dispara (prioridad del cañón). Para coger esa bola hay que tocarla a más de 28 unidades del centro del cañón. El obstáculo del cuerpo impide que quede a menos de 22. |
| RF-27 | Una bola recién disparada nace dentro de otra bola cercana | No ocurre: la comprobación de boca de RF-04 lo impide. |
| RF-28 | El reloj automático es menor que la recarga manual (nivel 0,8 s) | La recarga tras cualquier disparo es `min(1, 0,8) = 0,8`: el automático no queda limitado por la recarga manual. |

## Requisitos no funcionales

| ID | Categoría | Requisito | Cómo se verifica |
| --- | --- | --- | --- |
| RNF-01 | Estabilidad física | A 600 u/s ninguna bola atraviesa un cañón ni sale del tablero, a 30, 60 y 120 FPS simulados. | Test que dispara 50 bolas con cada paso de tiempo y comprueba posiciones dentro de límites y fuera de los cuerpos. |
| RNF-02 | Determinismo | Con la misma semilla (`randomState`) y la misma secuencia de toques, los disparos son idénticos. | Test que compara dos tableros. |
| RNF-03 | Calidad | `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze` y `flutter test` pasan en cada PR. | Ejecución local o pipeline manual. |
| RNF-04 | Configurabilidad | Todo valor de juego nuevo (velocidades, tiempos, arcos, precios) vive en `docs/balance.csv`. Solo la geometría de huecos y los radios del cuerpo, la boca y el toque son constantes en `cannon.dart`. | Revisión de código: `grep -n "520\|1.5\|150" lib/features/board/domain/cannon.dart` no da valores de balance. |
| RNF-05 | Rendimiento | Cuatro cañones automáticos con 200 bolas no añaden asignaciones por subpaso además de las bolas creadas. | Revisión de código del bucle de `Board.update`: sin listas nuevas dentro del bucle de subpasos. |
