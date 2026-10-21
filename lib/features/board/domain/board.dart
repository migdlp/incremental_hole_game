import 'dart:math' as math;
import '../../../core/vec.dart';
import '../../automation/domain/robot.dart';
import 'tool.dart';
import 'two_point_grip.dart';
import 'bat_impact.dart';
import 'coin_denomination.dart';
import 'capture_combo.dart';
import 'special_abilities.dart';
import 'gravity_event.dart';
import 'black_hole_event.dart';
import 'launcher.dart';
import 'wall_impact.dart';
import '../../upgrades/domain/catalog.dart';

class Ball {
  Ball(this.id, this.position, this.velocity, {this.golden = false});
  final int id;
  final bool golden;
  Vec position, velocity;
  Map<String, dynamic> toJson() => {
    'id': id,
    'p': position.toJson(),
    'v': velocity.toJson(),
    'golden': golden,
  };
}

class Coin {
  Coin(this.id, this.position, this.value, {this.landing = .2});
  final int id;
  Vec position;
  final int value;
  double landing;
  Map<String, dynamic> toJson() => {
    'id': id,
    'p': position.toJson(),
    'value': value,
    'landing': landing,
  };
}

class BoardEvents {
  const BoardEvents(
    this.captured,
    this.collected, {
    this.goldenCaptured = 0,
    this.rewards = const [],
  });
  final int captured, collected, goldenCaptured;
  final List<int> rewards;
}

class Board {
  Board(
    this.settings, {
    this.randomState = 42,
    this.tool = BallTool.hand,
    bool? combosEnabled,
    this.gravitySupported = false,
    bool forceGravity = false,
    int? gravitySeed,
    int? blackHoleSeed,
    int forcedBlackHoles = 0,
    Vec? launcherPosition,
    double? launcherAngle,
  }) : specials = SpecialAbilities(settings),
       combo = CaptureCombo(
         enabled:
             combosEnabled ??
             (settings.balanceVersion < 8 || settings['combo_unlocked'] > 0),
       ) {
    broomPosition = Vec(width - broomHalfWidth - 20, 100);
    gravity = GravityEvent(
      settings,
      seed: gravitySeed ?? randomState,
      available: gravitySupported,
      force: forceGravity,
    );
    blackHole = BlackHoleEvent(
      settings,
      seed: blackHoleSeed ?? randomState,
      forcedObjects: forcedBlackHoles,
    );
    launcher = Launcher(
      settings,
      position: launcherPosition,
      angle: launcherAngle,
      seed: randomState,
    );
  }
  static const width = 360.0, height = 560.0;
  static const hole = Vec(180, 50);
  static const generator = Vec(180, 480);
  final DaySettings settings;
  final CaptureCombo combo;
  final SpecialAbilities specials;
  late GravityEvent gravity;
  late BlackHoleEvent blackHole;
  late Launcher launcher;
  bool _holdingLauncher = false;
  bool get holdingLauncher => _toolGrip != null && _holdingLauncher;
  Vec _launcherVelocity = Vec.zero;
  double _launcherRotation = 0;
  int? _blackHoleTap;
  bool gravitySupported;
  Vec gravityTilt = Vec.zero;
  Vec broomGravityVelocity = Vec.zero, batGravityVelocity = Vec.zero;
  bool _gravityTap = false;
  bool get gravityObjectVisible =>
      gravitySupported && !coinOnly && gravity.hasObject;
  final _captureAllIds = <int>{};
  final wallImpacts = <WallImpact>[];
  static const maximumWallImpacts = 32;
  double get wallRestitution =>
      settings['wall_restitution'] > 0 ? settings['wall_restitution'] : .4;
  double get maximumSpeed =>
      settings['ball_speed_limit'] > 0 ? settings['ball_speed_limit'] : 380;

  void _wallImpact(WallSide wall, double coordinate, double speed) {
    if (wallRestitution <= 1 || speed < 1) return;
    if (wallImpacts.length == maximumWallImpacts) wallImpacts.removeAt(0);
    wallImpacts.add(
      WallImpact(wall, coordinate, (speed / maximumSpeed).clamp(0.0, 1.0)),
    );
  }

  void _bounceWalls(Ball ball) {
    final position = ball.position;
    var vx = ball.velocity.x, vy = ball.velocity.y;
    if (position.x <= radius && vx < 0) {
      _wallImpact(WallSide.left, position.y, -vx);
      vx = -vx * wallRestitution;
    } else if (position.x >= width - radius && vx > 0) {
      _wallImpact(WallSide.right, position.y, vx);
      vx = -vx * wallRestitution;
    }
    if (position.y <= radius && vy < 0) {
      _wallImpact(WallSide.top, position.x, -vy);
      vy = -vy * wallRestitution;
    } else if (position.y >= height - radius && vy > 0) {
      _wallImpact(WallSide.bottom, position.x, vy);
      vy = -vy * wallRestitution;
    }
    // Limit once after both normals: a corner never applies the multiplier twice
    // to the whole vector. Inward/stationary contacts only get position correction.
    ball.velocity = Vec(vx, vy).limit(maximumSpeed);
    ball.position = position.inside(radius);
  }

  bool activateSpecial(SpecialAbility ability) {
    if (coinOnly || (ability == SpecialAbility.captureAll && balls.isEmpty)) {
      return false;
    }
    if (!specials.activate(ability)) return false;
    if (ability == SpecialAbility.captureAll) {
      _captureAllIds.addAll(balls.map((ball) => ball.id));
    }
    return true;
  }

  final balls = <Ball>[];
  final coins = <Coin>[];
  // Only five denomination counters are queued if the visible-object cap fills.
  final _queuedCoins = <int, int>{};
  Map<int, int>? collectedCoins = <int, int>{};
  bool get canCollectCoins =>
      _heldBalls.isEmpty &&
      !holdingBat &&
      !holdingLauncher &&
      !_gravityTap &&
      _blackHoleTap == null;
  final robot = Robot();
  Vec? paddle, target;
  late Vec broomPosition;
  TwoPointGrip? _toolGrip;
  bool get holdingBroom =>
      _toolGrip != null && !_holdingLauncher && tool != BallTool.bat;
  bool get holdingBat =>
      _toolGrip != null && !_holdingLauncher && tool == BallTool.bat;
  bool get holdingPhysicalTool => _toolGrip != null;
  bool get hasSecondBroomPoint => _toolGrip?.second != null;
  List<Vec> get broomHandles =>
      segments.isEmpty ? const [] : [segments.first.a, segments.last.b];
  Vec batPosition = const Vec(80, 300);
  double batAngle = 0;
  bool get batUnlocked => settings['bat_power'] > 0;
  double get batHalfLength => settings['bat_half_length'];
  double get batThickness => settings['bat_thickness'];
  ToolSegment get batSegment {
    final axis = Vec(math.cos(batAngle), math.sin(batAngle)) * batHalfLength;
    return ToolSegment(batPosition - axis, batPosition + axis);
  }

  Vec _boundBat(Vec center, double angle) {
    final x = math.cos(angle).abs() * batHalfLength + batThickness;
    final y = math.sin(angle).abs() * batHalfLength + batThickness;
    return Vec(center.x.clamp(x, width - x), center.y.clamp(y, height - y));
  }

  List<Vec> get batHandles => [batSegment.a, batSegment.b];
  final batImpacts = <BatImpact>[];
  final _batContacts = <int>{};
  int batImpactSerial = 0;
  double lastBatImpactStrength = 0;
  Vec _batVelocity = Vec.zero;
  double _batRotation = 0;

  Vec get _grippedCenter => holdingLauncher
      ? launcher.position
      : holdingBat
      ? batPosition
      : broomPosition;
  double get _grippedAngle => holdingLauncher
      ? launcher.angle
      : holdingBat
      ? batAngle
      : toolAngle;
  bool _onBroom(Vec point, double tolerance) =>
      segments.any(
        (segment) => (segment.closest(point) - point).length <= tolerance,
      ) ||
      broomHandles.any((handle) => (handle - point).length <= 22);
  bool _onBat(Vec point, double tolerance) =>
      batUnlocked && (batSegment.closest(point) - point).length <= tolerance;

  // Keep the established input entry points; both tools use TwoPointGrip.
  bool grabSecondBroomPoint(Vec point) {
    if (coinOnly ||
        !holdingPhysicalTool ||
        target == null ||
        hasSecondBroomPoint ||
        !(holdingLauncher
            ? launcher.contains(point, extra: 22)
            : holdingBat
            ? _onBat(point, 22)
            : _onBroom(point, 22)) ||
        (point - target!).length < 18) {
      return false;
    }
    _toolGrip!.addSecond(point, target!, _grippedCenter, _grippedAngle);
    return true;
  }

  void dragSecondBroomPoint(Vec point) {
    if (hasSecondBroomPoint) _toolGrip!.second = point.inside(0);
  }

  void releaseSecondBroomPoint() {
    if (_toolGrip != null && target != null) {
      _toolGrip!.releaseSecond(target!, _grippedCenter, _grippedAngle);
    }
  }

  void promoteSecondBroomPoint() {
    final point = _toolGrip?.second;
    if (point == null) return;
    paddle = target = point;
    _downPoint = point;
    _samples.clear();
    releaseSecondBroomPoint();
  }

  bool coinOnly = false;
  BallTool get broomTool =>
      settings['v_unlocked'] > 0 ? BallTool.vee : BallTool.broom;

  void enterClosing() {
    releasePointer(cancel: true);
    coinOnly = true;
    gravity.finish();
    blackHole.endProduction();
    launcher.freeze();
    broomGravityVelocity = batGravityVelocity = Vec.zero;
    combo.end();
  }

  BallTool tool;
  final _heldBalls = <Ball, Vec>{};
  Ball? _manualBall;
  final _slippedBalls = <Ball>{};
  // Logical units and seconds: a soft, damped tether for extra balls.
  static const _gripStiffness = 80.0;
  static const _gripDamping = 14.0;
  static const _gripAcceleration = 900.0;
  static const _gripBreakDistance = 72.0;
  Ball? get heldBall => _heldBalls.keys.firstOrNull;
  List<Ball> get heldBalls => List.unmodifiable(_heldBalls.keys);
  int get handCapacity => math.max(1, settings['hand_capacity'].toInt());
  double get ballMagnetRadius => radius * 2 + 24;
  double get gripStrength => math.max(1, settings['hand_grip_strength']);
  bool get broomUnlocked => settings['broom_unlocked'] > 0;
  Vec _grabOffset = Vec.zero;
  Vec? _downPoint;
  bool _dragged = false, _heldDuringGesture = false;
  double _clock = 0;
  final _samples = <({double time, Vec point})>[];
  double toolAngle = math.pi / 2;
  static const broomThickness = 3.5;
  double get broomHalfWidth => settings['paddle_radius'] * 2;
  bool get sweepEnabled => settings['coin_sweep'] > 0;
  List<ToolSegment> get segments => broomUnlocked
      ? broomSegments(broomTool, broomPosition, toolAngle, broomHalfWidth)
      : const [];

  bool canUse(BallTool value) => switch (value) {
    BallTool.hand => true,
    BallTool.broom => broomUnlocked,
    BallTool.vee => settings['v_unlocked'] > 0,
    BallTool.bat => batUnlocked,
  };

  void selectTool(BallTool value) {
    if (!canUse(value)) return;
    releasePointer(cancel: true);
    tool = value;
  }

  int nextId = 1;
  int randomState;
  int captured = 0;
  int spawned = 0;
  int goldenCaptured = 0;
  double spawnClock = 0;
  double get radius => settings['ball_radius'];
  int get pending =>
      coins.fold(0, (sum, coin) => sum + coin.value) +
      _queuedCoins.entries.fold(
        0,
        (sum, entry) => sum + entry.key * entry.value,
      );
  double random() {
    randomState = (1664525 * randomState + 1013904223) & 0xffffffff;
    return randomState / 4294967296;
  }

  int releasePointer({bool cancel = false, double? time}) {
    var collected = 0;
    final velocity = cancel ? Vec.zero : _releaseVelocity(time ?? _clock);
    if (_gravityTap &&
        !cancel &&
        !_dragged &&
        target != null &&
        gravityObjectVisible &&
        gravity.contains(target!)) {
      gravity.hit(available: gravitySupported);
    }
    final tapped = _blackHoleTap;
    if (tapped != null && !cancel && !_dragged && !coinOnly && target != null) {
      final object = blackHole.objects.where((o) => o.id == tapped).firstOrNull;
      if (object != null && object.contains(target!)) blackHole.hit(tapped);
    }
    for (final ball in _heldBalls.keys) {
      ball.velocity = cancel
          ? Vec.zero
          : ball == _manualBall
          ? velocity
          : ball.velocity.limit(maximumSpeed);
    }
    if (!cancel && !_dragged && !_heldDuringGesture && _downPoint != null) {
      collected = _collect(_downPoint!, _downPoint!);
    }
    _heldBalls.clear();
    _manualBall = null;
    _slippedBalls.clear();
    _toolGrip = null;
    _holdingLauncher = false;
    _gravityTap = false;
    _blackHoleTap = null;
    paddle = null;
    target = null;
    _downPoint = null;
    _samples.clear();
    return collected;
  }

  Vec _releaseVelocity(double time) {
    if (_samples.length < 2) return Vec.zero;
    _sample(target!, time);
    final end = _samples.last;
    final cutoff = end.time - .08;
    var start = _samples.first;
    for (var i = 1; i < _samples.length; i++) {
      final next = _samples[i];
      if (next.time >= cutoff) {
        if (start.time < cutoff && next.time > start.time) {
          final t = (cutoff - start.time) / (next.time - start.time);
          start = (
            time: cutoff,
            point: start.point + (next.point - start.point) * t,
          );
        }
        break;
      }
      start = next;
    }
    final elapsed = end.time - start.time;
    if (elapsed < .008) return Vec.zero;
    final velocity = (end.point - start.point) * (1 / elapsed);
    return velocity.length < 18 ? Vec.zero : velocity.limit(maximumSpeed);
  }

  void _sample(Vec point, double time) {
    if (!time.isFinite) return;
    if (_samples.isNotEmpty && time <= _samples.last.time) return;
    _samples.add((time: time, point: point));
    while (_samples.length > 2 && _samples[1].time < time - .15) {
      _samples.removeAt(0);
    }
  }

  int touch(Vec point, {double? time}) {
    if (target != null) return 0;
    paddle = point.inside(0);
    target = paddle;
    _downPoint = paddle;
    _dragged = false;
    _heldDuringGesture = false;
    _samples.clear();
    _sample(paddle!, time ?? _clock);
    _blackHoleTap = null;
    _gravityTap = gravityObjectVisible && gravity.contains(paddle!);
    if (_gravityTap) {
      _heldDuringGesture = true;
      return 0;
    }
    _blackHoleTap = !coinOnly && !blackHole.ended
        ? blackHole.objectAt(paddle!)?.id
        : null;
    if (_blackHoleTap != null) {
      _heldDuringGesture = true;
      return 0;
    }
    final onCoin = coins.any(
      (c) => c.landing <= 0 && (c.position - paddle!).length <= 12,
    );
    final grabLauncher = !coinOnly && !onCoin && launcher.contains(paddle!);
    final handle =
        broomPosition - Vec(math.cos(toolAngle), math.sin(toolAngle)) * 21;
    final grabBat =
        !coinOnly &&
        !grabLauncher &&
        _onBat(paddle!, batThickness + 8) &&
        (tool == BallTool.bat || !_onBroom(paddle!, 12));
    final grabBroom =
        !coinOnly &&
        broomUnlocked &&
        !grabLauncher &&
        !grabBat &&
        !onCoin &&
        (_onBroom(paddle!, 12) ||
            segmentDistance(paddle!, broomPosition, handle) <= 12);
    tool = grabBat
        ? BallTool.bat
        : grabBroom
        ? broomTool
        : BallTool.hand;
    if (grabLauncher || grabBat || grabBroom) {
      _holdingLauncher = grabLauncher;
      _toolGrip = TwoPointGrip(
        grabLauncher
            ? launcher.position
            : grabBat
            ? batPosition
            : broomPosition,
        grabLauncher
            ? launcher.angle
            : grabBat
            ? batAngle
            : toolAngle,
        paddle!,
      );
      if (grabLauncher) launcher.freeze();
      if (grabBat) batGravityVelocity = Vec.zero;
      if (grabBroom) broomGravityVelocity = Vec.zero;
      _heldDuringGesture = true;
    }
    if (!coinOnly && !holdingPhysicalTool && !onCoin) {
      Ball? nearest;
      var distance = radius + 12;
      for (final ball in balls) {
        final d = (ball.position - paddle!).length;
        if (d < distance) {
          nearest = ball;
          distance = d;
        }
      }
      if (nearest != null) {
        _grabOffset = nearest.position - paddle!;
        _manualBall = nearest;
        _heldBalls[nearest] = _grabOffset;
        nearest.velocity = Vec.zero;
        _heldDuringGesture = true;
      }
    }
    return sweepEnabled ? _collect(paddle!, paddle!) : 0;
  }

  int drag(Vec point, {double? time}) {
    if (target == null) return 0;
    final destination = point.inside(0);
    if ((destination - _downPoint!).length > 8) _dragged = true;
    final amount = sweepEnabled ? _collect(target!, destination) : 0;
    target = destination;
    // Closing still tracks the coin-collection cursor, not physical objects.
    if (coinOnly) paddle = destination;
    _sample(destination, time ?? _clock);
    return amount;
  }

  int _collect(Vec a, Vec b) {
    if (!canCollectCoins) return 0;
    var amount = 0;
    coins.removeWhere((coin) {
      if (coin.landing > 0 ||
          segmentDistance(coin.position, a, b) >
              settings['collection_radius']) {
        return false;
      }
      amount += coin.value;
      final counts = collectedCoins;
      if (counts != null) {
        for (final stack in CoinDenomination.split(coin.value)) {
          counts.update(
            stack.denomination.amount,
            (n) => n + stack.count,
            ifAbsent: () => stack.count,
          );
        }
      }
      return true;
    });
    return amount;
  }

  void releaseCoin(int value) {
    if (value <= 0) throw ArgumentError.value(value, 'value');
    for (final stack in CoinDenomination.split(value)) {
      _queuedCoins.update(
        stack.denomination.amount,
        (n) => n + stack.count,
        ifAbsent: () => stack.count,
      );
    }
    _flushCoins();
  }

  void _flushCoins() {
    for (final denomination in CoinDenomination.values.reversed) {
      final value = denomination.amount;
      var count = _queuedCoins[value] ?? 0;
      while (count > 0 && coins.length < settings['coin_pile_limit']) {
        // Coins never merge: each visible coin pays exactly its color's value.
        var point = hole;
        for (var attempt = 0; attempt < 6; attempt++) {
          final angle = random() * math.pi * 2;
          final distance = 40 + random() * (36 + attempt * 20);
          point = (hole + Vec(math.cos(angle), math.sin(angle)) * distance)
              .inside(14);
          if (coins.every((coin) => (coin.position - point).length >= 22)) {
            break;
          }
        }
        coins.add(Coin(nextId++, point, value));
        count--;
      }
      if (count == 0) {
        _queuedCoins.remove(value);
      } else {
        _queuedCoins[value] = count;
      }
    }
  }

  BoardEvents update(double dt, {required bool producing}) {
    var collected = 0;
    for (final impact in batImpacts) {
      impact.age += dt;
    }
    batImpacts.removeWhere((impact) => impact.age >= BatImpact.lifetime);
    for (final impact in wallImpacts) {
      impact.age += dt;
    }
    wallImpacts.removeWhere((impact) => impact.age >= WallImpact.lifetime);
    _flushCoins();
    for (final coin in coins) {
      coin.landing = math.max(0, coin.landing - dt);
    }
    if (producing && !coinOnly) {
      final acceleratedTime = math.min(dt, specials.boostRemaining);
      spawnClock += dt + acceleratedTime * (specials.generationMultiplier - 1);
      specials.advance(dt);
      while (spawnClock + 1e-9 >= settings['spawn_interval']) {
        spawnClock = math.max(0, spawnClock - settings['spawn_interval']);
        final count = math.max(1, settings['balls_per_spawn'].toInt());
        final center = generator + Vec((random() - .5) * 42, -30);
        for (var index = 0; index < count; index++) {
          final spawn =
              center + Vec((index - (count - 1) / 2) * (radius * 2.4), 0);
          if (balls.length < settings['ball_limit'] &&
              launcher.contact(spawn, radius) == null &&
              balls.every((b) => (b.position - spawn).length > radius * 2.2)) {
            spawned++;
            balls.add(
              Ball(
                nextId++,
                spawn,
                Vec((random() - .5) * 36, -85),
                golden: random() < .01,
              ),
            );
          }
        }
      }
    }
    if (paddle != null && target != null) {
      final start = paddle!;
      if (canCollectCoins && settings['magnet_radius'] > 0) {
        for (final coin in coins) {
          if (coin.landing <= 0 &&
              (coin.position - start).length <= settings['magnet_radius']) {
            coin.position =
                coin.position + (start - coin.position).limit(140 * dt);
          }
        }
        collected += _collect(start, start);
      }
    }
    if (coinOnly) return BoardEvents(0, collected);
    combo.advance(dt);
    if (settings['robot_count'] > 0) {
      final goal = robot.direction(dt, [
        for (final ball in balls) (id: ball.id, position: ball.position),
      ], hole);
      if (goal != null) {
        final movement = (goal - robot.position).limit(
          settings['robot_speed'] * dt,
        );
        robot.position = (robot.position + movement).inside(18);
        _push(robot.position, 15, movement * (1 / dt), 2);
      }
    }
    final sweptCaptures = <int>{};
    var captures = 0, goldenCaptures = 0;
    final rewards = <int>[];
    void captureBalls() {
      balls.removeWhere((ball) {
        if (!_captureAllIds.contains(ball.id) &&
            !sweptCaptures.contains(ball.id) &&
            (ball.position - hole).length > settings['hole_capture_radius']) {
          return false;
        }
        _heldBalls.remove(ball);
        if (ball == _manualBall) _manualBall = null;
        _slippedBalls.remove(ball);
        captures++;
        if (ball.golden) goldenCaptures++;
        rewards.add(
          settings['ball_value'].toInt() * combo.capture(golden: ball.golden),
        );
        return true;
      });
    }

    // Small steps bound translation and rotating tips below a ball diameter.
    final steps = math.max(1, (dt / (1 / 240)).ceil());
    final step = dt / steps;
    for (var i = 0; i < steps; i++) {
      final gravityImpulse = gravity.advance(
        step,
        producing: producing,
        available: gravitySupported,
        tilt: gravityTilt,
      );
      blackHole.advance(step, producing: producing);
      _moveTool(step);
      _advanceLauncher(step, producing: producing);
      _moveGravityTools(step, gravityImpulse);
      final friction = math.exp(
        -1.6 * step -
            settings['gravity_ball_damping'] *
                (gravitySupported ? gravity.lastActiveTime : 0),
      );
      for (final ball in balls) {
        if (_heldBalls.containsKey(ball)) continue;
        ball.velocity = ball.velocity + gravityImpulse;
        final toHole = hole - ball.position;
        final baseAttraction =
            toHole.length < settings['hole_capture_radius'] + 15 ? 220.0 : 0.0;
        final expandedAttraction = blackHole.lastActiveTime > 0
            ? blackHole.accelerationAt(toHole.length)
            : 0.0;
        final suctionImpulse =
            baseAttraction * step +
            math.max(0.0, expandedAttraction - baseAttraction) *
                blackHole.lastActiveTime;
        if (suctionImpulse > 0) {
          ball.velocity = ball.velocity + toHole.unit * suctionImpulse;
        }
        ball.velocity = ball.velocity.limit(maximumSpeed) * friction;
        if (ball.velocity.length < 1 &&
            gravityImpulse.length == 0 &&
            expandedAttraction <= baseAttraction) {
          ball.velocity = Vec.zero;
        }
        final previous = ball.position;
        ball.position = ball.position + ball.velocity * step;
        _bounceWalls(ball);
        if (segmentDistance(hole, previous, ball.position) <=
            settings['hole_capture_radius']) {
          sweptCaptures.add(ball.id);
        }
      }
      captureBalls();
      _collide();
      _contactBroom(Vec.zero, 0);
      _contactBat();
      _contactLauncher(step);
      captureBalls();
      sweptCaptures.clear();
    }
    _clock += dt;
    _captureAllIds.clear();
    captured += captures;
    goldenCaptured += goldenCaptures;
    return BoardEvents(
      captures,
      collected,
      goldenCaptured: goldenCaptures,
      rewards: rewards,
    );
  }

  void _moveGravityTools(double dt, Vec impulse) {
    if (settings.balanceVersion < 11) return;
    final damping = math.exp(-settings['gravity_tool_damping'] * dt);
    ({Vec center, Vec velocity}) freeMotion(
      Vec center,
      Vec velocity,
      Vec Function(Vec) bound,
    ) {
      velocity = (velocity + impulse).limit(maximumSpeed) * damping;
      if (velocity.length < .01) velocity = Vec.zero;
      final next = center + velocity * dt;
      final position = bound(next);
      return (
        center: position,
        velocity: Vec(
          position.x != next.x ? -velocity.x * .35 : velocity.x,
          position.y != next.y ? -velocity.y * .35 : velocity.y,
        ),
      );
    }

    if (broomUnlocked &&
        !holdingBroom &&
        (impulse.length > 0 || broomGravityVelocity.length > 0)) {
      final before = broomPosition;
      final motion = freeMotion(
        before,
        broomGravityVelocity,
        (p) => p.inside(broomHalfWidth + broomThickness),
      );
      broomPosition = motion.center;
      broomGravityVelocity = motion.velocity;
      _contactBroom((broomPosition - before) * (1 / dt), 0);
    }
    if (batUnlocked &&
        !holdingBat &&
        (impulse.length > 0 || batGravityVelocity.length > 0)) {
      final before = batPosition;
      final motion = freeMotion(
        before,
        batGravityVelocity,
        (p) => _boundBat(p, batAngle),
      );
      batPosition = motion.center;
      batGravityVelocity = motion.velocity;
      _batVelocity = (batPosition - before) * (1 / dt);
    }
  }

  void _moveTool(double dt) {
    _batVelocity = Vec.zero;
    _batRotation = 0;
    _launcherVelocity = Vec.zero;
    _launcherRotation = 0;
    if (paddle == null || target == null) return;
    final start = paddle!;
    paddle = start + (target! - start).limit(900 * dt);
    if (_heldBalls.isNotEmpty && !holdingPhysicalTool) {
      // The first grip is manual. Only an existing grip can attract neighbours.
      while (_heldBalls.length < handCapacity) {
        Ball? nearest;
        var distance = ballMagnetRadius;
        for (final ball in balls) {
          if (_heldBalls.containsKey(ball) || _slippedBalls.contains(ball)) {
            continue;
          }
          final d = (ball.position - heldBall!.position).length;
          if (d < distance) {
            nearest = ball;
            distance = d;
          }
        }
        if (nearest == null) break;
        _heldBalls[nearest] = _nextGripOffset();
      }
      if (_manualBall case final Ball ball) {
        final goal = (target! + _grabOffset).inside(radius);
        final previous = ball.position;
        ball.position = previous + (goal - previous).limit(maximumSpeed * dt);
        ball.velocity = ((ball.position - previous) * (1 / dt)).limit(
          maximumSpeed,
        );
      }
      final anchor = _manualBall == null
          ? paddle!
          : _manualBall!.position - _grabOffset;
      final slipped = <Ball>[];
      for (final entry in _heldBalls.entries) {
        final ball = entry.key;
        if (ball == _manualBall) continue;
        final goal = (anchor + entry.value).inside(radius);
        final stretch = goal - ball.position;
        if (stretch.length >
            _gripBreakDistance * (1 + .2 * (gripStrength - 1))) {
          slipped.add(ball);
          continue;
        }
        final acceleration =
            (stretch * (_gripStiffness * gripStrength) -
                    ball.velocity * (_gripDamping * math.sqrt(gripStrength)))
                .limit(_gripAcceleration * gripStrength);
        ball.velocity = (ball.velocity + acceleration * dt).limit(maximumSpeed);
        final next = ball.position + ball.velocity * dt;
        ball.position = next.inside(radius);
        if (ball.position.x != next.x) ball.velocity = Vec(0, ball.velocity.y);
        if (ball.position.y != next.y) ball.velocity = Vec(ball.velocity.x, 0);
      }
      for (final ball in slipped) {
        _heldBalls.remove(ball);
        // A broken tether must not immediately reattach during this gesture.
        _slippedBalls.add(ball);
      }
    }
    if (!holdingPhysicalTool) return;
    if (holdingLauncher) {
      final desired = _toolGrip!.move(
        target!,
        launcher.position,
        launcher.angle,
        dt,
        margin: 0,
        speed: settings['launcher_move_speed'],
        angularSpeed: settings['launcher_angular_speed'],
      );
      final previous = launcher.position;
      launcher.move(desired.center, desired.angle);
      _launcherVelocity = (launcher.position - previous) * (1 / dt);
      _launcherRotation = desired.angularVelocity;
      return;
    }
    final pose = _toolGrip!.move(
      target!,
      _grippedCenter,
      _grippedAngle,
      dt,
      margin: holdingBat
          ? batHalfLength + batThickness
          : broomHalfWidth + broomThickness,
      speed: holdingBat ? settings['bat_move_speed'] : 900,
      angularSpeed: holdingBat ? settings['bat_angular_speed'] : 3,
      symmetric: holdingBroom && broomTool == BallTool.broom,
      constrain: holdingBat ? _boundBat : null,
    );
    if (holdingBat) {
      batPosition = pose.center;
      batAngle = pose.angle;
      _batVelocity = pose.velocity;
      _batRotation = pose.angularVelocity;
    } else {
      broomPosition = pose.center;
      toolAngle = pose.angle;
      _contactBroom(pose.velocity, pose.angularVelocity);
    }
  }

  void _advanceLauncher(double dt, {required bool producing}) {
    if (!launcher.unlocked) return;
    launcher.flash = math.max(0.0, launcher.flash - dt);
    launcher.boundaryFlash = math.max(0.0, launcher.boundaryFlash - dt);
    if (!producing) return;
    launcher.clock += dt;
    while (launcher.clock + 1e-9 >= launcher.interval) {
      launcher.clock = math.max(0.0, launcher.clock - launcher.interval);
      launcher.attempts++;
      if (balls.length >= settings['ball_limit']) continue;
      final exit =
          launcher.muzzle +
          launcher.axis * (launcher.barrelRadius + radius + .5);
      if ((exit - exit.inside(radius)).length > 1e-6 ||
          launcher.contact(exit, radius) != null ||
          segments.any(
            (s) =>
                (s.closest(exit) - exit).length < radius + broomThickness ||
                (s.closest(launcher.muzzle) - launcher.muzzle).length <
                    radius + broomThickness ||
                segmentDistance(s.a, launcher.muzzle, exit) <
                    radius + broomThickness ||
                segmentDistance(s.b, launcher.muzzle, exit) <
                    radius + broomThickness,
          ) ||
          (batUnlocked &&
              ((batSegment.closest(exit) - exit).length <
                      radius + batThickness ||
                  (batSegment.closest(launcher.muzzle) - launcher.muzzle)
                          .length <
                      radius + batThickness ||
                  segmentDistance(batSegment.a, launcher.muzzle, exit) <
                      radius + batThickness ||
                  segmentDistance(batSegment.b, launcher.muzzle, exit) <
                      radius + batThickness))) {
        continue;
      }
      final blockers = balls
          .where(
            (b) =>
                segmentDistance(b.position, launcher.muzzle, exit) <
                radius * 2 + .1,
          )
          .toList();
      if (blockers.isNotEmpty) {
        for (final ball in blockers) {
          if (!_heldBalls.containsKey(ball)) {
            ball.velocity =
                (ball.velocity +
                        launcher.axis * settings['launcher_obstruction_force'])
                    .limit(maximumSpeed);
          }
        }
        continue; // Consume the attempt; never queue a delayed volley.
      }
      balls.add(
        Ball(
          nextId++,
          exit,
          launcher.axis * math.min(maximumSpeed, launcher.speed),
          golden: launcher.random() < .01,
        ),
      );
      spawned++;
      launcher.shots++;
      launcher.flash = .15;
    }
  }

  void _contactLauncher(double dt) {
    if (!launcher.unlocked) return;
    var pressure = Vec.zero;
    for (final ball in balls) {
      if (_heldBalls.containsKey(ball)) continue;
      final contact = launcher.contact(ball.position, radius);
      if (contact == null) continue;
      final arm = contact.point - launcher.position;
      final surface = holdingLauncher
          ? _launcherVelocity + Vec(-arm.y, arm.x) * _launcherRotation
          : launcher.velocity;
      final relative = surface - ball.velocity;
      final closing = math.max(
        0.0,
        relative.x * contact.normal.x + relative.y * contact.normal.y,
      );
      // Saturation models finite transmitted stress and guarantees <=3 impacts
      // cannot defeat static resistance, regardless of their incoming speed.
      final stress = math.min(
        settings['launcher_contact_pressure_limit'],
        contact.depth * settings['launcher_pressure_stiffness'] + closing,
      );
      pressure = pressure - contact.normal * stress;
      ball.position = (ball.position + contact.normal * (contact.depth + .01))
          .inside(radius);
      if (closing > 0) {
        ball.velocity =
            (ball.velocity +
                    contact.normal *
                        (closing * (1 + settings['launcher_restitution'])))
                .limit(maximumSpeed);
      }
      _bounceWalls(ball);
    }
    launcher.applyPressure(pressure, dt, held: holdingLauncher);
  }

  void _contactBat() {
    if (!batUnlocked) return;
    final segment = batSegment;
    final touching = <int>{};
    for (final ball in balls) {
      if (_heldBalls.containsKey(ball)) continue;
      final contact = segment.closest(ball.position);
      final delta = ball.position - contact;
      final reach = radius + batThickness;
      if (delta.length > reach + .75) continue;
      if (_batContacts.contains(ball.id)) touching.add(ball.id);
      if (delta.length >= reach) continue;
      final arm = contact - batPosition;
      final surface = _batVelocity + Vec(-arm.y, arm.x) * _batRotation;
      // At an exact overlap use the approach direction, never an arbitrary boost.
      final normal = delta.length > .0001
          ? delta.unit
          : (surface - ball.velocity).length > .0001
          ? (surface - ball.velocity).unit
          : Vec(-math.sin(batAngle), math.cos(batAngle));
      final surfaceNormal = surface.x * normal.x + surface.y * normal.y;
      final closing =
          surfaceNormal -
          (ball.velocity.x * normal.x + ball.velocity.y * normal.y);
      ball.position = (ball.position + normal * (reach - delta.length + .01))
          .inside(radius);
      if (closing <= .001) continue;
      touching.add(ball.id);
      final newImpact = !_batContacts.contains(ball.id);
      final bonus = newImpact
          ? math.max(0.0, surfaceNormal) *
                settings['bat_manual_gain'] *
                settings['bat_power']
          : 0.0;
      final impulse =
          closing * (newImpact ? 1 + settings['bat_restitution'] : 1) + bonus;
      ball.velocity = (ball.velocity + normal * impulse).limit(maximumSpeed);
      _bounceWalls(ball);
      if (newImpact && closing >= 8) {
        final strength = (impulse / maximumSpeed).clamp(0.0, 1.0);
        if (batImpacts.length >= 24) batImpacts.removeAt(0);
        batImpacts.add(BatImpact(contact, strength));
        batImpactSerial++;
        lastBatImpactStrength = strength;
      }
    }
    _batContacts
      ..clear()
      ..addAll(touching);
  }

  Vec _nextGripOffset() {
    if (_manualBall == null &&
        _heldBalls.values.every((used) => (used - _grabOffset).length > .1)) {
      return _grabOffset;
    }
    final satellites = handCapacity - 1;
    final spacing = math.max(
      radius * 2 + 2,
      (radius + 1) / math.sin(math.pi / math.max(2, satellites)),
    );
    for (var slot = 0; slot < satellites; slot++) {
      final angle = slot * math.pi * 2 / satellites;
      final offset =
          _grabOffset + Vec(math.cos(angle), math.sin(angle)) * spacing;
      if (_heldBalls.values.every((used) => (used - offset).length > .1)) {
        return offset;
      }
    }
    throw StateError('No free hand slot');
  }

  void _contactBroom(Vec velocity, double rotation) {
    for (final segment in segments) {
      for (final ball in balls) {
        if (_heldBalls.containsKey(ball)) continue;
        final contact = segment.closest(ball.position);
        final difference = ball.position - contact;
        final overlap = radius + broomThickness - difference.length;
        if (overlap <= 0) continue;
        final normal = difference.length < .0001
            ? Vec(math.cos(toolAngle), math.sin(toolAngle))
            : difference.unit;
        ball.position = (ball.position + normal * overlap).inside(radius);
        final arm = contact - broomPosition;
        final rotating = Vec(-arm.y, arm.x) * rotation;
        final surface = (velocity + rotating.limit(80)).limit(maximumSpeed);
        final relative = surface - ball.velocity;
        final impulse = relative.x * normal.x + relative.y * normal.y;
        if (impulse > 0) {
          ball.velocity = (ball.velocity + normal * impulse).limit(
            maximumSpeed,
          );
        }
      }
    }
  }

  void _push(Vec point, double size, Vec velocity, double correction) {
    for (final ball in balls) {
      if (_heldBalls.containsKey(ball)) continue;
      final difference = ball.position - point;
      final overlap = size + radius - difference.length;
      if (overlap <= 0) continue;
      final normal = difference.unit;
      ball.position = (ball.position + normal * math.min(overlap, correction))
          .inside(radius);
      final projected = math.max(
        0.0,
        velocity.x * normal.x + velocity.y * normal.y,
      );
      ball.velocity = (ball.velocity + normal * (projected * .7 + 18)).limit(
        maximumSpeed,
      );
    }
  }

  void _collide() {
    const cell = 20.0;
    final grid = <(int, int), List<Ball>>{};
    for (final ball in balls) {
      final key = (
        (ball.position.x / cell).floor(),
        (ball.position.y / cell).floor(),
      );
      grid.putIfAbsent(key, () => []).add(ball);
    }
    for (final ball in balls) {
      final x = (ball.position.x / cell).floor(),
          y = (ball.position.y / cell).floor();
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          for (final other in grid[(x + dx, y + dy)] ?? <Ball>[]) {
            if (ball.id >= other.id) continue;
            final difference = other.position - ball.position;
            final overlap = radius * 2 - difference.length;
            if (overlap <= 0) continue;
            final n = difference.unit;
            final heldA = _heldBalls.containsKey(ball),
                heldB = _heldBalls.containsKey(other);
            if (heldA && heldB) continue;
            final distance = overlap + .01;
            if (!heldA) {
              ball.position =
                  (ball.position - n * (heldB ? distance : distance * .5))
                      .inside(radius);
            }
            if (!heldB) {
              other.position =
                  (other.position + n * (heldA ? distance : distance * .5))
                      .inside(radius);
            }
            final relative = ball.velocity - other.velocity;
            final impulse =
                math.max(0.0, relative.x * n.x + relative.y * n.y) * .65;
            if (!heldA) {
              ball.velocity = (ball.velocity - n * impulse * (heldB ? 2 : 1))
                  .limit(maximumSpeed);
            }
            if (!heldB) {
              other.velocity = (other.velocity + n * impulse * (heldA ? 2 : 1))
                  .limit(maximumSpeed);
            }
          }
        }
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'random': randomState,
    'nextId': nextId,
    'captured': captured,
    'goldenCaptured': goldenCaptured,
    'combo': combo.toJson(),
    if (settings.balanceVersion >= 8) ...{
      'specials': specials.toJson(),
      'captureAllIds': _captureAllIds.toList(),
    },
    'spawnClock': spawnClock,
    if (settings.balanceVersion >= 12) 'blackHole': blackHole.toJson(),
    if (settings.balanceVersion >= 13) 'launcher': launcher.toJson(),
    if (settings.balanceVersion >= 11) ...{
      'gravity': gravity.toJson(),
      'broomGravityVelocity': broomGravityVelocity.toJson(),
      'batGravityVelocity': batGravityVelocity.toJson(),
    },
    'broomPosition': broomPosition.toJson(),
    'broomAngle': toolAngle,
    if (settings.balanceVersion >= 10) ...{
      'batPosition': batPosition.toJson(),
      'batAngle': batAngle,
    },
    'balls': balls
        .map(
          (b) => _heldBalls.containsKey(b)
              ? (b.toJson()..['v'] = Vec.zero.toJson())
              : b.toJson(),
        )
        .toList(),
    'coins': coins.map((c) => c.toJson()).toList(),
    'queuedCoins': _queuedCoins.map((key, value) => MapEntry('$key', value)),
    'collectedCoins': collectedCoins?.map(
      (key, value) => MapEntry('$key', value),
    ),
    'robot': robot.position.toJson(),
    'robotTarget': robot.targetId,
  };

  factory Board.fromJson(DaySettings settings, Map<String, dynamic> json) {
    final goldenCaptured = json['goldenCaptured'] ?? 0;
    if (goldenCaptured is! int) {
      throw const FormatException('Capturas doradas inválidas');
    }
    final combo = json['combo'] == null
        ? CaptureCombo(enabled: false)
        : CaptureCombo.fromJson(
            json['combo'] as Map<String, dynamic>,
            captured: json['captured'] as int,
            goldenCaptured: goldenCaptured,
          );
    final board = Board(
      settings,
      randomState: json['random'] as int,
      combosEnabled: combo.enabled,
    );
    board.combo
      ..streak = combo.streak
      ..remaining = combo.remaining
      ..bonusUnits = combo.bonusUnits;
    if (json.containsKey('broomPosition')) {
      board.broomPosition = Vec.fromJson(json['broomPosition']);
    }
    if (json.containsKey('broomAngle')) {
      final angle = json['broomAngle'];
      if (angle is! num || !angle.isFinite) {
        throw const FormatException('Invalid broom angle');
      }
      board.toolAngle = angle.toDouble() % (2 * math.pi);
    }
    if (settings.balanceVersion >= 10) {
      board.batPosition = Vec.fromJson(json['batPosition']);
      final angle = json['batAngle'];
      if (angle is! num || !angle.isFinite) {
        throw const FormatException('Invalid bat angle');
      }
      board.batAngle = angle.toDouble() % (2 * math.pi);
      final bounded = board._boundBat(board.batPosition, board.batAngle);
      if ((bounded - board.batPosition).length > .0001) {
        throw const FormatException('Invalid bat position');
      }
    }
    if (settings.balanceVersion >= 11) {
      final savedGravity = json['gravity'];
      if (savedGravity is! Map<String, dynamic>) {
        throw const FormatException('Falta el estado de Gravedad');
      }
      board.gravity = GravityEvent.fromJson(settings, savedGravity);
      board.broomGravityVelocity = Vec.fromJson(json['broomGravityVelocity']);
      board.batGravityVelocity = Vec.fromJson(json['batGravityVelocity']);
      if (board.broomGravityVelocity.length > board.maximumSpeed + 1e-6 ||
          board.batGravityVelocity.length > board.maximumSpeed + 1e-6 ||
          (!board.broomUnlocked && board.broomGravityVelocity.length > 0) ||
          (!board.batUnlocked && board.batGravityVelocity.length > 0)) {
        throw const FormatException('Velocidad de herramienta inválida');
      }
    }
    if (settings.balanceVersion >= 12) {
      final saved = json['blackHole'];
      if (saved is! Map<String, dynamic>) {
        throw const FormatException('Falta Agujero negro');
      }
      board.blackHole = BlackHoleEvent.fromJson(settings, saved);
    }
    if (settings.balanceVersion >= 13) {
      final saved = json['launcher'];
      if (saved is! Map<String, dynamic>) {
        throw const FormatException('Falta el lanzador');
      }
      board.launcher = Launcher.fromJson(settings, saved);
    }
    final margin = board.broomHalfWidth + broomThickness;
    final boundedBroom = board.broomPosition.inside(margin);
    if ((boundedBroom - board.broomPosition).length > .0001) {
      throw const FormatException('Invalid broom position');
    }
    board.nextId = json['nextId'] as int;
    board.captured = json['captured'] as int;
    board.goldenCaptured = goldenCaptured;
    board.spawnClock = (json['spawnClock'] as num).toDouble();
    for (final row in json['balls'] as List) {
      final golden = row['golden'] ?? false;
      if (golden is! bool) throw const FormatException('Bola dorada inválida');
      board.balls.add(
        Ball(
          row['id'] as int,
          Vec.fromJson(row['p']),
          Vec.fromJson(row['v']).limit(board.maximumSpeed),
          golden: golden,
        ),
      );
    }
    for (final row in json['coins'] as List) {
      board.coins.add(
        Coin(
          row['id'] as int,
          Vec.fromJson(row['p']),
          row['value'] as int,
          landing: (row['landing'] as num).toDouble(),
        ),
      );
    }
    final queued = json['queuedCoins'];
    if (queued != null) {
      board._queuedCoins.addAll(CoinDenomination.readCounts(queued));
    }
    board.collectedCoins = json['collectedCoins'] == null
        ? null
        : CoinDenomination.readCounts(json['collectedCoins']);
    board.robot.position = Vec.fromJson(json['robot']);
    board.robot.targetId = json['robotTarget'] as int?;
    if (board.balls.length > settings['ball_limit'] ||
        board.coins.length > settings['coin_pile_limit'] ||
        board.coins.any(
          (c) =>
              c.value <= 0 ||
              !c.landing.isFinite ||
              c.landing < 0 ||
              c.landing > .2,
        ) ||
        !board.spawnClock.isFinite ||
        board.spawnClock < 0 ||
        board.captured < 0 ||
        board.goldenCaptured < 0 ||
        board.goldenCaptured > board.captured) {
      throw const FormatException('Tablero guardado inválido');
    }
    final ids = [
      ...board.balls.map((b) => b.id),
      ...board.coins.map((c) => c.id),
    ];
    if (ids.toSet().length != ids.length ||
        ids.any((id) => id <= 0 || id >= board.nextId)) {
      throw const FormatException('IDs de tablero inválidos');
    }
    if (settings.balanceVersion >= 8) {
      final specials = json['specials'];
      final pending = json['captureAllIds'];
      if (specials is! Map<String, dynamic> ||
          pending is! List ||
          pending.any(
            (id) => id is! int || !board.balls.any((ball) => ball.id == id),
          ) ||
          pending.toSet().length != pending.length ||
          (pending.isNotEmpty &&
              !board.specials.unlocked(SpecialAbility.captureAll))) {
        throw const FormatException('Estado de habilidades inválido');
      }
      board.specials.restore(specials);
      board._captureAllIds.addAll(pending.cast<int>());
    } else if (json['specials'] != null || json['captureAllIds'] != null) {
      throw const FormatException('Habilidades en una jornada anterior');
    }
    // Old saves used arbitrary-value piles. Split them once without changing
    // pending money; overflow is emitted as individual coins when space frees.
    final oldPiles = board.coins
        .where(
          (coin) => !CoinDenomination.values.any((d) => d.amount == coin.value),
        )
        .toList();
    board.coins.removeWhere(oldPiles.contains);
    for (final pile in oldPiles) {
      for (final stack in CoinDenomination.split(pile.value)) {
        board._queuedCoins.update(
          stack.denomination.amount,
          (n) => n + stack.count,
          ifAbsent: () => stack.count,
        );
      }
    }
    board._flushCoins();
    return board;
  }
}
