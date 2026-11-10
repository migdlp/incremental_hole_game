---
id: E04-T01
title: Tablero con cuatro huecos
epic: E04
status: done
depends_on: [E03-T02]
requirements: [RF-13, RF-14]
size: M
---

# E04-T01 · Tablero con cuatro huecos

## Objetivo

`Board` crea G2, G3 y G4 cuando `settings['g2_enabled']`, `settings['g3_enabled']` y `settings['g4_enabled']` son > 0, respectivamente. Cada uno usa sus propias claves `gN_arc`, `gN_automatic` y `gN_auto_interval`.

## Contexto

- `cannonSlots` (en `lib/features/board/domain/cannon.dart`) ya define los cuatro huecos: G2 (20, 150) a 0 rad, G3 (340, 150) a π y G4 (180, 540) a −π/2.
- El constructor de `Board` (en `lib/features/board/domain/board.dart`) hoy solo hace `cannons.add(Cannon(cannonSlots[0]))`. `cannonAngle`, `cannonAutomatic` y `_shoot` ya leen las claves con `g${c.slot.index}_…`.
- `toJson`/`fromJson` guardan la lista `cannons` en orden de hueco y exigen la misma longitud que `board.cannons`.
- Las bases `g2_arc`–`g4_auto_interval` no existen todavía en el CSV. Esta tarea las añade.
- Las claves `gN_enabled` y `gN_automatic` no tienen base (valen 0 hasta comprar).

## Archivos

- Modificar: `docs/balance.csv`, `lib/features/upgrades/domain/catalog.dart`, `lib/features/board/domain/board.dart`
- Ampliar: `test/features/cannon_test.dart`
- No tocar: árbol y presentación

## Pasos

1. En `docs/balance.csv`, tras `base,g1_auto_interval,…`, añade:
   ```
   base,g2_arc,0,0,g2_arc,150,degrees,,
   base,g2_auto_interval,0,0,g2_auto_interval,1.5,seconds,,
   base,g3_arc,0,0,g3_arc,150,degrees,,
   base,g3_auto_interval,0,0,g3_auto_interval,1.5,seconds,,
   base,g4_arc,0,0,g4_arc,150,degrees,,
   base,g4_auto_interval,0,0,g4_auto_interval,1.5,seconds,,
   ```
2. En `catalog.dart`, añade esas seis claves a las bases obligatorias.
3. En el constructor de `Board`, sustituye la creación del cañón por:
   ```dart
   for (final slot in cannonSlots) {
     if (slot.index == 1 || settings['g${slot.index}_enabled'] > 0) {
       cannons.add(Cannon(slot));
     }
   }
   ```
4. Revisa que `fromJson` siga comparando `slot` por posición con `board.cannons[i].slot` (ya implementado en E02-T02).
5. Pruebas en `test/features/cannon_test.dart`:
   - `only G1 exists without purchases`: `cannons.length == 1`.
   - `enabled slots appear in order`: con `g2_enabled = 1` y `g4_enabled = 1` (sin G3), los huecos son `[1, 2, 4]` y G4 está en (180, 540).
   - `each cannon uses its own arc and automation`: con `g2_enabled = 1`, `g2_automatic = 1` y `g1_arc = 90`, en 3 s sin toques solo dispara G2 (2 bolas que nacen a 24 unidades de (20, 150)), y `cannonAngle(G2)` está siempre en `[−75°, 75°]`.
   - `side cannon shots point inwards`: la primera bola de G2 tiene `velocity.x > 0` y la de G3, `velocity.x < 0`.
   - `saved board with a different cannon count is rejected`: el JSON de un tablero con G1 y G2 restaurado con settings solo con G1 lanza `FormatException`.

## Criterios de aceptación

- [x] Las cinco pruebas nuevas y la suite completa pasan.

## Verificación

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Fuera de alcance

- Filas `upgrade,g2_*`–`g4_*` y nodos del árbol (E04-T02).

## Si te bloqueas

- Si una prueba antigua del árbol falla por las bases nuevas, no cambies las bases: anota el nombre de la prueba y para.

## Notas de implementación

- Seis bases nuevas (`g2`–`g4` arco e intervalo) en el CSV y en `fromCsv`; el constructor de `Board` crea G1 y los huecos habilitados en orden. `fromJson` ya comparaba el hueco por posición, sin cambios.
- Cinco pruebas nuevas en `cannon_test.dart`. En la de «arco y automático propios», la distancia de la bola a la boca se comprueba con tolerancia de un paso (la bola ya se ha movido en el paso en que nace). Total: 160 pruebas. Sin desviaciones.
