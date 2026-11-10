# Visión · Generadores-cañón

## Problema

Ahora el generador fijo de arriba (`Board.generator`, en (180, 60)) suelta una bola cada ⅔ s casi sin velocidad. Las bolas caen siempre en la misma zona y el jugador hace siempre el mismo recorrido: coger, llevar al hoyo y cobrar. El tablero se siente estático y las mejoras de producción («Generador rápido», «Doble emisión») solo suben un número.

## Qué cambia

El generador se convierte en un **cañón**: oscila de lado a lado en un arco y dispara las bolas con fuerza. Las bolas salen repartidas por el tablero de forma algo aleatoria y rebotan en las paredes. Al principio el jugador **toca el cañón** para disparar. Con mejoras, el cañón **dispara solo** y su **puntería** se estrecha. Se pueden **comprar hasta tres cañones más**, en huecos fijos, cada uno con sus propias mejoras. Recoger y llevar bolas al hoyo sigue existiendo: el jugador reparte su atención entre disparar, recoger y cobrar.

## Usuarios y roles

| Rol | Quién es | Qué necesita |
| --- | --- | --- |
| Jugador | El propio desarrollador probando en Android y web | Un tablero dinámico, con decisiones sobre dónde mirar y qué automatizar |
| Agente ejecutor | Agente que implementa las tareas de `tasks/` | Tareas cerradas, sin decisiones abiertas |

## Objetivos

- O1: Las bolas entran en juego disparadas desde cañones que oscilan, no soltadas en un punto fijo.
- O2: La producción progresa de manual a automática mediante el árbol, sin quitar del todo la aleatoriedad del destino de cada bola.
- O3: El jugador puede ampliar a cuatro cañones con mejoras independientes.
- O4: Cinco PR revisables por separado. El APK se genera una sola vez, al final, sobre `main`.

## No-objetivos

- Bolas duplicadora y bomba, aspiradora y demás ideas de `docs/ideas-herramientas-bolas.md`.
- Colocar o mover cañones a mano: los huecos son fijos.
- Migrar partidas guardadas: el progreso se reinicia (no hay jugadores reales).
- Audio nuevo o partículas.
- Ajuste final de precios jugando en Android físico: los precios del plan son provisionales.

## Métricas de éxito

- Las 116 pruebas actuales (o sus sustitutas cuando el comportamiento cambia) y las nuevas pasan en cada PR.
- Con juego perfecto, la primera compra (Mano I, 13 monedas) se alcanza en dos jornadas (ver E05-T01).
- APK 0.6.0+11 generado por la pipeline manual sobre `main` y enlazado en `README.md`.

## Restricciones

- Flutter 3.35.7, Dart 3.9.2 y Flame 1.35.1, sin dependencias nuevas.
- Física propia en `lib/features/board/domain/board.dart`. Se amplía, no se sustituye.
- Valores de juego en `docs/balance.csv`.
- Código y comentarios nuevos en inglés. Documentación y textos de UI en español.

## Glosario

| Término | Definición |
| --- | --- |
| Cañón | Generador que oscila y dispara bolas. Sustituye al generador actual. Clase `Cannon`. |
| Hueco | Posición fija del tablero donde puede existir un cañón. Hay 4, numerados del 1 al 4 (G1–G4). |
| Arco | Ángulo total, en grados, que recorre el cañón al oscilar, centrado en su dirección base. |
| Periodo de barrido | Tiempo de un ciclo completo de ida y vuelta del cañón (2 s). |
| Recarga | Tiempo mínimo entre dos disparos del mismo cañón. |
| Automático | Estado de un cañón que dispara solo cada «intervalo automático». |
| Boca | Punto de salida de la bola, a 24 unidades del centro del cañón en la dirección de apuntado. |
| Velocidad de captura | Velocidad máxima con la que una bola libre puede caer en el hoyo. |
