import 'dart:math' as math;
import '../../../core/vec.dart';
import 'star_rewards.dart';

class StarBubble {
  StarBubble(
    this.reward,
    this.position,
    this.velocity, {
    this.holeCooldown = .8,
  });
  final StarReward reward;
  Vec position, velocity;
  double holeCooldown;
  Map<String, dynamic> toJson({bool held = false}) => {
    'id': reward.id,
    'p': position.toJson(),
    'v': (held ? Vec.zero : velocity).toJson(),
    'cooldown': holeCooldown,
  };
}

/// Bounded reusable burst/flight pool. Payment never depends on this pool.
class StarFlight {
  bool active = false;
  Vec start = Vec.zero;
  int category = 0;
  double age = 0;
}

class StarBubbles {
  StarBubbles(
    this.config, {
    required this.ballRadius,
    this.maximumSpeed = 380,
    this.hole = const Vec(180, 123.2),
  });
  final StarConfig config;
  final double ballRadius, maximumSpeed;
  late final _radii = List.generate(
    5,
    (category) => config.radius(ballRadius, category),
  );
  final bodies = <StarBubble>[];
  final broken = <int>[];
  final flights = List.generate(24, (_) => StarFlight());
  StarLedger ledger = const StarLedger();
  double entryClock = 0;
  int breakSerial = 0;
  StarBubble? held;
  Vec grabOffset = Vec.zero;
  double radius(StarBubble bubble) => _radii[bubble.reward.category];
  void sync(StarLedger value) => ledger = value;
  final Vec hole;
  void _eject(StarBubble b) {
    // Golden-ratio progression spreads eject directions without consuming ball RNG.
    final angle = .35 + ((b.reward.id * .61803398875) % 1) * 2.4;
    b.position = hole;
    b.velocity =
        Vec(math.cos(angle), math.sin(angle)) * config['star_eject_speed'];
    b.holeCooldown = .8;
  }

  void populate(double dt) {
    entryClock = math.max(0, entryClock - dt);
    if (entryClock > 0 ||
        ledger.pending.isEmpty ||
        bodies.length >= ledger.pending.length ||
        bodies.length >= config['star_active_limit']) {
      return;
    }
    final ids = bodies.map((b) => b.reward.id).toSet();
    final reward = ledger.pending
        .where((p) => !ids.contains(p.id) && !broken.contains(p.id))
        .firstOrNull;
    if (reward == null) return;
    // Do not create overlapping solids. Pending value remains in the ledger.
    final reach = _radii[reward.category];
    if (bodies.any((b) => (b.position - hole).length < reach + radius(b) + 2)) {
      return;
    }
    final b = StarBubble(reward, hole, Vec.zero);
    _eject(b);
    bodies.add(b);
    entryClock = config['star_reentry_interval'];
  }

  bool grab(Vec point) {
    for (final b in bodies.reversed) {
      if ((b.position - point).length <= radius(b) + 5) {
        held = b;
        grabOffset = b.position - point;
        b.velocity = Vec.zero;
        return true;
      }
    }
    return false;
  }

  void release(Vec velocity) {
    held?.velocity = velocity.limit(maximumSpeed);
    held = null;
  }

  void moveHeld(Vec target, double dt) {
    final b = held;
    if (b == null) return;
    final goal = target + grabOffset;
    b.velocity = ((goal - b.position) * (1 / dt)).limit(maximumSpeed);
    // Keep the attempted movement for the wall collision; clamping here would
    // erase the gesture's impact, making a held bubble impossible to break.
    b.position = b.position + b.velocity * dt;
  }

  bool impact(StarBubble b, Vec normal, double closing, Vec point) {
    if (closing < config['star_break_speed']) return false;
    if (!bodies.remove(b)) return false;
    if (held == b) held = null;
    broken.add(b.reward.id);
    breakSerial++;
    final flight = flights.where((f) => !f.active).firstOrNull;
    if (flight != null) {
      flight.active = true;
      flight.start = point;
      flight.category = b.reward.category;
      flight.age = 0;
    }
    return true;
  }

  void advanceVisuals(double dt) {
    for (final f in flights) {
      if (!f.active) continue;
      f.age += dt;
      if (f.age >= .85) f.active = false;
    }
  }

  void integrate(StarBubble b, double dt, Vec gravityImpulse) {
    if (b != held) {
      b.velocity =
          (b.velocity + Vec(0, -config['star_buoyancy'] * dt) + gravityImpulse)
              .limit(maximumSpeed) *
          math.exp(-config['star_damping'] * dt);
      b.position = b.position + b.velocity * dt;
    }
    b.holeCooldown = math.max(0, b.holeCooldown - dt);
    final r = radius(b);
    final p = b.position, v = b.velocity;
    final hitX = p.x < r && v.x < 0 || p.x > 360 - r && v.x > 0;
    final hitY = p.y < r && v.y < 0 || p.y > 560 - r && v.y > 0;
    // One conventional corner response, no stacked power or duplicate payment.
    final speed = math.max(hitX ? v.x.abs() : 0.0, hitY ? v.y.abs() : 0.0);
    if ((hitX || hitY) && impact(b, Vec.zero, speed, p.inside(r))) return;
    final bounce = config['star_restitution'];
    b.position = p.inside(r);
    b.velocity = Vec(
      hitX ? -v.x * bounce : v.x,
      hitY ? -v.y * bounce : v.y,
    ).limit(maximumSpeed);
    if (b != held &&
        b.holeCooldown == 0 &&
        (b.position - hole).length < r + 12) {
      _eject(b);
    }
  }

  Map<String, dynamic> toJson() => {
    'config': config.toJson(),
    'entryClock': entryClock,
    'bodies': bodies.map((b) => b.toJson(held: held == b)).toList(),
  };
  static StarBubbles restore(
    Map<String, dynamic> json,
    StarLedger ledger, {
    required double ballRadius,
    required double maximumSpeed,
    Vec hole = const Vec(180, 123.2),
  }) {
    final system = StarBubbles(
      StarConfig.fromJson(json['config'] as Map<String, dynamic>),
      ballRadius: ballRadius,
      maximumSpeed: maximumSpeed,
      hole: hole,
    )..sync(ledger);
    final clock = json['entryClock'];
    final rows = json['bodies'];
    if (clock is! num ||
        !clock.isFinite ||
        clock < 0 ||
        clock > 3 ||
        rows is! List ||
        rows.length > system.config['star_active_limit']) {
      throw const FormatException('Burbujas inválidas');
    }
    system.entryClock = clock.toDouble();
    final ids = <int>{};
    for (final row in rows) {
      final reward = ledger.pending.where((p) => p.id == row['id']).firstOrNull;
      final cd = row['cooldown'];
      if (reward == null ||
          !ids.add(reward.id) ||
          cd is! num ||
          !cd.isFinite ||
          cd < 0 ||
          cd > .8) {
        throw const FormatException('Burbuja sin recompensa pendiente');
      }
      final b = StarBubble(
        reward,
        Vec.fromJson(row['p']),
        Vec.fromJson(row['v']),
        holeCooldown: cd.toDouble(),
      );
      final r = system.radius(b);
      if ((b.position - b.position.inside(r)).length > 1e-5 ||
          b.velocity.length > maximumSpeed + 1e-5) {
        throw const FormatException('Física de burbuja inválida');
      }
      system.bodies.add(b);
    }
    return system;
  }
}
