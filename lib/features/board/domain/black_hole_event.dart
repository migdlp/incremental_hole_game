import 'dart:math' as math;
import '../../../core/vec.dart';
import '../../upgrades/domain/catalog.dart';

class BlackHoleObject {
  BlackHoleObject(this.id, this.position, this.velocity, this.hitsRequired);
  final int id, hitsRequired;
  Vec position, velocity;
  int hits = 0;
  double damageFlash = 0;
  static const radius = 18.0;
  bool contains(Vec point) => (point - position).length <= radius + 5;
  Map<String, dynamic> toJson() => {
    'id': id,
    'position': position.toJson(),
    'velocity': velocity.toJson(),
    'hitsRequired': hitsRequired,
    'hits': hits,
    'damageFlash': damageFlash,
  };
}

class BlackHoleImpact {
  BlackHoleImpact(this.position);
  final Vec position;
  double age = 0;
  static const lifetime = .2;
}

/// A fixed production-time schedule, independent of frames and other event RNGs.
class BlackHoleEvent {
  BlackHoleEvent(this.settings, {required int seed, int forcedObjects = 0})
    : randomState = (seed ^ 0xbb67ae85) & 0xffffffff {
    if (forcedObjects < 0 || forcedObjects > 3) {
      throw ArgumentError('Objetos de prueba inválidos');
    }
    if (!enabled) return;
    for (var i = 0; i < forcedObjects; i++) {
      forceSpawn(position: Vec(360 * (i + 1) / (forcedObjects + 1), 280));
    }
  }
  BlackHoleEvent._(this.settings);
  final DaySettings settings;
  final objects = <BlackHoleObject>[];
  final impacts = <BlackHoleImpact>[];
  int randomState = 0,
      checks = 0,
      nextId = 1,
      activations = 0,
      forced = 0,
      revision = 0;
  double elapsed = 0, remaining = 0, announcement = 0, lastActiveTime = 0;
  bool ended = false;
  bool get enabled => settings.balanceVersion >= 12;
  bool get active => !ended && remaining > 0;
  double get interval => settings['black_hole_interval'];
  double get duration => math.min(10.0, settings['black_hole_duration']);
  double get reach => settings['black_hole_radius'];
  double get production => settings['production_duration'];
  int get maximumChecks =>
      !enabled ? 0 : ((production - 1e-9) / interval).floor();
  double get nextCheck => (checks + 1) * interval;

  double _random() {
    randomState = (1664525 * randomState + 1013904223) & 0xffffffff;
    return randomState / 4294967296;
  }

  BlackHoleObject _spawn({Vec? position}) {
    final hits = 3 + (_random() * 4).floor();
    final point = Vec(40 + _random() * 280, 130 + _random() * 260);
    final angle = _random() * math.pi * 2;
    final object = BlackHoleObject(
      nextId++,
      position ?? point,
      Vec(math.cos(angle), math.sin(angle)) *
          settings['black_hole_object_speed'],
      hits,
    );
    objects.add(object);
    return object;
  }

  BlackHoleObject? forceSpawn({Vec? position}) {
    if (!enabled || ended || elapsed >= production || forced >= 3) return null;
    forced++;
    return _spawn(position: position);
  }

  BlackHoleObject? objectAt(Vec point) {
    for (final object in objects.reversed) {
      if (object.contains(point)) return object;
    }
    return null;
  }

  bool hit(int id) {
    if (!enabled || ended || elapsed >= production) return false;
    final object = objects.where((o) => o.id == id).firstOrNull;
    if (object == null) return false;
    object.hits++;
    object.damageFlash = .18;
    revision++;
    if (impacts.length >= 24) impacts.removeAt(0);
    impacts.add(BlackHoleImpact(object.position));
    if (object.hits == object.hitsRequired) {
      objects.remove(object);
      activations++;
      remaining = duration;
      announcement = 1;
    }
    return true;
  }

  double accelerationAt(double distance) {
    if (!enabled || distance >= reach) return 0;
    final factor = (1 - distance / reach).clamp(0.0, 1.0);
    return settings['black_hole_acceleration'] *
        math.pow(factor, settings['black_hole_curve']).toDouble();
  }

  void _segment(double dt) {
    if (dt <= 0) return;
    lastActiveTime += math.min(dt, remaining);
    remaining = math.max(0.0, remaining - dt);
    if (remaining < 1e-9) remaining = 0;
    announcement = math.max(0.0, announcement - dt);
    // Analytic reflection keeps slow drifting independent of the update size.
    (double, double) axis(double position, double velocity, double extent) {
      const margin = BlackHoleObject.radius + 4;
      final span = extent - 2 * margin;
      final phase = (position - margin + velocity * dt) % (2 * span);
      return phase <= span
          ? (margin + phase, velocity)
          : (margin + 2 * span - phase, -velocity);
    }

    for (final object in objects) {
      final x = axis(object.position.x, object.velocity.x, 360);
      final y = axis(object.position.y, object.velocity.y, 560);
      object.position = Vec(x.$1, y.$1);
      object.velocity = Vec(x.$2, y.$2);
      object.damageFlash = math.max(0.0, object.damageFlash - dt);
    }
    for (final impact in impacts) {
      impact.age += dt;
    }
    impacts.removeWhere(
      (impact) => impact.age >= BlackHoleImpact.lifetime - 1e-9,
    );
  }

  void advance(double dt, {required bool producing}) {
    lastActiveTime = 0;
    if (!enabled || !producing || ended || dt <= 0) return;
    final end = math.min(production, elapsed + dt);
    while (nextCheck <= end + 1e-9 && checks < maximumChecks) {
      final at = nextCheck;
      _segment(math.max(0.0, at - elapsed));
      elapsed = at;
      checks++;
      if (_random() < settings['black_hole_probability']) _spawn();
    }
    _segment(math.max(0.0, end - elapsed));
    elapsed = end;
    if (elapsed >= production - 1e-9) endProduction();
  }

  /// Closing removes every object and effect; no event continues into collection.
  void endProduction() {
    ended = true;
    elapsed = production;
    remaining = announcement = 0;
    objects.clear();
    impacts.clear();
  }

  void finishDay() {
    endProduction();
    objects.clear();
    nextId = 1;
    activations = forced = 0;
  }

  Map<String, dynamic> toJson() => {
    'random': randomState,
    'checks': checks,
    'nextId': nextId,
    'activations': activations,
    'forced': forced,
    'elapsed': elapsed,
    'remaining': remaining,
    'announcement': announcement,
    'ended': ended,
    'objects': objects.map((o) => o.toJson()).toList(),
  };

  factory BlackHoleEvent.fromJson(
    DaySettings settings,
    Map<String, dynamic> json,
  ) {
    final event = BlackHoleEvent._(settings);
    int integer(String key, int maximum) {
      final value = json[key];
      if (value is! int || value < 0 || value > maximum) {
        throw const FormatException('Contador de Agujero negro inválido');
      }
      return value;
    }

    double number(String key, double maximum) {
      final value = json[key];
      if (value is! num || !value.isFinite || value < 0 || value > maximum) {
        throw const FormatException('Tiempo de Agujero negro inválido');
      }
      return value.toDouble();
    }

    event.randomState = integer('random', 0xffffffff);
    event.checks = integer('checks', event.maximumChecks);
    event.forced = integer('forced', 3);
    event.nextId = integer('nextId', event.maximumChecks + 4);
    event.activations = integer('activations', event.maximumChecks + 3);
    event.elapsed = number('elapsed', event.production);
    event.remaining = number('remaining', event.duration);
    event.announcement = number('announcement', 1);
    final ended = json['ended'], rows = json['objects'];
    if (ended is! bool ||
        rows is! List ||
        rows.length > event.maximumChecks + 3) {
      throw const FormatException('Objetos de Agujero negro inválidos');
    }
    event.ended = ended;
    for (final row in rows) {
      if (row is! Map<String, dynamic>) {
        throw const FormatException('Objeto de Agujero negro inválido');
      }
      final id = row['id'],
          required = row['hitsRequired'],
          hits = row['hits'],
          flash = row['damageFlash'];
      if (id is! int ||
          id < 1 ||
          id >= event.nextId ||
          required is! int ||
          required < 3 ||
          required > 6 ||
          hits is! int ||
          hits < 0 ||
          hits >= required ||
          flash is! num ||
          !flash.isFinite ||
          flash < 0 ||
          flash > .18) {
        throw const FormatException('Daño de Agujero negro inválido');
      }
      final object =
          BlackHoleObject(
              id,
              Vec.fromJson(row['position']),
              Vec.fromJson(row['velocity']),
              required,
            )
            ..hits = hits
            ..damageFlash = flash.toDouble();
      if ((object.position - object.position.inside(22)).length > 1e-6 ||
          (object.velocity.length - settings['black_hole_object_speed']).abs() >
              1e-6) {
        throw const FormatException('Movimiento de Agujero negro inválido');
      }
      event.objects.add(object);
    }
    final expectedChecks = math.min(
      event.maximumChecks,
      ((event.elapsed + 1e-9) / event.interval).floor(),
    );
    if (event.nextId < 1 ||
        (!event.ended && event.checks != expectedChecks) ||
        event.nextId - 1 > event.checks + event.forced ||
        event.activations > event.nextId - 1 ||
        (event.ended
            ? event.objects.isNotEmpty
            : event.objects.length + event.activations != event.nextId - 1) ||
        event.objects.map((o) => o.id).toSet().length != event.objects.length ||
        (event.remaining > 0 && event.activations == 0) ||
        (event.announcement > 0 && event.remaining == 0) ||
        (event.ended != (event.elapsed >= event.production - 1e-9)) ||
        (event.ended && (event.remaining != 0 || event.announcement != 0))) {
      throw const FormatException('Estado de Agujero negro incoherente');
    }
    return event;
  }
}
