import 'dart:math' as math;
import '../../../core/vec.dart';
import '../../upgrades/domain/catalog.dart';

enum GravityStage { none, waiting, object, active, spent }

/// One independent event roll per day. Never consumes the ball-generator RNG.
class GravityEvent {
  GravityEvent(
    this.settings, {
    required int seed,
    required bool available,
    bool force = false,
  }) : randomState = (seed ^ 0x6a09e667) & 0xffffffff {
    if (settings.balanceVersion < 11 || !available) return;
    if (!force && _random() >= settings['gravity_probability']) return;
    stage = GravityStage.waiting;
    spawnAt = force ? 0 : _random() * settings['production_duration'];
    if (force) _spawn();
  }
  GravityEvent._(this.settings);
  final DaySettings settings;
  GravityStage stage = GravityStage.none;
  int randomState = 0;
  double elapsed = 0, spawnAt = -1;
  Vec position = const Vec(180, 280), drift = Vec.zero;
  int hitsRequired = 0, hits = 0, revision = 0;
  double remaining = 0, announcement = 0, damageFlash = 0;
  Vec filteredTilt = Vec.zero;
  double lastActiveTime = 0;
  static const radius = 19.0;
  bool get hasObject => stage == GravityStage.object;
  bool get active => stage == GravityStage.active;
  double get duration => math.min(10.0, settings['gravity_duration']);

  double _random() {
    randomState = (1664525 * randomState + 1013904223) & 0xffffffff;
    return randomState / 4294967296;
  }

  void _spawn() {
    stage = GravityStage.object;
    hitsRequired = 3 + (_random() * 4).floor();
    position = Vec(40 + _random() * 280, 130 + _random() * 260);
    final angle = _random() * math.pi * 2;
    drift =
        Vec(math.cos(angle), math.sin(angle)) *
        settings['gravity_object_speed'];
  }

  bool contains(Vec point) =>
      hasObject && (point - position).length <= radius + 5;

  bool hit({required bool available}) {
    if (!available ||
        !hasObject ||
        elapsed >= settings['production_duration']) {
      return false;
    }
    hits++;
    revision++;
    damageFlash = .18;
    if (hits == hitsRequired) {
      stage = GravityStage.active;
      remaining = math.min(duration, settings['production_duration'] - elapsed);
      announcement = math.min(1, remaining);
      filteredTilt = Vec.zero;
    }
    return true;
  }

  /// Returns the velocity increment; partial final steps never extend the effect.
  Vec advance(
    double dt, {
    required bool producing,
    required bool available,
    required Vec tilt,
  }) {
    lastActiveTime = 0;
    if (!producing || dt <= 0) return Vec.zero;
    final step = math.min(
      dt,
      math.max(0.0, settings['production_duration'] - elapsed),
    );
    final before = elapsed;
    elapsed += step;
    damageFlash = math.max(0.0, damageFlash - step);
    announcement = math.max(0.0, announcement - step);
    if (stage == GravityStage.waiting && elapsed >= spawnAt) _spawn();
    if (hasObject) {
      final travel = math.min(
        step,
        math.max(0.0, elapsed - math.max(before, spawnAt)),
      );
      final next = position + drift * travel;
      position = next.inside(radius + 4);
      drift = Vec(
        position.x != next.x ? -drift.x : drift.x,
        position.y != next.y ? -drift.y : drift.y,
      );
    }
    if (!active) return Vec.zero;
    lastActiveTime = math.min(step, remaining);
    final target = available ? tilt.limit(1) : Vec.zero;
    final weight = 1 - math.exp(-settings['gravity_response'] * lastActiveTime);
    filteredTilt = filteredTilt + (target - filteredTilt) * weight;
    remaining = math.max(0.0, remaining - lastActiveTime);
    if (remaining < 1e-9 || elapsed >= settings['production_duration']) {
      remaining = 0;
      stage = GravityStage.spent;
      announcement = 0;
    }
    return available
        ? filteredTilt * (settings['gravity_acceleration'] * lastActiveTime)
        : Vec.zero;
  }

  void finish() {
    elapsed = settings['production_duration'];
    stage = GravityStage.spent;
    remaining = announcement = damageFlash = lastActiveTime = 0;
    filteredTilt = Vec.zero;
  }

  Map<String, dynamic> toJson() => {
    'stage': stage.name,
    'random': randomState,
    'elapsed': elapsed,
    'spawnAt': spawnAt,
    'position': position.toJson(),
    'drift': drift.toJson(),
    'hitsRequired': hitsRequired,
    'hits': hits,
    'remaining': remaining,
    'announcement': announcement,
    'damageFlash': damageFlash,
    'tilt': filteredTilt.toJson(),
  };

  factory GravityEvent.fromJson(
    DaySettings settings,
    Map<String, dynamic> json,
  ) {
    final event = GravityEvent._(settings);
    double number(String key, double low, double high) {
      final value = json[key];
      if (value is! num || !value.isFinite || value < low || value > high) {
        throw const FormatException('Estado de Gravedad inválido');
      }
      return value.toDouble();
    }

    event.stage = GravityStage.values.firstWhere(
      (s) => s.name == json['stage'],
      orElse: () => throw const FormatException('Fase de Gravedad inválida'),
    );
    final random = json['random'],
        required = json['hitsRequired'],
        hits = json['hits'];
    if (random is! int ||
        random < 0 ||
        random > 0xffffffff ||
        required is! int ||
        hits is! int ||
        required < 0 ||
        required > 6 ||
        hits < 0 ||
        hits > required) {
      throw const FormatException('Contadores de Gravedad inválidos');
    }
    event.randomState = random;
    event.hitsRequired = required;
    event.hits = hits;
    event.elapsed = number('elapsed', 0, settings['production_duration']);
    event.spawnAt = number('spawnAt', -1, settings['production_duration']);
    event.remaining = number('remaining', 0, event.duration);
    event.announcement = number('announcement', 0, 1);
    event.damageFlash = number('damageFlash', 0, .18);
    event.position = Vec.fromJson(json['position']);
    event.drift = Vec.fromJson(json['drift']);
    event.filteredTilt = Vec.fromJson(json['tilt']);
    if (required > 0 && required < 3) {
      throw const FormatException('Resistencia de Gravedad inválida');
    }
    final visibleOrBroken = event.hasObject || event.active;
    if ((event.position - event.position.inside(radius + 4)).length > .0001 ||
        event.drift.length > settings['gravity_object_speed'] + 1e-6 ||
        event.filteredTilt.length > 1 + 1e-6 ||
        (visibleOrBroken && required < 3) ||
        (event.hasObject && hits >= required) ||
        (event.active && (hits != required || event.remaining <= 0)) ||
        (!event.active && (event.remaining != 0 || event.announcement != 0)) ||
        (event.active &&
            event.remaining >
                settings['production_duration'] - event.elapsed + 1e-6) ||
        (event.stage == GravityStage.waiting &&
            (event.spawnAt < event.elapsed || required != 0 || hits != 0)) ||
        (event.stage == GravityStage.none &&
            (event.spawnAt != -1 || required != 0 || hits != 0)) ||
        (visibleOrBroken &&
            (event.spawnAt < 0 || event.spawnAt > event.elapsed + 1e-6))) {
      throw const FormatException('Estado de Gravedad incoherente');
    }
    return event;
  }
}
