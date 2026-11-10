---
id: E01-T01
title: Guardado v6 sin migraciones
epic: E01
status: done
depends_on: []
requirements: [RF-16]
size: M
---

# E01-T01 · Guardado v6 sin migraciones

## Objetivo

El juego solo lee y escribe guardados con `"version": 6`. Cualquier guardado anterior se ignora sin aviso y la partida empieza de cero. Desaparecen el código de migración y los balances congelados.

## Contexto

- No hay jugadores reales. El usuario decidió borrar el progreso sin migrar (ADR-01 en `docs/plan/canones/02-architecture.md`).
- Ahora `GameSession.restore` (en `lib/app/game_session.dart`) acepta las versiones 1–5. Usa `_grandfathered`, `_previousTree`, `legacy` y `balanceVersion` del 1 al 6, y `UpgradeCatalog.settings`/`validateLevels` (en `lib/features/upgrades/domain/catalog.dart`) leen `legacy_balance.dart`, `balance_v4.dart` y `balance_v5.dart`.
- `Board.fromJson` (en `lib/features/board/domain/board.dart`) parte las «pilas antiguas» de valor arbitrario en monedas válidas. Eso también se elimina: una moneda con valor fuera de 1/10/50/100/500 hace el guardado inválido.
- `load()` prueba los candidatos en orden (principal y luego copia) y lanza `FormatException` si ninguno se puede restaurar.

## Archivos

- Borrar: `lib/features/upgrades/domain/legacy_balance.dart`, `lib/features/upgrades/domain/balance_v4.dart`, `lib/features/upgrades/domain/balance_v5.dart`
- Modificar: `lib/features/upgrades/domain/catalog.dart`, `lib/app/game_session.dart`, `lib/features/board/domain/board.dart` (solo `fromJson`)
- Modificar pruebas: `test/features/balance_test.dart`, `test/features/ball_controls_test.dart`, `test/features/currency_test.dart`, `test/features/future_tree_test.dart`, `test/features/hand_capacity_test.dart`, `test/features/skill_tree_test.dart`, `test/features/ui_economy_test.dart`, `test/features/game_rules_test.dart`
- No tocar: `docs/balance.csv`, la presentación y `lib/persistence/*`

## Pasos

1. Borra los tres archivos de balance congelado.
2. En `catalog.dart`:
   1. Quita los tres `import`.
   2. En `DaySettings` cambia el valor por defecto a `balanceVersion = 7`.
   3. Sustituye `settings` por `DaySettings settings(Map<String, int> owned)`: copia `base` y aplica, para cada definición con nivel > 0, `values[definition.effect] = definition.levels[level - 1].value`. Devuelve `DaySettings(values)`. Quita los bloques de `balanceVersion == 1` y `== 2`.
   4. Sustituye `validateLevels` por `void validateLevels(Map<String, int> levels)`. Para cada entrada: la definición existe, `0 <= value <= definition.levels.length` y, si `value > 0`, `requirementsMet(definition.levels[value - 1], levels)`. Si algo falla, lanza `FormatException('Mejoras guardadas inválidas')` o `FormatException('Requisito guardado incumplido')`, con los mismos textos que ahora.
3. En `game_session.dart`:
   1. Elimina los campos `_grandfathered` y `_previousTree` y cada uno de sus usos.
   2. En `snapshot()` escribe `'version': 6` y elimina las claves `grandfathered` y `previousTree`.
   3. En `restore()`: si `json['version'] != 6`, lanza `FormatException('Versión de guardado no compatible')`. Elimina las variables `legacy`, `oldProgress`, `grandfathered` y `previousTree`, la conversión de `paddle` a `broom` y el `recoveryMessage` de partida actualizada. La herramienta se lee siempre de `json['tool']`. En `run`, `balanceVersion` debe ser exactamente `7` o se lanza `FormatException('Versión de balance inválida')`. `settings = catalog.settings(savedLevels)`. Elimina el bloque que rellena `hand_capacity` y el que quita claves en `legacy`. Mantén el resto de validaciones (tiempo, contabilidad, resultado, herramienta sin desbloquear).
   4. Reescribe `load()` así:
      ```dart
      Future<void> load() async {
        final candidates = await store.loadCandidates();
        var current = 0;
        for (final raw in candidates) {
          if (!_isCurrentVersion(raw)) continue;
          current++;
          try {
            restore(raw);
            _lastSaved = raw;
            if (current > 1) {
              recoveryMessage = 'Partida recuperada desde la copia de seguridad.';
            }
            return;
          } on Object {
            // Try the previous complete snapshot before offering an explicit reset.
          }
        }
        if (current == 0) return; // Only old or no saves: start a new game.
        throw const FormatException(
          'El guardado y su copia no se pueden leer. No se han sobrescrito.',
        );
      }

      static bool _isCurrentVersion(String raw) {
        try {
          final json = jsonDecode(raw);
          return json is! Map || json['version'] is! int || json['version'] == 6;
        } on FormatException {
          return true; // Unparseable data is treated as a damaged current save.
        }
      }
      ```
4. En `Board.fromJson`, sustituye el bloque `oldPiles` por una validación: si alguna moneda tiene un `value` que no está en `CoinDenomination.values.map((d) => d.amount)`, lanza `FormatException('Tablero guardado inválido')`. Mantén la llamada a `board._flushCoins()`.
5. Pruebas:
   1. Borra las pruebas cuyo propósito es restaurar guardados de versiones 1–5 o balances 1–6. Por nombre, entre otras: `old v2 run survives reload until next day adopts the new balance`, `saved balance 2 keeps its cadence until the next day` y `bug-era saves load with single hand and no free broom`. Haz `grep -n "'version': [1-5]\|balanceVersion\|grandfathered\|previousTree\|legacy" test -r` y, para cada coincidencia, borra la prueba si solo verifica la migración o cámbiala a `'version': 6` / `balanceVersion: 7` si verifica otra regla.
   2. Añade en `test/features/game_rules_test.dart`:
      - `old version saves are ignored and a new game starts`: `MemoryStore` con `candidates = ['{"version":5,"day":9,"balance":500}']`. Tras `await session.load()`: `progress.day == 1`, `economy.balance == 0`, `levels` vacío y `recoveryMessage == null`.
      - `current version roundtrip keeps progress`: guarda con saldo 40 y día 3, restaura en una sesión nueva y comprueba ambos valores.
      - `damaged current save still raises the explicit reset error`: candidates `['{"version":6,"day":-1}']` y `load()` lanza `FormatException`.

## Casos límite a cubrir

| Caso | Comportamiento esperado |
| --- | --- |
| Principal v5 y copia v5 | Partida nueva, sin mensaje |
| Principal v6 dañado y copia v6 válida | Restaura la copia y muestra «Partida recuperada desde la copia de seguridad.» |
| Principal v6 válido y copia v5 | Restaura el principal |
| Texto que no es JSON | Se trata como v6 dañado: si no hay otra opción, se lanza `FormatException` |
| Moneda guardada con valor 3 | `FormatException('Tablero guardado inválido')` |

## Criterios de aceptación

- [x] `grep -rn "legacyBalanceCsv\|balanceV4Csv\|balanceV5Csv\|grandfathered\|previousTree" lib test` no devuelve nada.
- [x] `snapshot()` contiene `"version":6` y, con jornada activa, `"balanceVersion":7`.
- [x] Las tres pruebas nuevas y la tabla de casos límite pasan.
- [x] El juego arranca en web con almacenamiento vacío.

## Verificación

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Fuera de alcance

- Cualquier cambio de física o del cañón (E01-T02 y E02).
- Cambiar `FileSaveStore` o `store_web.dart`.

## Si te bloqueas

- Si una prueba existente mezcla migración con otra regla y no puedes separarlas, conserva la regla con `'version': 6` y anota en «Notas de implementación» qué parte de migración quitaste.
- No añadas un aviso de reinicio: el usuario lo descartó.

## Notas de implementación

- Borrados los tres balances congelados; `settings()` y `validateLevels()` quedan sin versiones antiguas, y `GameSession` solo lee y escribe `"version": 6` (balance 7). `load()` ignora los candidatos de versiones anteriores sin aviso.
- `Board.fromJson` lanza `FormatException('Tablero guardado inválido')` ante monedas con valor fuera de 1/10/50/100/500.
- Pruebas: eliminadas 8 pruebas que solo verificaban migración (v1–v5 y balances 1–6); añadidas 8 en `game_rules_test.dart` (las 3 pedidas más los casos límite de la tabla y el snapshot). La prueba `unknown balance…` se conserva con balance 7.
- Sin desviaciones. Total: 116 pruebas.
