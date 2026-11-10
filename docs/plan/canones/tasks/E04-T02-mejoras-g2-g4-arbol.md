---
id: E04-T02
title: Mejoras de G2–G4 en balance y árbol
epic: E04
status: todo
depends_on: [E04-T01]
requirements: [RF-13, RF-14, RF-20]
size: M
---

# E04-T02 · Mejoras de G2–G4 en balance y árbol

## Objetivo

El árbol permite comprar Cañón 2, 3 y 4 en orden, con sus mejoras propias. En total quedan 28 tipos y 74 nodos.

## Contexto

- Filas exactas en `docs/plan/canones/02-architecture.md`, sección «Balance», desde `upgrade,g2_unlock,…` hasta `upgrade,g4_aim,3,…` (21 filas).
- Rutas exactas en la sección «Árbol»:
  ```
  'g2_unlock': line(4, -3, 0, 0, 1),
  'g2_auto': line(3, -3, 0, 0, 1),
  'g2_auto_speed': line(2, -3, -1, 0, 2),
  'g2_aim': line(4, -4, 0, -1, 3),
  'g3_unlock': line(6, -3, 0, 0, 1),
  'g3_auto': line(7, -3, 0, 0, 1),
  'g3_auto_speed': line(8, -3, 1, 0, 2),
  'g3_aim': line(6, -4, 0, -1, 3),
  'g4_unlock': line(8, -5, 0, 0, 1),
  'g4_auto': line(9, -5, 0, 0, 1),
  'g4_auto_speed': line(10, -5, 0, 1, 2),
  'g4_aim': line(8, -6, 1, 0, 3),
  ```
- La pantalla del árbol (`lib/features/upgrades/presentation/skill_tree_screen.dart`) ya resuelve color, descripción y resumen para cualquier ID de cañón mediante `_isCannon` (E03-T02). Solo faltan los iconos.

## Archivos

- Modificar: `docs/balance.csv`, `lib/features/upgrades/domain/catalog.dart`, `lib/features/upgrades/domain/skill_tree.dart`, `lib/features/upgrades/presentation/skill_tree_screen.dart`
- Ampliar pruebas: `test/features/future_tree_test.dart` y los recuentos de `test/features/skill_tree_test.dart` y `test/features/next_improvements_test.dart`
- No tocar: `board.dart`

## Pasos

1. Añade las 21 filas al final de `docs/balance.csv`, en el orden de la arquitectura.
2. En `catalog.dart`, añade a `labels`, tras `'g1_aim'`, para N = 2, 3 y 4 y en este orden:
   ```dart
   'gN_unlock': ['Cañón N', 'Producción'],
   'gN_auto': ['Cañón N · Automático', 'Producción'],
   'gN_auto_speed': ['Cañón N · Ritmo automático', 'Producción'],
   'gN_aim': ['Cañón N · Puntería', 'Producción'],
   ```
   Escribe las 12 entradas literalmente (sin generarlas en bucle) para que `labels` siga siendo `const`.
3. En `skill_tree.dart`, añade las 12 rutas.
4. En `skill_tree_screen.dart`, añade a `_icons` para N = 2, 3 y 4: `'gN_unlock': Icons.add_circle_outline`, `'gN_auto': Icons.autorenew`, `'gN_auto_speed': Icons.speed` y `'gN_aim': Icons.track_changes`.
5. Pruebas:
   - Recuentos: **28 tipos y 74 nodos**.
   - `cannon unlocks follow G2 then G3 then G4`: `g2_unlock` requiere `g1_auto:1`, `g3_unlock` requiere `g2_unlock:1` y `g4_unlock` requiere `g3_unlock:1`.
   - `per cannon upgrades are independent` (RF-14): `catalog.settings({'hand': 1, 'g1_auto': 1, 'g1_aim': 1, 'g2_unlock': 1})` da `g1_arc == 135` y `g2_arc == 150`.
   - `buying cannon 2 adds it to the next day`: sesión con saldo suficiente y los requisitos comprados. `purchase(g2_unlock)`, `startDay()` y `board.cannons.length == 2`.

## Criterios de aceptación

- [ ] Las pruebas nuevas, las de geometría del árbol y la suite completa pasan.
- [ ] En web, el árbol muestra las tres ramas nuevas por encima de G1, sin solapes ni conexiones cruzadas.

## Verificación

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Fuera de alcance

- Revisión de precios (SUPUESTO-1).

## Si te bloqueas

- Si una ruta no supera la prueba de ocho direcciones, no la cambies tú: anota cuál es y para.
