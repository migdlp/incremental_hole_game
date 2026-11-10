---
id: E03-T01
title: Disparo automático con recarga compartida
epic: E03
status: todo
depends_on: [E02-T05]
requirements: [RF-10, RF-23, RF-28]
size: M
---

# E03-T01 · Disparo automático con recarga compartida

## Objetivo

Un cañón con `settings['gN_automatic'] > 0` dispara solo cada `settings['gN_auto_interval']` segundos durante la producción. Comparte la recarga con el disparo manual.

## Contexto

- En `lib/features/board/domain/board.dart` ya existen `cannons`, `cannonAutomatic`, `_shoot`, `fireCannon` y el bucle de cañones de `update`, que hoy solo hace `tick` porque `cannonAutomatic` siempre es `false`.
- Reglas (RF-10, RF-23 y RF-28):
  - El reloj `autoClock` avanza solo si el cañón es automático, en producción y fuera de `coinOnly`.
  - Dispara cuando `autoClock + 1e-9 >= interval` y `cooldown <= 0`.
  - Tras cualquier disparo (manual o automático): `autoClock = 0` y `cooldown = automatic ? min(cannon_cooldown, interval) : cannon_cooldown`. `_shoot` ya lo hace según la arquitectura. Comprueba que así sea.
  - Si `_shoot` falla por bloqueo, `autoClock` se conserva y se reintenta en el paso siguiente.
- La base `g1_auto_interval` (1,5) aún no está en el CSV. La clave `g1_automatic` no tiene fila base: vale 0 hasta comprar la mejora (`DaySettings[]` devuelve 0 si falta). Las pruebas la activan con `settings.values['g1_automatic'] = 1`.

## Archivos

- Modificar: `docs/balance.csv`, `lib/features/upgrades/domain/catalog.dart`, `lib/features/board/domain/board.dart`
- Ampliar: `test/features/cannon_test.dart`
- No tocar: árbol y presentación

## Pasos

1. En `docs/balance.csv`, tras `base,g1_arc,…`, añade `base,g1_auto_interval,0,0,g1_auto_interval,1.5,seconds,,`.
2. En `catalog.dart`, añade `'g1_auto_interval'` a la lista de bases obligatorias.
3. En `board.dart`, comprueba que el bucle de `update` es exactamente el de «API de `Board`» en `docs/plan/canones/02-architecture.md`. Si `_shoot` no aplica `min(...)` cuando el cañón es automático, corrígelo.
4. Pruebas nuevas en `test/features/cannon_test.dart` (crea `settings = testCatalog().settings({})` y pon `settings.values['g1_automatic'] = 1` antes de `Board(settings)`):
   - `automatic cannon fires every interval`: 3 s de `update(1 / 60, producing: true)` sin toques producen exactamente 2 bolas (t ≈ 1,5 y t ≈ 3,0; tolerancia de un paso).
   - `manual tap resets the automatic clock`: toque (`fireCannon`) a t = 1,0. El siguiente disparo automático ocurre entre t = 2,48 y t = 2,52.
   - `automatic shot sets the shared cooldown`: justo después de un disparo automático con intervalo 1,5, `cooldown == 1` (1e-9). Con `settings.values['g1_auto_interval'] = 0.8`, `cooldown == 0.8`.
   - `blocked automatic shot retries without losing its turn`: tapa la boca justo antes de t = 1,5. A t = 1,6 no hay bola nueva y `autoClock >= 1.5`. Retira la bola que tapa y en el paso siguiente se dispara.
   - `manual cannon never fires on its own`: sin `g1_automatic`, 5 s sin toques producen 0 bolas.
   - `automatic clock freezes during closing`: tras `enterClosing()`, `autoClock` no cambia.

## Criterios de aceptación

- [ ] Las seis pruebas nuevas y la suite completa pasan.

## Verificación

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Fuera de alcance

- Filas `upgrade,g1_*` y nodos del árbol (E03-T02).

## Si te bloqueas

- Si el disparo automático cae un paso antes o después por error de coma flotante, conserva el `+ 1e-9` de la comparación y ajusta solo la tolerancia de la prueba a un paso (1/60 s).
