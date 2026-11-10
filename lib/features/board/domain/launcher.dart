import 'dart:math' as math;
import '../../../core/vec.dart';
import '../../upgrades/domain/catalog.dart';
import 'tool.dart';

/// One heavy, aimable producer. Geometry and pressure are independent of drawing.
class Launcher {
  Launcher(this.settings, {Vec? position, double? angle, int seed = 42})
    : position = position ?? const Vec(285, 510),
      angle = angle ?? math.pi * 1.75,
      randomState = (seed ^ 0x3c6ef372) & 0xffffffff {
    this.position = constrain(this.position, this.angle);
  }
  final DaySettings settings;
  Vec position, velocity = Vec.zero, pressure = Vec.zero;
  double angle, clock = 0, flash = 0, boundaryFlash = 0;
  int shots = 0, attempts = 0, randomState;
  bool get unlocked =>
      settings.balanceVersion >= 13 && settings['launcher_unlocked'] > 0;
  double get bodyRadius => settings['launcher_body_radius'];
  double get barrelLength => settings['launcher_barrel_length'];
  double get barrelRadius => settings['launcher_barrel_radius'];
  double get interval => settings['launcher_interval'];
  double get speed => settings['launcher_speed'];
  static const zoneTop = 420.0;
  Vec get axis => Vec(math.cos(angle), math.sin(angle));
  Vec get muzzle => position + axis * barrelLength;
  ToolSegment get barrel => ToolSegment(position, muzzle);
  List<Vec> get handles => [position - axis * bodyRadius, muzzle];

  Vec constrain(Vec point, double orientation) {
    if (settings.balanceVersion < 13) return point;
    final x = math.cos(orientation) * barrelLength;
    final y = math.sin(orientation) * barrelLength;
    final left = math.max(bodyRadius, -x + barrelRadius);
    final right = math.max(bodyRadius, x + barrelRadius);
    final top = math.max(bodyRadius, -y + barrelRadius);
    final bottom = math.max(bodyRadius, y + barrelRadius);
    return Vec(
      point.x.clamp(left, 360 - right),
      point.y.clamp(zoneTop + top, 560 - bottom),
    );
  }

  ({Vec normal, double depth, Vec point})? contact(Vec point, double radius) {
    if (!unlocked) return null;
    ({Vec normal, double depth, Vec point})? result;
    for (final (center, thickness) in [
      (position, bodyRadius),
      (barrel.closest(point), barrelRadius),
    ]) {
      final delta = point - center;
      final depth = radius + thickness - delta.length;
      if (depth > 0 && (result == null || depth > result.depth)) {
        final normal = delta.length > .00001 ? delta.unit : axis * -1;
        result = (
          normal: normal,
          depth: depth,
          point: center + normal * thickness,
        );
      }
    }
    return result;
  }

  bool contains(Vec point, {double extra = 10}) =>
      contact(point, extra) != null;

  void move(Vec point, double orientation) {
    final bounded = constrain(point, orientation);
    if ((bounded - point).length > .001) boundaryFlash = .15;
    position = bounded;
    angle = orientation % (2 * math.pi);
  }

  /// Saturated contact stress, not nearby-ball counts or accumulated impulses.
  /// The threshold exceeds three maximum single-contact stresses.
  void applyPressure(Vec force, double dt, {required bool held}) {
    if (held || force.length <= settings['launcher_pressure_threshold']) {
      pressure = held ? Vec.zero : force;
      velocity = Vec.zero;
      return;
    }
    final response = 1 - math.exp(-settings['launcher_pressure_response'] * dt);
    pressure = pressure + (force - pressure) * response;
    final excess = math.max(
      0.0,
      pressure.length - settings['launcher_pressure_threshold'],
    );
    final acceleration = pressure.unit * (excess / settings['launcher_mass']);
    if (excess == 0) {
      velocity = Vec.zero;
      return;
    }
    velocity =
        ((velocity + acceleration * dt) *
                math.exp(-settings['launcher_damping'] * dt))
            .limit(settings['launcher_pressure_speed']);
    final before = position;
    move(position + velocity * dt, angle);
    velocity = Vec(
      position.x == before.x ? 0 : velocity.x,
      position.y == before.y ? 0 : velocity.y,
    );
  }

  double random() {
    randomState = (1664525 * randomState + 1013904223) & 0xffffffff;
    return randomState / 4294967296;
  }

  void freeze() {
    velocity = pressure = Vec.zero;
    flash = boundaryFlash = 0;
  }

  Map<String, dynamic> toJson() => {
    'position': position.toJson(),
    'angle': angle,
    'velocity': velocity.toJson(),
    'pressure': pressure.toJson(),
    'clock': clock,
    'flash': flash,
    'boundaryFlash': boundaryFlash,
    'shots': shots,
    'attempts': attempts,
    'random': randomState,
  };
  factory Launcher.fromJson(DaySettings settings, Map<String, dynamic> json) {
    double number(String key, double max) {
      final value = json[key];
      if (value is! num || !value.isFinite || value < 0 || value > max) {
        throw const FormatException('Lanzador inválido');
      }
      return value.toDouble();
    }

    int count(String key) {
      final value = json[key];
      if (value is! int || value < 0 || value > 0xffffffff) {
        throw const FormatException('Contador de lanzador inválido');
      }
      return value;
    }

    final point = Vec.fromJson(json['position']);
    final launcher =
        Launcher(settings, position: point, angle: number('angle', math.pi * 2))
          ..velocity = Vec.fromJson(json['velocity'])
          ..pressure = Vec.fromJson(json['pressure'])
          ..clock = number('clock', settings['launcher_interval'])
          ..flash = number('flash', .15)
          ..boundaryFlash = number('boundaryFlash', .15)
          ..shots = count('shots')
          ..attempts = count('attempts')
          ..randomState = count('random');
    if ((launcher.position - point).length > 1e-6 ||
        launcher.velocity.length > settings['launcher_pressure_speed'] + 1e-6 ||
        launcher.pressure.length >
            settings['launcher_contact_pressure_limit'] *
                    settings['ball_limit'] +
                1e-6 ||
        launcher.clock >= settings['launcher_interval'] ||
        launcher.shots > launcher.attempts ||
        (!launcher.unlocked &&
            (launcher.clock != 0 ||
                launcher.shots != 0 ||
                launcher.attempts != 0 ||
                launcher.velocity.length != 0 ||
                launcher.pressure.length != 0))) {
      throw const FormatException('Estado de lanzador incoherente');
    }
    return launcher;
  }
}
