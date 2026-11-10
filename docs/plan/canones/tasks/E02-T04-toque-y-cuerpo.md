---
id: E02-T04
title: Toque prioritario y cuerpo sólido del cañón
epic: E02
status: todo
depends_on: [E02-T02]
requirements: [RF-05, RF-08, RF-09, RF-21, RF-22, RF-25, RF-26, RNF-01, RNF-05]
size: M
---

# E02-T04 · Toque prioritario y cuerpo sólido del cañón

## Objetivo

Tocar a ≤ 28 unidades del centro de un cañón activo durante la producción lo dispara, sin agarrar bolas, coger la escoba ni cobrar monedas. Las bolas libres rebotan en el cuerpo circular del cañón (radio 16).

## Contexto

- `Board.touch(Vec point, {double? time})` en `lib/features/board/domain/board.dart`: fija `paddle`, `target`, `_downPoint` y `_directionAnchor`, decide si se coge la escoba (`holdingBroom`) o se agarra una bola (`_manualBall`), y al final devuelve `sweepEnabled ? _collect(paddle!, paddle!) : 0`.
- `drag` cobra con `_collect` si `sweepEnabled`. `releasePointer` cobra por toque si `!_dragged && !_heldDuringGesture`.
- `GameSession.touch` (en `lib/app/game_session.dart`) llama a `board.touch` y suma lo cobrado. No hace falta cambiarlo.
- Con `coinOnly` (recogida) los cañones no responden y el toque sigue el flujo normal de monedas (RF-05).
- Física de subpasos en `update`: tras mover la bola y rebotar en paredes (`bounded`), se llama a `_collide()` y `_contactBroom`.
- Constantes: `Cannon.bodyRadius = 16`, `Cannon.touchRadius = 28` y `settings['wall_restitution']`.

## Archivos

- Modificar: `lib/features/board/domain/board.dart`
- Ampliar: `test/features/cannon_test.dart`
- No tocar: `game_session.dart` y la presentación

## Pasos

1. Añade el campo privado `bool _cannonGesture = false;`.
2. En `touch`, justo después de `_sample(paddle!, time ?? _clock);`:
   ```dart
   final cannon = coinOnly ? null : cannonAt(paddle!);
   if (cannon != null) {
     _cannonGesture = true;
     _heldDuringGesture = true; // release must not count as a coin tap
     fireCannon(cannon);
     return 0;
   }
   ```
3. En `drag`, al principio, tras `if (target == null) return 0;`: `if (_cannonGesture) { target = point.inside(0); return 0; }`.
4. En `releasePointer`, junto al resto de reinicios, añade `_cannonGesture = false;`. En `update`, la condición del imán `if (canCollectCoins && settings['magnet_radius'] > 0)` pasa a `if (!_cannonGesture && canCollectCoins && settings['magnet_radius'] > 0)`, para que mantener pulsado el cañón no atraiga ni cobre monedas.
5. En `update`, dentro del bucle de subpasos y del `for (final ball in balls)`, después de `ball.position = bounded;`, añade la resolución del obstáculo descrita en «Cambios de física» de `docs/plan/canones/02-architecture.md`:
   ```dart
   for (final cannon in cannons) {
     final d = ball.position - cannon.slot.position;
     final minDistance = Cannon.bodyRadius + radius;
     if (d.length >= minDistance) continue;
     final n = d.length < .0001
         ? Vec(math.cos(cannon.slot.baseAngle), math.sin(cannon.slot.baseAngle))
         : d.unit;
     ball.position = (cannon.slot.position + n * minDistance).inside(radius);
     final vn = ball.velocity.x * n.x + ball.velocity.y * n.y;
     if (vn < 0) {
       ball.velocity =
           ball.velocity - n * (vn * (1 + settings['wall_restitution']));
     }
   }
   ```
6. Pruebas en `test/features/cannon_test.dart`:
   - `touching the cannon fires instead of grabbing`: bola en reposo a 20 unidades del centro de G1 pero fuera de la boca. `board.touch(Vec(180, 60))` crea una bola nueva, `board.heldBalls` está vacío y `releasePointer()` devuelve 0.
   - `touching the cannon never collects coins`: con `coin_sweep` comprado y una moneda (`landing: 0`) en (180, 70), tocar G1 y arrastrar por encima de la moneda no la cobra.
   - `closing touch on the cannon collects coins normally`: tras `enterClosing()`, tocar sobre una moneda situada a 10 unidades de G1 la cobra y no crea ninguna bola.
   - `balls bounce off the cannon body`: bola en (180, 120) con velocidad (0, −300). Tras 30 pasos de 1/60, la distancia al centro de G1 es siempre ≥ 22 − 1e-6 (compruébalo en cada paso).
   - `fast shots stay inside the board and outside bodies at 30, 60 and 120 fps` (RNF-01): para cada `dt` en [1/30, 1/60, 1/120], dispara 50 veces (pon `cooldown = 0` entre disparos y avanza 0,2 s entre ellos). Tras cada paso, toda bola cumple `0 ≤ x ≤ 360`, `0 ≤ y ≤ 560` y distancia a G1 ≥ 22 − 0,5.
   - `fast ball does not knock a held ball out of the hand` (RF-09): agarra una bola en (180, 300) con `touch`. Lanza otra contra ella a 520 u/s. Tras 20 pasos, `board.heldBalls` sigue conteniendo la bola agarrada.

## Casos límite a cubrir

| Caso | Comportamiento esperado |
| --- | --- |
| Toque a 28 unidades exactas del centro | Dispara (≤) |
| Toque a 29 unidades sobre una bola | Agarra la bola |
| Arrastre que empieza en el cañón y pasa sobre bolas | No agarra ni cobra |

## Criterios de aceptación

- [ ] Las seis pruebas nuevas y la suite completa pasan.
- [ ] El bucle de obstáculo no crea listas ni mapas (RNF-05).

## Verificación

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Fuera de alcance

- Colisión del cañón con la escoba o el robot (RF-22: pasan por encima).
- Dibujo (E02-T05).

## Si te bloqueas

- Si `Ball` no permite crear una bola agarrada en la prueba de RF-09 sin tocarla, agárrala con `board.touch` sobre su posición y avanza un paso antes de lanzar la otra.
