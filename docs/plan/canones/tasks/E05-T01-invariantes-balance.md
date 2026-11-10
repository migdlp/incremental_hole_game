---
id: E05-T01
title: Pruebas de invariantes de balance
epic: E05
status: todo
depends_on: [E04-T02]
requirements: [RNF-04]
size: S
---

# E05-T01 · Pruebas de invariantes de balance

## Objetivo

Un archivo de pruebas fija los invariantes del balance nuevo para detectar cambios accidentales del CSV.

## Contexto

- Día inicial: 10 s de producción (`production_duration`) y 3 s de recogida. Recarga manual de 1 s. Valor por bola 1 (dorada ×10, con un 1 % de probabilidad).
- Con juego perfecto y sin mejoras, se disparan 10 bolas por jornada (en t = 0 s y cada segundo hasta t = 9 s), así que el ingreso máximo esperado sin doradas es 10.
- La primera compra (`hand:1`) cuesta 13: debe requerir más de una jornada y como máximo dos.
- Valores de juego en `docs/balance.csv` y catálogo con `testCatalog()` (en `test/test_support.dart`).

## Archivos

- Crear: `test/features/cannon_balance_test.dart`
- No tocar: `docs/balance.csv` y `lib/`

## Pasos

1. Crea `test/features/cannon_balance_test.dart` con:
   - `a perfect first day fires ten shots`: `Board(testCatalog().settings({}))`. Durante 10 s de `update(1 / 60, producing: true)`, llama a `fireCannon(board.cannons.first)` en cada paso y cuenta los `true`: el resultado es 10.
   - `first purchase needs between one and two perfect days`: `13 > 10` y `13 <= 20`, leyendo 13 de `catalog.definitions` (`hand`, nivel 1, `cost`) y 10 de la prueba anterior (extrae una función auxiliar `int perfectShots(DaySettings s)`).
   - `cannon unlock prices grow along the chain`: coste de `g2_unlock` < `g3_unlock` < `g4_unlock`.
   - `automatic intervals strictly decrease per level`: para N = 1..4, los valores de `gN_auto_speed` son estrictamente decrecientes y el primero es < `gN_auto_interval` base (1,5).
   - `aim never widens`: para N = 1..4, los valores de `gN_aim` son estrictamente decrecientes y el primero es < 150.
   - `shot speed stays below the ball speed cap`: `cannon_shot_speed < max_ball_speed`.

## Criterios de aceptación

- [ ] Las seis pruebas pasan.

## Verificación

```bash
flutter test test/features/cannon_balance_test.dart
flutter test
```

## Fuera de alcance

- Cambiar precios. Si una prueba falla, el CSV no coincide con `02-architecture.md`: corrige el CSV para que coincida con la arquitectura, no la prueba.

## Si te bloqueas

- Si `perfectShots` da 11 porque se dispara también en t = 10 exacto, comprueba que el bucle se detiene cuando el tiempo acumulado llega a 10 − 1e-9. No cambies la recarga.
