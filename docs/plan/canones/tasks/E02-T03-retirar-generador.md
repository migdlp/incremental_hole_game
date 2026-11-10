---
id: E02-T03
title: Retirar Generador rápido y Doble emisión
epic: E02
status: done
depends_on: [E02-T02]
requirements: [RF-15]
size: M
---

# E02-T03 · Retirar Generador rápido y Doble emisión

## Objetivo

El catálogo, el CSV y el árbol dejan de tener las mejoras `generator` y `double_spawn` y las bases `spawn_interval` y `balls_per_spawn`. «Día más largo» pasa a requerir «Mayor recompensa» II (`reward:2`) mientras llega su requisito definitivo (E03-T02).

## Contexto

- `docs/balance.csv` contiene `base,spawn_interval,…`, `base,balls_per_spawn,…`, cinco filas `upgrade,generator,…`, una `upgrade,double_spawn,…` y cinco `upgrade,duration,…` con `requires = generator:2`.
- `UpgradeCatalog.labels` (en `lib/features/upgrades/domain/catalog.dart`) tiene las entradas `'double_spawn'` y `'generator'`. La lista de bases obligatorias incluye `'spawn_interval'` y `'balls_per_spawn'`.
- `SkillTree` (en `lib/features/upgrades/domain/skill_tree.dart`) tiene `routes['generator']` y `routes['double_spawn']`.
- Tras E02-T02, `Board` ya no lee esas claves.
- El requisito temporal de `duration` es `reward:2`. E03-T02 lo cambia a `g1_auto_speed:1`.
- Regla de geometría del árbol (prueba `all node dependencies and routed segments use eight directions without passing through nodes`, en `test/features/next_improvements_test.dart`): cada nodo debe estar alineado (horizontal, vertical o diagonal de 45°) con **cada** padre, incluidos los que aporta su requisito. `duration:1` está en la celda (2, 1) y `reward:2` en (5, 1): alineados en horizontal y sin nodos entre medias una vez retirado `generator`. `hand:1` (5, 3) **no** está alineado; por eso no se usa.
- `skill_tree_screen.dart`, en `_details()`, calcula el porcentaje con `final isInterval = node.definition.effect == 'spawn_interval';` (menor es mejor). Al desaparecer `spawn_interval`, la condición pasa a `effect.endsWith('_interval')`, que cubrirá `gN_auto_interval` en E03.

## Archivos

- Modificar: `docs/balance.csv`, `lib/features/upgrades/domain/catalog.dart`, `lib/features/upgrades/domain/skill_tree.dart`, `lib/features/upgrades/presentation/skill_tree_screen.dart`
- Modificar pruebas que mencionen `generator`, `double_spawn`, `spawn_interval` o `balls_per_spawn` (`grep -rln "generator\|double_spawn\|spawn_interval\|balls_per_spawn" test`), entre ellas `test/features/future_tree_test.dart`, `test/features/skill_tree_test.dart` y `test/features/next_improvements_test.dart`
- No tocar: `board.dart` y `garden_game.dart`

## Pasos

1. En `docs/balance.csv`, borra las filas `base,spawn_interval,…`, `base,balls_per_spawn,…`, todas las `upgrade,generator,…` y la `upgrade,double_spawn,…`. En las cinco filas `upgrade,duration,…`, cambia `generator:2` por `reward:2`.
2. En `catalog.dart`, borra las entradas `'double_spawn'` y `'generator'` de `labels` y quita `'spawn_interval'` y `'balls_per_spawn'` de la lista de bases obligatorias.
3. En `skill_tree.dart`, borra las claves `'generator'` y `'double_spawn'` de `routes`.
4. En `skill_tree_screen.dart`, borra los casos `'generator'` y `'double_spawn'` de `_typeColor`, `_icons`, `_description` y `_summary`. En `_typeColor`, el patrón `'generator' || 'double_spawn' => const Color(0xff22c55e),` desaparece; ese verde lo reutiliza E03-T02 para los cañones. En `_details()`, sustituye `final isInterval = node.definition.effect == 'spawn_interval';` por `final isInterval = node.definition.effect.endsWith('_interval');`.
5. Pruebas:
   - Las que cuentan tipos o nodos pasan a **13 tipos y 43 nodos** (antes 15 y 49).
   - Las que compran `generator` o `double_spawn` como paso intermedio para llegar a otra mejora: elimina ese paso si la mejora destino ya no lo requiere, o sustitúyelo por `hand:1` (si la mejora destino requería `generator`, ahora requiere lo indicado en el paso 1).
   - Las que verifican efectos de `generator` o `double_spawn` se borran.
   - Añade a `test/features/future_tree_test.dart`: `retired production upgrades are gone`, que comprueba que `testCatalog().definitions` no contiene `generator` ni `double_spawn` y que `duration` nivel 1 tiene `requirements == ['reward:2']`.

## Criterios de aceptación

- [x] `grep -rn "spawn_interval\|balls_per_spawn\|double_spawn\|'generator'" lib docs/balance.csv` no devuelve nada.
- [x] Las pruebas de geometría del árbol (segmentos en ocho direcciones y sin solapes) siguen pasando.
- [x] Suite completa en verde.

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

- Si alguna otra mejora del CSV requiere `generator` o `double_spawn`, para: solo `duration` y `double_spawn` dependen de `generator` en el CSV actual, así que sería una contradicción con el plan. Anótalo en «Notas de implementación».

## Bloqueo (resuelto 2026-11-10)

**Resolución del planificador:** opción 2. Requisito temporal `reward:2`, alineado con `duration:1`. Pasos, contexto y criterios actualizados arriba; E03-T02 lo sustituye por `g1_auto_speed:1`. Se ha simulado la prueba de geometría con el CSV real de `main` en los tres estados del árbol (tras E02-T03, E03-T02 y E04-T02) y pasa en todos. Aplica el parche local guardado cambiando `hand:1` por `reward:2` en las filas `duration` y en la prueba nueva.

Texto original del bloqueo:

Al aplicar el paso 1 (`duration` pasa a `requires = hand:1`), la prueba existente `all node dependencies and routed segments use eight directions without passing through nodes` (`test/features/next_improvements_test.dart`) falla con `hand:1 → duration:1`.

- Causa: esa prueba exige que cada nodo esté alineado (horizontal, vertical o diagonal de 45°) con cada uno de sus padres. `hand:1` está en la celda lógica (5, 3) y `duration:1` en (2, 1): el desfase es (−3, −2), que no está alineado. Hoy el padre es `generator:2` en (3, 1), que sí lo está. Los criterios de aceptación de esta tarea exigen que las pruebas de geometría del árbol sigan pasando.
- El plan no resuelve el conflicto: «Día más largo» sigue en `line(2, 1, -1, 0, 5)` («sin cambios» en la arquitectura) y E03-T02 no la mueve.
- El resto de fallos de la suite (recuentos 15→13 tipos y 49→43 nodos, y pruebas que compran `generator`) son los ajustes esperados por la tarea. Lo único que no se puede resolver sin decidir es la geometría.

Opciones:

1. Mover `duration` a otra ruta alineada con `hand:1` (5, 3). Es una decisión de diseño del árbol; las celdas cercanas están reservadas para E03-T02/E04-T02 (`g1_auto` en (4, 2), `g1_auto_speed` desde (3, 1)).
2. Elegir otro requisito temporal que sí esté alineado con (2, 1), p. ej. `reward:2` (5, 1). Cambia el balance temporal («Día más largo» exigiría 2 niveles de «Mayor recompensa»).
3. Relajar la prueba de alineación solo para `duration:1` hasta E03-T02, que lo reubica en `g1_auto_speed:1`. Toca una prueba que la tarea no lista.
4. Fusionar el cambio de requisito de `duration` en E03-T02 y dejar en E02-T03 un requisito que no rompa la geometría.

El trabajo hecho (CSV, catálogo, rutas, pantalla del árbol y parte de las pruebas) está guardado en un parche local fuera de la rama y no se ha commiteado; la rama conserva la suite en verde.

## Notas de implementación

- Retirados `generator`, `double_spawn`, `spawn_interval` y `balls_per_spawn` del CSV, el catálogo, las rutas y la pantalla del árbol. `duration` requiere `reward:2` y `_details()` usa `effect.endsWith('_interval')`.
- Pruebas: recuentos a 13 tipos y 43 nodos; compras intermedias de `generator` sustituidas por `reward`; prueba nueva `retired production upgrades are gone`. La prueba de geometría del árbol pasa sin cambios. Total: 137 pruebas. Sin más desviaciones.
