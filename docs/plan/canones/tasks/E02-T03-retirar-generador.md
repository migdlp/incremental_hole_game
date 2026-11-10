---
id: E02-T03
title: Retirar Generador rápido y Doble emisión
epic: E02
status: todo
depends_on: [E02-T02]
requirements: [RF-15]
size: M
---

# E02-T03 · Retirar Generador rápido y Doble emisión

## Objetivo

El catálogo, el CSV y el árbol dejan de tener las mejoras `generator` y `double_spawn` y las bases `spawn_interval` y `balls_per_spawn`. «Día más largo» se compra tras Mano I mientras llega su requisito definitivo (E03-T02).

## Contexto

- `docs/balance.csv` contiene `base,spawn_interval,…`, `base,balls_per_spawn,…`, cinco filas `upgrade,generator,…`, una `upgrade,double_spawn,…` y cinco `upgrade,duration,…` con `requires = generator:2`.
- `UpgradeCatalog.labels` (en `lib/features/upgrades/domain/catalog.dart`) tiene las entradas `'double_spawn'` y `'generator'`. La lista de bases obligatorias incluye `'spawn_interval'` y `'balls_per_spawn'`.
- `SkillTree` (en `lib/features/upgrades/domain/skill_tree.dart`) tiene `routes['generator']` y `routes['double_spawn']`.
- Tras E02-T02, `Board` ya no lee esas claves.
- El requisito temporal de `duration` es `hand:1`. E03-T02 lo cambia a `g1_auto_speed:1`.

## Archivos

- Modificar: `docs/balance.csv`, `lib/features/upgrades/domain/catalog.dart`, `lib/features/upgrades/domain/skill_tree.dart`, `lib/features/upgrades/presentation/skill_tree_screen.dart`
- Modificar pruebas que mencionen `generator`, `double_spawn`, `spawn_interval` o `balls_per_spawn` (`grep -rln "generator\|double_spawn\|spawn_interval\|balls_per_spawn" test`), entre ellas `test/features/future_tree_test.dart`, `test/features/skill_tree_test.dart` y `test/features/next_improvements_test.dart`
- No tocar: `board.dart` y `garden_game.dart`

## Pasos

1. En `docs/balance.csv`, borra las filas `base,spawn_interval,…`, `base,balls_per_spawn,…`, todas las `upgrade,generator,…` y la `upgrade,double_spawn,…`. En las cinco filas `upgrade,duration,…`, cambia `generator:2` por `hand:1`.
2. En `catalog.dart`, borra las entradas `'double_spawn'` y `'generator'` de `labels` y quita `'spawn_interval'` y `'balls_per_spawn'` de la lista de bases obligatorias.
3. En `skill_tree.dart`, borra las claves `'generator'` y `'double_spawn'` de `routes`.
4. En `skill_tree_screen.dart`, borra los casos `'generator'` y `'double_spawn'` de `_typeColor`, `_icons`, `_description` y `_summary`. En `_typeColor`, el patrón `'generator' || 'double_spawn' => const Color(0xff22c55e),` desaparece; ese verde lo reutiliza E03-T02 para los cañones.
5. Pruebas:
   - Las que cuentan tipos o nodos pasan a **13 tipos y 43 nodos** (antes 15 y 49).
   - Las que compran `generator` o `double_spawn` como paso intermedio para llegar a otra mejora: elimina ese paso si la mejora destino ya no lo requiere, o sustitúyelo por `hand:1`.
   - Las que verifican efectos de `generator` o `double_spawn` se borran.
   - Añade a `test/features/future_tree_test.dart`: `retired production upgrades are gone`, que comprueba que `testCatalog().definitions` no contiene `generator` ni `double_spawn` y que `duration` nivel 1 tiene `requirements == ['hand:1']`.

## Criterios de aceptación

- [ ] `grep -rn "spawn_interval\|balls_per_spawn\|double_spawn\|'generator'" lib docs/balance.csv` no devuelve nada.
- [ ] Las pruebas de geometría del árbol (segmentos en ocho direcciones y sin solapes) siguen pasando.
- [ ] Suite completa en verde.

## Verificación

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Fuera de alcance

- Añadir las ramas nuevas del cañón (E03-T02 y E04-T02).
- Ampliar el lienzo del árbol (E03-T02).

## Si te bloqueas

- Si alguna otra mejora del CSV requiere `generator` o `double_spawn`, cámbiale el requisito a `hand:1` y anótalo en «Notas de implementación».
