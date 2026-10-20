import 'dart:math' as math;
import '../../../core/vec.dart';
import '../../automation/domain/robot.dart';
import 'tool.dart';
import 'coin_denomination.dart';
import 'capture_combo.dart';
import 'special_abilities.dart';
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
  }) : specials = SpecialAbilities(settings),
       combo = CaptureCombo(
         enabled:
             combosEnabled ??
             (settings.balanceVersion < 8 || settings['combo_unlocked'] > 0),
       ) {
    broomPosition = Vec(width - broomHalfWidth - 20, 100);
  }
  static const width = 360.0, height = 560.0;
  static const hole = Vec(180, 50);
  static const generator = Vec(180, 480);
  final DaySettings settings;
  final CaptureCombo combo;
  final SpecialAbilities specials;
  final _captureAllIds = <int>{};

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
  bool get canCollectCoins => _heldBalls.isEmpty;
  final robot = Robot();
  Vec? paddle, target;
  late Vec broomPosition;
  Vec _broomGrabOffset = Vec.zero;
  bool holdingBroom = false;
  Vec? _secondBroomTarget;
  Vec _broomPivotOffset = Vec.zero;
  double _broomReferenceAngle = 0, _broomReferenceToolAngle = 0;
  bool get hasSecondBroomPoint => _secondBroomTarget != null;
  List<Vec> get broomHandles =>
      segments.isEmpty ? const [] : [segments.first.a, segments.last.b];

  bool _onBroom(Vec point, double tolerance) =>
      segments.any(
        (segment) => (segment.closest(point) - point).length <= tolerance,
      ) ||
      broomHandles.any((handle) => (handle - point).length <= 22);

  bool grabSecondBroomPoint(Vec point) {
    if (coinOnly ||
        !holdingBroom ||
        target == null ||
        hasSecondBroomPoint ||
        !_onBroom(point, 22) ||
        (point - target!).length < 18) {
      return false;
    }
    _secondBroomTarget = point.inside(0);
    final axis = point - target!;
    _broomReferenceAngle = math.atan2(axis.y, axis.x);
    _broomReferenceToolAngle = toolAngle;
    _broomPivotOffset = broomPosition - (target! + point) * .5;
    return true;
  }

  void dragSecondBroomPoint(Vec point) {
    if (hasSecondBroomPoint) _secondBroomTarget = point.inside(0);
  }

  void releaseSecondBroomPoint() {
    _secondBroomTarget = null;
    if (target != null) _broomGrabOffset = broomPosition - target!;
    _desiredAngle = toolAngle;
  }

  void promoteSecondBroomPoint() {
    final point = _secondBroomTarget;
    if (point == null) return;
    paddle = target = point;
    _downPoint = _directionAnchor = point;
    _samples.clear();
    releaseSecondBroomPoint();
  }

  bool coinOnly = false;
  BallTool get broomTool =>
      settings['v_unlocked'] > 0 ? BallTool.vee : BallTool.broom;

  void enterClosing() {
    releasePointer(cancel: true);
    coinOnly = true;
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
  Vec? _downPoint, _directionAnchor;
  bool _dragged = false, _heldDuringGesture = false;
  double _clock = 0;
  final _samples = <({double time, Vec point})>[];
  double toolAngle = math.pi / 2, _desiredAngle = math.pi / 2;
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
    for (final ball in _heldBalls.keys) {
      ball.velocity = cancel
          ? Vec.zero
          : ball == _manualBall
          ? velocity
          : ball.velocity.limit(380);
    }
    if (!cancel && !_dragged && !_heldDuringGesture && _downPoint != null) {
      collected = _collect(_downPoint!, _downPoint!);
    }
    _heldBalls.clear();
    _manualBall = null;
    _slippedBalls.clear();
    holdingBroom = false;
    _secondBroomTarget = null;
    paddle = null;
    target = null;
    _downPoint = null;
    _directionAnchor = null;
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
    return velocity.length < 18 ? Vec.zero : velocity.limit(380);
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
    _directionAnchor = paddle;
    _dragged = false;
    _heldDuringGesture = false;
    _samples.clear();
    _sample(paddle!, time ?? _clock);
    _desiredAngle = toolAngle;
    final onCoin = coins.any(
      (c) => c.landing <= 0 && (c.position - paddle!).length <= 12,
    );
    final handle =
        broomPosition - Vec(math.cos(toolAngle), math.sin(toolAngle)) * 21;
    holdingBroom =
        !coinOnly &&
        broomUnlocked &&
        !onCoin &&
        (_onBroom(paddle!, 12) ||
            segmentDistance(paddle!, broomPosition, handle) <= 12);
    tool = holdingBroom ? broomTool : BallTool.hand;
    if (holdingBroom) {
      _broomGrabOffset = broomPosition - paddle!;
      _heldDuringGesture = true;
    }
    if (!coinOnly && !holdingBroom && !onCoin) {
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
    final direction = destination - _directionAnchor!;
    if (direction.length >= 3 && !holdingBroom) {
      _desiredAngle = math.atan2(direction.y, direction.x);
      _directionAnchor = destination;
    }
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
    // Small steps bound translation and rotating tips below a ball diameter.
    final steps = math.max(1, (dt / (1 / 240)).ceil());
    final step = dt / steps;
    for (var i = 0; i < steps; i++) {
      _moveTool(step);
      final friction = math.exp(-1.6 * step);
      for (final ball in balls) {
        if (_heldBalls.containsKey(ball)) continue;
        final toHole = hole - ball.position;
        if (toHole.length < settings['hole_capture_radius'] + 15) {
          ball.velocity = ball.velocity + toHole.unit * (220 * step);
        }
        ball.velocity = ball.velocity.limit(380) * friction;
        if (ball.velocity.length < 1) ball.velocity = Vec.zero;
        ball.position = ball.position + ball.velocity * step;
        final bounded = ball.position.inside(radius);
        if (bounded.x != ball.position.x) {
          ball.velocity = Vec(-ball.velocity.x * .4, ball.velocity.y);
        }
        if (bounded.y != ball.position.y) {
          ball.velocity = Vec(ball.velocity.x, -ball.velocity.y * .4);
        }
        ball.position = bounded;
      }
      _collide();
      _contactBroom(Vec.zero, 0);
    }
    _clock += dt;
    var captures = 0, goldenCaptures = 0;
    final rewards = <int>[];
    balls.removeWhere((ball) {
      if (!_captureAllIds.contains(ball.id) &&
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

  void _moveTool(double dt) {
    if (paddle == null || target == null) return;
    final start = paddle!;
    paddle = start + (target! - start).limit(900 * dt);
    if (_heldBalls.isNotEmpty && !holdingBroom) {
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
        ball.position = previous + (goal - previous).limit(700 * dt);
        ball.velocity = (ball.position - previous) * (1 / dt);
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
        ball.velocity = (ball.velocity + acceleration * dt).limit(380);
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
    if (!holdingBroom) return;
    final previousBroom = broomPosition;
    var desiredCenter = target! + _broomGrabOffset;
    final second = _secondBroomTarget;
    if (second != null) {
      final axis = second - target!;
      if (axis.length >= 18) {
        _desiredAngle =
            _broomReferenceToolAngle +
            math.atan2(axis.y, axis.x) -
            _broomReferenceAngle;
      }
      final rotation = _desiredAngle - _broomReferenceToolAngle;
      final c = math.cos(rotation), s = math.sin(rotation);
      final rotatedOffset = Vec(
        _broomPivotOffset.x * c - _broomPivotOffset.y * s,
        _broomPivotOffset.x * s + _broomPivotOffset.y * c,
      );
      desiredCenter = (target! + second) * .5 + rotatedOffset;
    }
    final goal = desiredCenter.inside(broomHalfWidth + broomThickness);
    broomPosition = previousBroom + (goal - previousBroom).limit(900 * dt);
    var angle = (_desiredAngle - toolAngle + math.pi) % (2 * math.pi) - math.pi;
    if (broomTool == BallTool.broom) {
      if (angle > math.pi / 2) angle -= math.pi;
      if (angle < -math.pi / 2) angle += math.pi;
    }
    final turn = angle.clamp(-3 * dt, 3 * dt);
    toolAngle = (toolAngle + turn) % (2 * math.pi);
    _contactBroom((broomPosition - previousBroom) * (1 / dt), turn / dt);
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
        final surface = (velocity + rotating.limit(80)).limit(380);
        final relative = surface - ball.velocity;
        final impulse = relative.x * normal.x + relative.y * normal.y;
        if (impulse > 0) {
          ball.velocity = (ball.velocity + normal * impulse).limit(380);
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
        380,
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
                  .limit(380);
            }
            if (!heldB) {
              other.velocity = (other.velocity + n * impulse * (heldA ? 2 : 1))
                  .limit(380);
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
    'broomPosition': broomPosition.toJson(),
    'broomAngle': toolAngle,
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
      board.toolAngle = board._desiredAngle = angle.toDouble() % (2 * math.pi);
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
          Vec.fromJson(row['v']),
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
