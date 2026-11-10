# Arquitectura · Generadores-cañón

Se siguen los patrones actuales: dominio puro en `lib/features/*/domain`, presentación Flame en `garden_game.dart`, sesión en `game_session.dart` y balance en `docs/balance.csv`, cargado por `UpgradeCatalog.fromCsv`. No se añaden dependencias.

## Componentes

| Componente | Archivo | Responsabilidad |
| --- | --- | --- |
| `CannonSlot`, `cannonSlots` | `lib/features/board/domain/cannon.dart` (nuevo) | Geometría fija de los 4 huecos |
| `Cannon` | `lib/features/board/domain/cannon.dart` (nuevo) | Estado de un cañón (recarga, reloj automático, destellos) y cálculo de ángulo y boca |
| `Board` | `lib/features/board/domain/board.dart` | Crea los cañones según `settings`, los dispara, los guarda y aplica física: velocidad de captura, rebote y obstáculo |
| `UpgradeCatalog` | `lib/features/upgrades/domain/catalog.dart` | Etiquetas de las mejoras nuevas, bases obligatorias y validación sin versiones antiguas |
| `SkillTree` | `lib/features/upgrades/domain/skill_tree.dart` | Posiciones de los nodos nuevos y lienzo de 864 × 1120 |
| `GameSession` | `lib/app/game_session.dart` | Guardado v6 sin migraciones |
| `GardenGame` | `lib/features/board/presentation/garden_game.dart` | Dibujo de los cañones |

## Contrato de `cannon.dart`

```dart
import 'dart:math' as math;
import '../../../core/vec.dart';

class CannonSlot {
  const CannonSlot(this.index, this.position, this.baseAngle);
  final int index; // 1..4
  final Vec position;
  final double baseAngle; // radians, board coordinates (y grows downwards)
}

const cannonSlots = [
  CannonSlot(1, Vec(180, 60), math.pi / 2),
  CannonSlot(2, Vec(20, 150), 0),
  CannonSlot(3, Vec(340, 150), math.pi),
  CannonSlot(4, Vec(180, 540), -math.pi / 2),
];

class Cannon {
  Cannon(this.slot, {this.cooldown = 0, this.autoClock = 0});
  final CannonSlot slot;
  double cooldown;     // seconds until a shot is allowed
  double autoClock;    // seconds accumulated towards the next automatic shot
  double blockedFlash = 0; // presentation only, not saved
  double recoil = 0;       // presentation only, not saved
  static const bodyRadius = 16.0;
  static const muzzleDistance = 24.0;
  static const touchRadius = 28.0;
  static const blockedSeconds = .3;
  static const recoilSeconds = .12;

  /// Triangle wave: constant angular speed, full back-and-forth per period.
  double angleAt(double clock, {required double arcDegrees, required double period}) {
    final s = (clock / period + (slot.index - 1) * .25) % 1.0;
    final tri = 1 - 4 * (s - .5).abs(); // -1 → 1 → -1
    return slot.baseAngle + tri * arcDegrees * math.pi / 360;
  }

  Vec muzzle(double angle) =>
      slot.position + Vec(math.cos(angle), math.sin(angle)) * muzzleDistance;

  /// Advances presentation timers and cooldown. Never negative.
  void tick(double dt) {
    cooldown = math.max(0, cooldown - dt);
    blockedFlash = math.max(0, blockedFlash - dt);
    recoil = math.max(0, recoil - dt);
  }

  Map<String, dynamic> toJson() =>
      {'slot': slot.index, 'cooldown': cooldown, 'autoClock': autoClock};
}
```

Nota: `tri` vale −1 en `s = 0`, pero el desfase por hueco hace que G1 empiece en `base − arco/2`. RF-01 se comprueba con G1, cuyo desfase es 0.

## API de `Board`

| Miembro | Firma | Comportamiento |
| --- | --- | --- |
| `cannons` | `final List<Cannon> cannons` | Se rellena en el constructor: G1 siempre y GN (N = 2..4) si `settings['gN_enabled'] > 0`, en orden de hueco. |
| `cannonClock` | `double cannonClock = 0` | Avanza solo durante la producción y fuera de `coinOnly`. |
| `cannonAngle` | `double cannonAngle(Cannon c)` | `c.angleAt(cannonClock, arcDegrees: settings['g${n}_arc'], period: settings['cannon_sweep_period'])` |
| `cannonAutomatic` | `bool cannonAutomatic(Cannon c)` | `settings['g${n}_automatic'] > 0` |
| `fireCannon` | `bool fireCannon(Cannon c)` | Disparo manual. Devuelve `false` si `coinOnly`, si la recarga es > 0 o si está bloqueado (RF-04). Si dispara, crea la bola y aplica recarga y reloj. |
| `cannonAt` | `Cannon? cannonAt(Vec point)` | El cañón activo más cercano a ≤ `Cannon.touchRadius`, o `null`. |

Disparo (privado `_shoot(Cannon c)`, común a manual y automático):

1. `angle = cannonAngle(c)` y `muzzle = c.muzzle(angle)`.
2. Bloqueado si `balls.length >= settings['ball_limit']` o si alguna bola está a menos de `radius * 2.2` de `muzzle`. En ese caso `c.blockedFlash = Cannon.blockedSeconds` y devuelve `false`.
3. `balls.add(Ball(nextId++, muzzle, Vec(cos, sin) * settings['cannon_shot_speed'], golden: random() < .01))`.
4. `c.cooldown = cannonAutomatic(c) ? min(settings['cannon_cooldown'], settings['g${n}_auto_interval']) : settings['cannon_cooldown']`, `c.autoClock = 0`, `c.recoil = Cannon.recoilSeconds` y devuelve `true`.

En `update`, con `producing && !coinOnly`, se sustituye el bloque `spawnClock` por:

```dart
cannonClock += dt;
for (final cannon in cannons) {
  cannon.tick(dt);
  if (!cannonAutomatic(cannon)) continue;
  cannon.autoClock += dt;
  if (cannon.autoClock + 1e-9 >= settings['g${cannon.slot.index}_auto_interval'] &&
      cannon.cooldown <= 0) {
    _shoot(cannon); // on failure autoClock is kept, so it retries next step
  }
}
```

Fuera de producción no se llama a `tick`: recarga y destellos quedan congelados (RF-05 y RF-24).

## Cambios de física en `Board.update`

- En la integración de bolas libres, `ball.velocity.limit(380)` pasa a `limit(settings['max_ball_speed'])`. Los cuatro `.limit(380)` de `_collide` pasan a usar el mismo valor. Los límites 380 de la mano, la escoba y el robot (`releasePointer`, `_releaseVelocity`, `_contactBroom`, `_push` y `_moveTool`) no cambian.
- En el rebote, los dos `* .4` de `bounded` pasan a `* settings['wall_restitution']`.
- Obstáculo: tras el rebote en paredes y para cada cañón activo, si `d = ball.position - c.slot.position` cumple `d.length < Cannon.bodyRadius + radius`, se recoloca la bola en `c.slot.position + d.unit * (Cannon.bodyRadius + radius)`. Si `vn = v·n < 0`, se aplica `v = v - n * vn * (1 + wall_restitution)`. Si `d.length < 0.0001`, `n = Vec(cos(baseAngle), sin(baseAngle))`.
- Captura: en `balls.removeWhere`, una bola libre (no está en `_heldBalls`) solo se captura si además `ball.velocity.length <= settings['hole_capture_speed']`.

## Toque (`Board.touch`)

Al principio de `touch`, después de fijar `paddle`, `target`, `_downPoint` y las muestras: si `!coinOnly` y `cannonAt(paddle!)` no es `null`, se llama a `fireCannon`, se marca `_cannonGesture = true` y se devuelve 0. Con `_cannonGesture`, `drag` no cobra (devuelve 0 sin llamar a `_collect`) y `releasePointer` no cobra por toque. `releasePointer` pone `_cannonGesture = false`.

## Balance (`docs/balance.csv`)

Columnas: `kind,id,level,cost,effect,effect_value,unit,requires,cap`.

Filas base nuevas (E01 y E02):

```
base,max_ball_speed,0,0,max_ball_speed,600,logical_units_per_second,,
base,wall_restitution,0,0,wall_restitution,0.55,ratio,,
base,hole_capture_speed,0,0,hole_capture_speed,140,logical_units_per_second,,
base,cannon_cooldown,0,0,cannon_cooldown,1,seconds,,
base,cannon_sweep_period,0,0,cannon_sweep_period,2,seconds,,
base,cannon_shot_speed,0,0,cannon_shot_speed,520,logical_units_per_second,,
base,g1_arc,0,0,g1_arc,150,degrees,,
base,g1_auto_interval,0,0,g1_auto_interval,1.5,seconds,,
base,g2_arc,0,0,g2_arc,150,degrees,,
base,g2_auto_interval,0,0,g2_auto_interval,1.5,seconds,,
base,g3_arc,0,0,g3_arc,150,degrees,,
base,g3_auto_interval,0,0,g3_auto_interval,1.5,seconds,,
base,g4_arc,0,0,g4_arc,150,degrees,,
base,g4_auto_interval,0,0,g4_auto_interval,1.5,seconds,,
```

Se eliminan las bases `spawn_interval` y `balls_per_spawn` y todas las filas `upgrade,generator,…` y `upgrade,double_spawn,…`. La fila `duration` pasa a `requires = g1_auto_speed:1` en sus cinco niveles.

Mejoras nuevas (precios provisionales, SUPUESTO-1):

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
upgrade,g2_unlock,1,250,g2_enabled,1,unlock,g1_auto:1,1
upgrade,g2_auto,1,150,g2_automatic,1,unlock,g2_unlock:1,1
upgrade,g2_auto_speed,1,200,g2_auto_interval,1.3,seconds,g2_auto:1,
upgrade,g2_auto_speed,2,330,g2_auto_interval,1.1,seconds,g2_auto:1,
upgrade,g2_aim,1,120,g2_arc,135,degrees,g2_unlock:1,
upgrade,g2_aim,2,200,g2_arc,120,degrees,g2_unlock:1,
upgrade,g2_aim,3,330,g2_arc,110,degrees,g2_unlock:1,
upgrade,g3_unlock,1,600,g3_enabled,1,unlock,g2_unlock:1,1
upgrade,g3_auto,1,350,g3_automatic,1,unlock,g3_unlock:1,1
upgrade,g3_auto_speed,1,450,g3_auto_interval,1.3,seconds,g3_auto:1,
upgrade,g3_auto_speed,2,740,g3_auto_interval,1.1,seconds,g3_auto:1,
upgrade,g3_aim,1,280,g3_arc,135,degrees,g3_unlock:1,
upgrade,g3_aim,2,460,g3_arc,120,degrees,g3_unlock:1,
upgrade,g3_aim,3,760,g3_arc,110,degrees,g3_unlock:1,
upgrade,g4_unlock,1,1400,g4_enabled,1,unlock,g3_unlock:1,1
upgrade,g4_auto,1,800,g4_automatic,1,unlock,g4_unlock:1,1
upgrade,g4_auto_speed,1,1000,g4_auto_interval,1.3,seconds,g4_auto:1,
upgrade,g4_auto_speed,2,1650,g4_auto_interval,1.1,seconds,g4_auto:1,
upgrade,g4_aim,1,640,g4_arc,135,degrees,g4_unlock:1,
upgrade,g4_aim,2,1050,g4_arc,120,degrees,g4_unlock:1,
upgrade,g4_aim,3,1730,g4_arc,110,degrees,g4_unlock:1,
```

Etiquetas en `UpgradeCatalog.labels`, nombre y rama:

| ID | Nombre | Rama |
| --- | --- | --- |
| `g1_auto` | `Cañón 1 · Automático` | `Producción` |
| `g1_auto_speed` | `Cañón 1 · Ritmo automático` | `Producción` |
| `g1_aim` | `Cañón 1 · Puntería` | `Producción` |
| `g2_unlock` | `Cañón 2` | `Producción` |
| `g2_auto` | `Cañón 2 · Automático` | `Producción` |
| `g2_auto_speed` | `Cañón 2 · Ritmo automático` | `Producción` |
| `g2_aim` | `Cañón 2 · Puntería` | `Producción` |
| `g3_unlock`…`g3_aim` | Mismo patrón con `Cañón 3` | `Producción` |
| `g4_unlock`…`g4_aim` | Mismo patrón con `Cañón 4` | `Producción` |

## Árbol (`SkillTree`)

El lienzo pasa de 864 × 864 a **864 de ancho × 1120 de alto**. `SkillTree.canvasSize` se sustituye por `canvasWidth = 864.0` y `canvasHeight = 1120.0`, y `line()` desplaza la Y en +6 celdas: `(48.0 + (x + dx*i + 2) * spacing, 48.0 + (y + dy*i + 6) * spacing)`. Las rutas existentes conservan sus coordenadas lógicas y solo se mueven 6 celdas hacia abajo en píxeles.

Coordenadas lógicas `line(x, y, dx, dy, count)` de las rutas nuevas (las de `generator`, `double_spawn` y `duration` se reutilizan o eliminan como se indica):

| ID | Ruta |
| --- | --- |
| `g1_auto` | `line(4, 2, 0, 0, 1)` (celda que ocupaba Generador I) |
| `g1_auto_speed` | `line(3, 1, -1, -1, 4)` |
| `g1_aim` | `line(3, 2, -1, 0, 5)` |
| `duration` | `line(2, 1, -1, 0, 5)` (sin cambios) |
| `g2_unlock` | `line(4, -3, 0, 0, 1)` |
| `g2_auto` | `line(3, -3, 0, 0, 1)` |
| `g2_auto_speed` | `line(2, -3, -1, 0, 2)` |
| `g2_aim` | `line(4, -4, 0, -1, 3)` |
| `g3_unlock` | `line(6, -3, 0, 0, 1)` |
| `g3_auto` | `line(7, -3, 0, 0, 1)` |
| `g3_auto_speed` | `line(8, -3, 1, 0, 2)` |
| `g3_aim` | `line(6, -4, 0, -1, 3)` |
| `g4_unlock` | `line(8, -5, 0, 0, 1)` |
| `g4_auto` | `line(9, -5, 0, 0, 1)` |
| `g4_auto_speed` | `line(10, -5, 0, 1, 2)` |
| `g4_aim` | `line(8, -6, 1, 0, 3)` |

Se eliminan las claves `generator` y `double_spawn` de `routes`. Resultado: 28 tipos de mejora y 74 nodos (43 actuales que se conservan + 31 nuevos).

## Guardado (versión 6)

- `snapshot()` escribe `'version': 6` y deja de escribir `grandfathered` y `previousTree`.
- `run.balanceVersion` vale siempre 7 (`DaySettings.balanceVersion` por defecto = 7).
- `board` sustituye `spawnClock` por `cannonClock` (número) y `cannons` (lista de `{slot, cooldown, autoClock}` en orden de hueco).
- `Board.fromJson` exige: `cannons.length == board.cannons.length`, `slot` igual al hueco en la misma posición, valores finitos ≥ 0, `cooldown ≤ settings['cannon_cooldown']` y `cannonClock` finito ≥ 0.
- `GameSession.load()` ignora los candidatos cuya clave `version` sea un entero distinto de 6. Si todos son de versiones antiguas, empieza una partida nueva sin mensaje. El primer `save()` sobrescribe `progress.json`.

## ADRs

### ADR-01 · Reiniciar el guardado en lugar de migrar

- Contexto: hay migraciones v1–v5 y tres balances congelados (`legacy_balance.dart`, `balance_v4.dart` y `balance_v5.dart`) que complican cada cambio de árbol. No hay jugadores reales.
- Decisión: versión 6, se ignoran las anteriores y se borra el código histórico.
- Consecuencias: catálogo y sesión más simples. Se eliminan las pruebas de migración. El usuario pierde su progreso local una vez.

### ADR-02 · Captura por umbral de velocidad sobre la física existente

- Contexto: se quiere que una bola rápida no caiga. La física es propia, con 240 subpasos/s.
- Opciones: (a) umbral de velocidad en la captura; (b) simular una pendiente o un borde del hoyo.
- Decisión: (a). Es un cambio de una condición y se apoya en la atracción ya existente (220 u/s²), que frena y curva la trayectoria. A 600 u/s el avance por subpaso es 2,5 unidades, menos de la mitad del radio de bola (6): no hay riesgo de que atraviese el hoyo ni los cuerpos.
- Consecuencias: las bolas agarradas quedan exentas para no cambiar la sensación de la mano.

### ADR-03 · Mejoras por cañón como definiciones independientes del catálogo

- Contexto: el catálogo asocia una definición a un único `effect`.
- Decisión: cada cañón tiene sus propios IDs (`gN_auto`, `gN_auto_speed`, `gN_aim` y `gN_unlock`) con claves de efecto `gN_*`, siguiendo el patrón de `magnet` + `attraction`.
- Consecuencias: árbol más grande (74 nodos) sin cambiar el modelo `UpgradeDefinition`.

### ADR-04 · Huecos fijos en código y valores de balance en CSV

- Decisión: posiciones, direcciones base y radios (cuerpo 16, boca 24 y toque 28) son constantes en `cannon.dart` porque definen la geometría del tablero. Velocidades, tiempos y arcos van en el CSV.

## Entregas y ramas

| PR | Rama | Epic | Base |
| --- | --- | --- | --- |
| 1 | `feat/canones-e01-cimientos` | E01 | `main` |
| 2 | `feat/canones-e02-canon-manual` | E02 | `main` tras fusionar PR 1 |
| 3 | `feat/canones-e03-automatico` | E03 | `main` tras fusionar PR 2 |
| 4 | `feat/canones-e04-mas-canones` | E04 | `main` tras fusionar PR 3 |
| 5 | `feat/canones-e05-cierre` | E05 | `main` tras fusionar PR 4 |

El APK se genera una sola vez (E05-T03), con la pipeline manual `Flutter - APK manual` sobre `main` después de fusionar la PR 5.

## Pruebas

- Unidad de dominio en `test/features/cannon_test.dart` (nuevo), con el estilo de los tests existentes (`package:flutter_test`, `testCatalog()` de `test/test_support.dart`).
- Pruebas de reglas que necesitan bolas: crearlas con `board.balls.add(Ball(board.nextId++, Vec(x, y), Vec.zero))` o con `board.fireCannon(board.cannons.first)` y avanzar `board.update`.
- Widgets: `flutter_test` con `MemoryStore`, igual que `test/widget_test.dart`.
