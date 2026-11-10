---
id: E02-T02
title: Integrar G1 en Board y sustituir el generador
epic: E02
status: todo
depends_on: [E02-T01]
requirements: [RF-02, RF-03, RF-04, RF-05, RF-17, RF-24, RF-27, RNF-02]
size: L
---

# E02-T02 · Integrar G1 en `Board` y sustituir el generador

## Objetivo

`Board` ya no emite bolas por intervalo. Las bolas solo nacen al llamar a `fireCannon(board.cannons.first)` durante la producción. El estado del cañón se guarda y se restaura.

Es tamaño L porque la emisión automática desaparece y varias pruebas existentes dependen de ella. Se adaptan en esta misma tarea para que la suite siga en verde.

## Contexto

- `Board.update` (en `lib/features/board/domain/board.dart`) tiene un bloque `if (producing && !coinOnly) { spawnClock += dt; /* emisión */ }` que crea bolas cerca de `Board.generator` (180, 60). Ese bloque se sustituye.
- La clase `Cannon` existe en `lib/features/board/domain/cannon.dart` (E02-T01).
- Contrato completo en `docs/plan/canones/02-architecture.md`, sección «API de `Board`». Resumen:
  - `final List<Cannon> cannons` y `double cannonClock = 0`.
  - `cannonAngle(c)` con `settings['g${c.slot.index}_arc']` y `settings['cannon_sweep_period']`.
  - `cannonAutomatic(c)` → `settings['g${c.slot.index}_automatic'] > 0` (en este epic siempre `false`).
  - `fireCannon(c)` es manual: devuelve `false` si `coinOnly`, si `c.cooldown > 0` o si `_shoot` falla.
  - `_shoot(c)`: bloqueo por `ball_limit` o por una bola a menos de `radius * 2.2` de la boca. Bola nueva con velocidad `dir * settings['cannon_shot_speed']` y `golden: random() < .01`. Después, recarga, `autoClock = 0` y `recoil`.
- `fireCannon` no comprueba `producing`: la sesión solo deja tocar durante la jornada, y durante la recogida `coinOnly` es `true`. En la noche no hay tablero activo.
- Guardado: `toJson` sustituye `'spawnClock'` por `'cannonClock'` y `'cannons'`. `fromJson` valida según «Guardado (versión 6)» de la arquitectura.

## Archivos

- Modificar: `docs/balance.csv`, `lib/features/upgrades/domain/catalog.dart`, `lib/features/board/domain/board.dart`
- Modificar pruebas que dependan de la emisión automática (búscalas con `grep -rln "spawnClock\|spawn_interval\|balls_per_spawn" test`, y también las que fallen al ejecutar la suite): entre ellas `test/features/golden_ball_test.dart`, `test/features/balance_test.dart` y `test/features/game_rules_test.dart`
- Ampliar: `test/features/cannon_test.dart`
- Modificar (solo una línea): `lib/features/board/presentation/garden_game.dart`: `final generator = offset(Board.generator);` pasa a `final generator = offset(board.cannons.first.slot.position);`. Ningún otro cambio visual: el dibujo nuevo lo hace E02-T05.
- No tocar: `game_app.dart` y `skill_tree.dart`

## Pasos

1. En `docs/balance.csv`, añade tras la fila que empieza por `base,hole_capture_speed,`:
   ```
   base,cannon_cooldown,0,0,cannon_cooldown,1,seconds,,
   base,cannon_sweep_period,0,0,cannon_sweep_period,2,seconds,,
   base,cannon_shot_speed,0,0,cannon_shot_speed,520,logical_units_per_second,,
   base,g1_arc,0,0,g1_arc,150,degrees,,
   ```
   No borres todavía `spawn_interval` ni `balls_per_spawn` (lo hace E02-T03).
2. En `catalog.dart`, añade esas cuatro claves a la lista de bases obligatorias.
3. En `board.dart`:
   1. Importa `cannon.dart`.
   2. Añade `final cannons = <Cannon>[];` y `double cannonClock = 0;`. En el constructor: `cannons.add(Cannon(cannonSlots[0]));`.
   3. Elimina `static const generator`, el campo `spawnClock` y cada uno de sus usos.
   4. Añade `cannonAngle`, `cannonAutomatic`, `fireCannon`, `_shoot` y `cannonAt(Vec point)` (cañón más cercano a ≤ `Cannon.touchRadius`, o `null`), tal como están en la arquitectura.
   5. En `update`, sustituye el bloque de emisión por el bucle de cañones de la arquitectura (sección «API de `Board`»). Como `cannonAutomatic` es `false`, el bucle solo avanza `cannonClock` y `tick`.
   6. `toJson`: quita `'spawnClock'` y añade `'cannonClock': cannonClock` y `'cannons': [for (final c in cannons) c.toJson()]`.
   7. `fromJson`: quita la lectura y la validación de `spawnClock`. Lee `cannonClock` (`num`, finito y ≥ 0). Lee `cannons` como `List` cuya longitud debe ser igual a `board.cannons.length` y sustituye cada `board.cannons[i]` por `Cannon.fromJson(board.cannons[i].slot, row)`. Si algún `cooldown` es > `settings['cannon_cooldown']`, lanza `FormatException('Tablero guardado inválido')`.
4. Adapta las pruebas que fallen porque ya no aparecen bolas solas:
   - Si la prueba necesita bolas en una posición concreta, créalas con `board.balls.add(Ball(board.nextId++, Vec(x, y), Vec.zero))`.
   - Si la prueba mide la emisión (p. ej. `golden chance is one percent per successfully emitted ball` en `golden_ball_test.dart`), sustitúyela por disparos: repite `board.cannons.first.cooldown = 0; board.fireCannon(board.cannons.first); board.balls.clear();` N veces y comprueba la misma proporción dorada.
   - Las pruebas de cadencia de `balance_test.dart` sobre `spawn_interval` se borran. La de «initial day lasts 13 seconds including three for collection» se conserva.
   - No borres pruebas de otras reglas. Si una no se puede adaptar, anótalo en «Notas de implementación».
5. Amplía `test/features/cannon_test.dart` con pruebas de `Board`:
   - `manual shots respect cooldown`: toques a t = 0 y t = 0,5 dan 1 bola, y a t = 0 y t = 1,0 dan 2. Avanza con `board.update(1 / 60, producing: true)`.
   - `shot leaves from the muzzle at shot speed`: la bola nueva está a 24 unidades de (180, 60) y `velocity.length` = 520 ± 0,001.
   - `blocked muzzle keeps cooldown and flashes`: pon una bola en la boca calculada, `fireCannon` devuelve `false`, `cooldown == 0`, `blockedFlash > 0` y no se crea ninguna bola nueva.
   - `ball limit blocks shooting`: con `ball_limit` bolas en el tablero, `fireCannon` devuelve `false`.
   - `closing freezes the cannon`: tras `enterClosing()`, `fireCannon` devuelve `false` y `cannonClock` no cambia tras `update`.
   - `same seed and taps give identical shots` (RNF-02): dos tableros con `randomState: 7`, mismos toques y pasos, y mismas posiciones y velocidades.
   - `cannon state survives save and restore`: dispara, avanza 0,4 s, `Board.fromJson(settings, board.toJson())` conserva `cannonClock` y `cooldown` (±1e-9).

## Casos límite a cubrir

| Caso | Comportamiento esperado |
| --- | --- |
| `cannons` guardado con longitud distinta | `FormatException` |
| `cooldown` guardado mayor que 1 | `FormatException` |
| Producción termina con la recarga a 0,4 | La recarga se mantiene en 0,4 hasta el final del día (sin `tick`) |

## Criterios de aceptación

- [ ] `grep -rn "spawnClock\|Board.generator" lib test` no devuelve nada.
- [ ] Las siete pruebas nuevas pasan y la suite completa está en verde.
- [ ] Sin toques, una jornada completa de 13 s no crea ninguna bola.

## Verificación

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Fuera de alcance

- Tocar el cañón desde la pantalla, obstáculo y dibujo (E02-T04/T05).
- Borrar `spawn_interval` y `balls_per_spawn` del CSV (E02-T03).

## Si te bloqueas

- Si alguna otra parte de `lib/` usa `Board.generator` o `spawnClock`, para y lista los usos en una sección «Bloqueo».
