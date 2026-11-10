---
id: E03-T02
title: Mejoras de G1 en balance y árbol
epic: E03
status: todo
depends_on: [E03-T01, E02-T03]
requirements: [RF-11, RF-12, RF-20]
size: M
---

# E03-T02 · Mejoras de G1 en balance y árbol

## Objetivo

El árbol ofrece «Cañón 1 · Automático», «Cañón 1 · Ritmo automático» (4 niveles) y «Cañón 1 · Puntería» (5 niveles) en un lienzo ampliado de 864 × 1120. «Día más largo» requiere `g1_auto_speed:1`.

## Contexto

- Las filas del CSV, las etiquetas y las rutas exactas están en `docs/plan/canones/02-architecture.md` (secciones «Balance» y «Árbol»). Las de G1 son:
  ```
  upgrade,g1_auto,1,60,g1_automatic,1,unlock,hand:1,1
  upgrade,g1_auto_speed,1,80,g1_auto_interval,1.3,seconds,g1_auto:1,
  upgrade,g1_auto_speed,2,130,g1_auto_interval,1.1,seconds,g1_auto:1,
  upgrade,g1_auto_speed,3,220,g1_auto_interval,0.95,seconds,g1_auto:1,
  upgrade,g1_auto_speed,4,360,g1_auto_interval,0.8,seconds,g1_auto:1,
  upgrade,g1_aim,1,40,g1_arc,135,degrees,g1_auto:1,
  upgrade,g1_aim,2,70,g1_arc,120,degrees,g1_auto:1,
  upgrade,g1_aim,3,110,g1_arc,110,degrees,g1_auto:1,
  upgrade,g1_aim,4,180,g1_arc,100,degrees,g1_auto:1,
  upgrade,g1_aim,5,300,g1_arc,90,degrees,g1_auto:1,
  ```
- `SkillTree` (en `lib/features/upgrades/domain/skill_tree.dart`) usa `line(x, y, dx, dy, count)` con `48.0 + (x + dx*i + 2) * spacing` y la Y equivalente con `+ 2`. `canvasSize = 864.0` se usa en `skill_tree_screen.dart` (`width: SkillTree.canvasSize` y `height: SkillTree.canvasSize`, línea ~217) y quizá en otros sitios: búscalo con `grep -rn canvasSize lib test`.
- La pantalla asigna color, icono, descripción y resumen por ID en `_typeColor`, `_icons`, `_description` y `_summary` de `lib/features/upgrades/presentation/skill_tree_screen.dart`.

## Archivos

- Modificar: `docs/balance.csv`, `lib/features/upgrades/domain/catalog.dart`, `lib/features/upgrades/domain/skill_tree.dart`, `lib/features/upgrades/presentation/skill_tree_screen.dart`
- Modificar o ampliar pruebas: `test/features/future_tree_test.dart`, `test/features/skill_tree_test.dart` (recuentos y límite Y del lienzo) y `test/features/next_improvements_test.dart` (recuentos)
- No tocar: `board.dart`

## Pasos

1. Añade las 10 filas de G1 al final de `docs/balance.csv`. En las cinco filas `upgrade,duration,…`, cambia `requires` de `reward:2` a `g1_auto_speed:1`. `duration:1` (2, 1) y `g1_auto_speed:1` (3, 1) quedan alineados en horizontal.
2. En `catalog.dart`, añade a `labels`, justo antes de `'reward'`:
   ```dart
   'g1_auto': ['Cañón 1 · Automático', 'Producción'],
   'g1_auto_speed': ['Cañón 1 · Ritmo automático', 'Producción'],
   'g1_aim': ['Cañón 1 · Puntería', 'Producción'],
   ```
3. En `skill_tree.dart`:
   1. Sustituye `static const canvasSize = 864.0;` por `static const canvasWidth = 864.0;` y `static const canvasHeight = 1120.0;`.
   2. En `line()`, cambia el `+ 2` de la Y por `+ 6`. La X no cambia.
   3. Añade a `routes`: `'g1_auto': line(4, 2, 0, 0, 1)`, `'g1_auto_speed': line(3, 1, -1, -1, 4)` y `'g1_aim': line(3, 2, -1, 0, 5)`.
4. Sustituye todos los usos de `SkillTree.canvasSize` por `canvasWidth` (ancho) y `canvasHeight` (alto) en `lib` y `test`.
5. En `skill_tree_screen.dart`:
   1. Añade la función `bool _isCannon(String id) => RegExp(r'^g[1-4]_').hasMatch(id);`.
   2. En `_typeColor`, añade al principio del `switch` el caso `final id when _isCannon(id) => const Color(0xff22c55e),`.
   3. Añade a `_icons`: `'g1_auto': Icons.autorenew`, `'g1_auto_speed': Icons.speed` y `'g1_aim': Icons.track_changes`.
   4. En `_description`, añade al principio, para cualquier ID de cañón, el cálculo `n = id[1]`:
      - `*_auto` → `'El cañón $n dispara solo; puedes seguir tocándolo'`
      - `*_auto_speed` → `'El cañón $n dispara solo más a menudo'`
      - `*_aim` → `'Estrecha el arco del cañón $n para apuntar mejor'`
      - `*_unlock` → `'Añade el cañón $n al tablero. Llega manual'`

      Implementa con `if (_isCannon(id)) { final n = id[1]; return switch (id.substring(3)) { 'auto' => …, 'auto_speed' => …, 'aim' => …, 'unlock' => …, _ => '' }; }` antes del `switch` existente, convirtiendo la función en cuerpo de bloque.
   5. En `_details()`, la línea `final isInterval = node.definition.effect.endsWith('_interval');` (de E02-T03) pasa a `final isInterval = node.definition.effect.endsWith('_interval') || node.definition.effect.endsWith('_arc');`, porque la Puntería también es «menor es mejor» y si no mostraría un porcentaje negativo. Renombrar la variable es opcional; si lo haces, usa `lowerIsBetter`.
   6. En `_summary`, la misma estructura para cañones:
      - `auto` → `('', 'Dispara solo', ' y comparte la recarga contigo.')`
      - `auto_speed` → `('Dispara solo cada ', number(value), ' s.')`
      - `aim` → `('Arco de ', '${number(value)}°', '.')`
      - `unlock` → `('', 'Cañón $n', ' en el tablero.')`
7. Pruebas:
   - Actualiza los recuentos a **16 tipos y 53 nodos**.
   - En `test/features/skill_tree_test.dart` (líneas ~16–17), el límite `expect(node.y, inInclusiveRange(32, 1056));` pasa a `expect(node.y, inInclusiveRange(32, SkillTree.canvasHeight - 48));` (= 1072). Con el desplazamiento de +6 filas, la fila lógica 10 (nivel 5 de `paddle`, «Escoba más ancha») queda en y = 1072 y el nodo, de radio 32, sigue dentro del lienzo de 1120. El límite de X (`40, 840`) no cambia.
   - Añade a `future_tree_test.dart` `G1 upgrades follow the planned values`: niveles de `g1_auto_speed` = [1.3, 1.1, 0.95, 0.8] y de `g1_aim` = [135, 120, 110, 100, 90], `g1_auto` nivel 1 requiere `hand:1` y `duration` nivel 1 requiere `g1_auto_speed:1`.
   - Añade `buying G1 automatic makes the next day automatic`: sesión con saldo 60 y `hand:1`. Compra `g1_auto`, `startDay()` y `board.cannonAutomatic(board.cannons.first)` es `true`.
   - Las pruebas existentes de geometría (ocho direcciones, sin solapes y dentro del lienzo) deben pasar con el lienzo nuevo.

## Criterios de aceptación

- [ ] Las pruebas nuevas, las de geometría y la suite completa pasan.
- [ ] En `flutter run -d chrome`, el árbol muestra los tres nodos nuevos en verde con su icono, ficha y precio.

## Verificación

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Fuera de alcance

- Filas y nodos de G2–G4 (E04-T02).
- Revisar precios: son provisionales (SUPUESTO-1).

## Si te bloqueas

- Si una prueba de geometría falla por una ruta nueva que no se puede trazar en ocho direcciones, no muevas nodos existentes: para y anota la ruta fallida.
- Si `switch` con patrón `final id when …` no compila en Dart 3.9 dentro de una expresión de `Color`, usa `if (_isCannon(node.definition.id)) return const Color(0xff22c55e);` antes del `switch` y anótalo.
