---
id: E02-T05
title: Dibujo del cañón y textos de ayuda
epic: E02
status: todo
depends_on: [E02-T04]
requirements: [RF-18, RF-19]
size: M
---

# E02-T05 · Dibujo del cañón y textos de ayuda

## Objetivo

El tablero dibuja cada cañón de `board.cannons` girado a su ángulo actual, con guías de arco, recarga, bloqueo y retroceso. Desaparece el bloque y el rótulo «GENERADOR». Los textos de ayuda explican que hay que tocar el cañón.

## Contexto

- `GardenGame.render` (en `lib/features/board/presentation/garden_game.dart`) dibuja ahora el generador antiguo con cuatro `drawRRect`, a partir de `final generator = offset(…)`, más un `label(canvas, 'GENERADOR', …)`. Ese bloque se sustituye entero.
- Helpers disponibles en `GardenGame`: `paint(Color, {double? stroke})`, `offset(Vec)` y `label(…)`. El canvas ya está escalado a coordenadas lógicas del tablero.
- En `Board`: `cannons`, `cannonAngle(c)`, `cannonAutomatic(c)`, `settings['g${n}_arc']`, `settings['cannon_cooldown']`, `c.cooldown`, `c.blockedFlash`, `c.recoil`, `Cannon.bodyRadius` (16) y `Cannon.recoilSeconds` (0,12).
- Durante la recogida hay una capa oscura que se dibuja antes que las monedas. Los cañones deben dibujarse **antes** de esa capa para quedar oscurecidos. Hoy el generador ya se dibuja antes y basta con mantener el orden.
- Textos en `lib/app/game_app.dart`: el texto de ayuda de la jornada (cadena condicional que termina en `'Agarra una bola y llévala al hoyo'`) y el texto de inicio `'Agarra una bola, llévala al hoyo y recoge sus monedas.'`.
- Paleta existente: verde `0xff247d73`, azul oscuro `0xff172333`, gris `0xff697583` y sombra `0x30644c2d`.

## Archivos

- Modificar: `lib/features/board/presentation/garden_game.dart`, `lib/app/game_app.dart`
- Modificar pruebas: `test/widget_test.dart`
- No tocar: el dominio (`board.dart` y `cannon.dart`)

## Pasos

1. En `garden_game.dart`, sustituye el bloque del generador antiguo (desde `final generator = offset(…)` hasta el `label(… 'GENERADOR' …)` incluido) por un bucle `for (final cannon in board.cannons) _drawCannon(canvas, board, cannon);`.
2. Añade el método `void _drawCannon(Canvas canvas, Board board, Cannon cannon)`, que dibuja en este orden:
   1. Guías de arco: dos líneas desde el centro, de longitud 40, en `slot.baseAngle ± arc/2` (con `arc = settings['g${n}_arc'] * pi / 180`). `paint(const Color(0x30247d73), stroke: 1.5)`.
   2. Sombra: círculo de radio 18 desplazado (0, 3) con `0x30644c2d`.
   3. Cañón (rectángulo redondeado de 26 × 10, radio 4) girado a `cannonAngle(cannon)`: `canvas.save()`, `translate(centro)`, `rotate(angle)` y `drawRRect` con el centro del rectángulo en `(13 - retroceso, 0)`, donde `retroceso = 4 * cannon.recoil / Cannon.recoilSeconds`. Después, `restore()`. Color `0xff172333`, o `0xff697583` si `cannon.blockedFlash > 0`.
   4. Cuerpo: círculo de radio 16. Color `0xff247d73`, o `0xff697583` si `blockedFlash > 0`.
   5. Recarga: si `cannon.cooldown > 0`, un arco (`drawArc`) de radio 20 que empieza en −π/2 y barre `2π * (1 - cooldown / settings['cannon_cooldown'])`, con `paint(const Color(0xffd8e2dc), stroke: 3)`.
   6. Automático: si `board.cannonAutomatic(cannon)`, un círculo de radio 23 con `paint(const Color(0xffe0a040), stroke: 2)`.
3. Importa `../domain/cannon.dart` en `garden_game.dart`.
4. En `game_app.dart`, en el texto de ayuda de la jornada, añade antes de la rama `session.economy.generated > 0` esta condición: `session.economy.generated == 0 && session.board!.balls.isEmpty ? 'Toca el cañón para disparar bolas' : …`. Las ramas existentes se mantienen tras ella en el mismo orden.
5. En `game_app.dart`, cambia el texto de inicio por `'Dispara con el cañón, lleva las bolas al hoyo y recoge sus monedas.'`.
6. En `test/widget_test.dart`, añade:
   - `first hint tells the player to tap the cannon`: al comenzar el día aparece `Toca el cañón para disparar bolas` y no aparece `GENERADOR`.
   - `intro text mentions the cannon`: con sesión nueva aparece `Dispara con el cañón, lleva las bolas al hoyo y recoge sus monedas.`.
   - Actualiza las pruebas que buscaban el texto de inicio antiguo.

## Criterios de aceptación

- [ ] `grep -rn "GENERADOR" lib` no devuelve nada.
- [ ] Pruebas de widget nuevas y suite completa en verde.
- [ ] Revisión visual en `flutter run -d chrome`: el cañón gira, retrocede al disparar, muestra el anillo de recarga y se pone gris al taparle la boca con una bola.

## Verificación

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --no-web-resources-cdn
```

Manual: `python3 -m http.server 8123 --directory build/web`, abrir `http://localhost:8123`, comenzar el día y tocar el cañón varias veces.

## Fuera de alcance

- Sonido al disparar.
- Indicadores en el árbol (E03-T02).

## Si te bloqueas

- Si el orden de dibujo hace que la capa de recogida no oscurezca el cañón, mueve solo el bucle de cañones para que quede antes de la capa y anótalo.
