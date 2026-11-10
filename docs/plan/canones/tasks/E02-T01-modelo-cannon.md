---
id: E02-T01
title: Modelo de dominio Cannon
epic: E02
status: done
depends_on: [E01-T02]
requirements: [RF-01, RF-13]
size: S
---

# E02-T01 · Modelo de dominio `Cannon`

## Objetivo

Existe `lib/features/board/domain/cannon.dart`, con los cuatro huecos fijos y la clase `Cannon`, que calcula ángulo y boca y gestiona sus temporizadores, con pruebas. Todavía no se usa desde `Board`.

## Contexto

- Huecos (RF-13): G1 (180, 60) a 90°, G2 (20, 150) a 0°, G3 (340, 150) a 180° y G4 (180, 540) a −90°. Coordenadas lógicas del tablero 360 × 560, con la Y hacia abajo: un ángulo de π/2 apunta hacia abajo.
- Oscilación (RF-01): onda triangular de velocidad constante. Un ciclo completo de ida y vuelta dura `period`. Cada hueco empieza desfasado `(index - 1) * 0.25` del ciclo para que los cañones no vayan sincronizados.
- `Vec` está en `lib/core/vec.dart` (constructor `const Vec(x, y)` y operadores `+`, `-` y `* double`, `.length` y `.unit`).

## Archivos

- Crear: `lib/features/board/domain/cannon.dart`
- Crear: `test/features/cannon_test.dart`
- No tocar: `board.dart` y cualquier otro archivo

## Pasos

1. Crea `cannon.dart` con exactamente el contenido de la sección «Contrato de `cannon.dart`» de `docs/plan/canones/02-architecture.md` (clases `CannonSlot`, `Cannon` y la constante `cannonSlots`). Añade `static Cannon fromJson(CannonSlot slot, Map<String, dynamic> json)`, que lee `cooldown` y `autoClock` como `num` y lanza `FormatException('Cañón guardado inválido')` si: `json['slot'] != slot.index`, algún valor no es finito o es < 0.
2. Crea `test/features/cannon_test.dart` con:
   - `G1 sweeps a 150 degree arc at constant speed`: con `Cannon(cannonSlots[0])`, `arcDegrees: 150` y `period: 2`, los ángulos en t = 0; 0,5; 1; 1,5 y 2 valen π/2 − 75°, π/2, π/2 + 75°, π/2 y π/2 − 75° (tolerancia 1e-9, grados convertidos con `* math.pi / 180`).
   - `slots are phase shifted by a quarter period`: `Cannon(cannonSlots[1]).angleAt(0, arcDegrees: 150, period: 2)` es igual a `0 + 0` (a ¼ de ciclo, `tri = 0`; tolerancia 1e-9).
   - `muzzle is 24 units along the aim`: `Cannon(cannonSlots[0]).muzzle(math.pi / 2)` ≈ `Vec(180, 84)`.
   - `tick never makes timers negative`: cooldown 0,3 y `tick(1)` dan 0.
   - `fromJson rejects mismatched slot and negative values`: dos casos que lanzan `FormatException`.
   - `toJson roundtrip`: `fromJson(slot, cannon.toJson())` conserva `cooldown` y `autoClock`.

## Criterios de aceptación

- [x] Las seis pruebas pasan.
- [x] `cannon.dart` no importa nada de `upgrades` ni de `presentation`.

## Verificación

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/features/cannon_test.dart
```

## Fuera de alcance

- Disparar, crear bolas y leer `settings` (E02-T02).

## Si te bloqueas

- Si `Vec` no tiene un constructor `const` o los operadores indicados, para y repórtalo. No modifiques `vec.dart`.

## Notas de implementación

- `cannon.dart` sigue el contrato de la arquitectura al pie de la letra, más `Cannon.fromJson`, que valida hueco y valores finitos ≥ 0.
- Seis pruebas nuevas en `cannon_test.dart`. Sin desviaciones. Total: 127 pruebas.
