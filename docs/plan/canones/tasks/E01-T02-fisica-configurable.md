---
id: E01-T02
title: Física configurable y captura por velocidad
epic: E01
status: todo
depends_on: [E01-T01]
requirements: [RF-06, RF-07]
size: M
---

# E01-T02 · Física configurable y captura por velocidad

## Objetivo

La velocidad máxima de las bolas libres, el rebote en paredes y la velocidad máxima de captura del hoyo se leen de `docs/balance.csv`. Una bola libre solo cae al hoyo si va a ≤ 140 u/s.

## Contexto

- Física en `lib/features/board/domain/board.dart`, método `update`. Integración por subpasos (240 Hz): `ball.velocity = ball.velocity.limit(380) * friction`, rebote con `* .4` en X e Y y captura en `balls.removeWhere` solo por distancia (`settings['hole_capture_radius']`, 22).
- `_collide()` limita las velocidades a 380 en cuatro sitios.
- La mano (`_releaseVelocity`, `releasePointer` y `_moveTool`), la escoba (`_contactBroom`) y el robot (`_push`) también usan 380. **Esos no cambian**: son límites de herramienta.
- `_heldBalls` contiene las bolas agarradas por la mano.
- Valores decididos: `max_ball_speed` 600, `wall_restitution` 0,55 y `hole_capture_speed` 140 (ADR-02).
- `UpgradeCatalog.fromCsv` exige una lista fija de bases. Las nuevas deben añadirse a esa lista.

## Archivos

- Modificar: `docs/balance.csv`, `lib/features/upgrades/domain/catalog.dart`, `lib/features/board/domain/board.dart`
- Crear: `test/features/physics_test.dart`
- No tocar: herramientas (mano, escoba y robot), salvo lo indicado

## Pasos

1. En `docs/balance.csv`, inserta justo después de la fila `base,balls_per_spawn,…`:
   ```
   base,max_ball_speed,0,0,max_ball_speed,600,logical_units_per_second,,
   base,wall_restitution,0,0,wall_restitution,0.55,ratio,,
   base,hole_capture_speed,0,0,hole_capture_speed,140,logical_units_per_second,,
   ```
2. En `catalog.dart`, añade `'max_ball_speed'`, `'wall_restitution'` y `'hole_capture_speed'` a la lista de bases obligatorias de `fromCsv`.
3. En `board.dart`, dentro de `update`:
   1. En el bucle de subpasos, sustituye `ball.velocity.limit(380)` por `ball.velocity.limit(settings['max_ball_speed'])`.
   2. Sustituye los dos `* .4` del rebote por `* settings['wall_restitution']`.
   3. En `balls.removeWhere`, la condición pasa a:
      ```dart
      if ((ball.position - hole).length > settings['hole_capture_radius']) return false;
      if (!_heldBalls.containsKey(ball) &&
          ball.velocity.length > settings['hole_capture_speed']) {
        return false;
      }
      ```
      Mantén el resto del cuerpo (limpiar `_heldBalls`, `_manualBall`, `_slippedBalls` y los contadores).
4. En `_collide()`, sustituye los cuatro `.limit(380)` por `.limit(settings['max_ball_speed'])`.
5. Crea `test/features/physics_test.dart` con estas pruebas (usa `testCatalog().settings({})` y `Board(settings)`, y crea las bolas con `board.balls.add(Ball(board.nextId++, pos, vel))`):
   - `fast free ball crosses the hole without being captured`: bola en `Board.hole - Vec(40, 0)` con velocidad `Vec(400, 0)`. Tras 10 pasos de `board.update(1 / 60, producing: false)`, `board.captured == 0`.
   - `slow free ball inside the hole is captured`: bola en `Board.hole` con `Vec.zero`. Tras un paso, `board.captured == 1`.
   - `wall bounce keeps configured restitution`: bola en `Vec(354, 300)` con `Vec(500, 0)`. Tras un paso de `1 / 240`, `velocity.x` está en `-500 * 0.55 * friction ± 2`, donde `friction = math.exp(-1.6 / 240)`.
   - `free ball speed is capped at max_ball_speed`: bola con `Vec(900, 0)` en `Vec(100, 300)`. Tras un paso, `velocity.length <= 600`.

## Casos límite a cubrir

| Caso | Comportamiento esperado |
| --- | --- |
| Bola agarrada movida rápido sobre el hoyo | Se captura por posición, como ahora |
| Bola libre a exactamente 140 u/s dentro del radio | Se captura (≤) |
| Pruebas existentes que lanzan bolas al hoyo con la mano a > 140 u/s | Si alguna falla, ajusta la prueba para que la bola llegue en reposo o agarrada. No cambies el umbral. |

## Criterios de aceptación

- [ ] Las cuatro pruebas nuevas pasan.
- [ ] `grep -n "limit(380)" lib/features/board/domain/board.dart` solo aparece en `releasePointer`, `_releaseVelocity`, `_moveTool`, `_contactBroom` y `_push`.
- [ ] Todas las pruebas existentes pasan.

## Verificación

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Fuera de alcance

- Cañón y obstáculos (E02).
- Cambiar rozamiento (`-1.6`) o atracción del hoyo (`220`).

## Si te bloqueas

- Si más de tres pruebas existentes fallan por la captura por velocidad, para y anota sus nombres en una sección «Bloqueo»: podría indicar que la atracción del hoyo no frena como se espera.
