import 'dart:math' as math;
import '../../../core/vec.dart';
import '../../automation/domain/robot.dart';
import 'tool.dart';
import '../../upgrades/domain/catalog.dart';

class Ball {
  Ball(this.id, this.position, this.velocity);
  final int id;
  Vec position, velocity;
  Map<String, dynamic> toJson() => {
    'id': id,
    'p': position.toJson(),
    'v': velocity.toJson(),
  };
}

class Coin {
  Coin(this.id, this.position, this.value, {this.landing = .2});
  final int id;
  Vec position;
  int value;
  double landing;
  Map<String, dynamic> toJson() => {
    'id': id,
    'p': position.toJson(),
    'value': value,
    'landing': landing,
  };
}

class BoardEvents {
  const BoardEvents(this.captured, this.collected);
  final int captured, collected;
}

class Board {
  Board(this.settings, {this.randomState = 42, this.tool = BallTool.hand}) {
    broomPosition = Vec(width - broomHalfWidth - 20, 100);
  }
  static const width = 360.0, height = 560.0;
  static const hole = Vec(180, 412);
  static const generator = Vec(180, 60);
  final DaySettings settings;
  final balls = <Ball>[];
  final coins = <Coin>[];
  final robot = Robot();
  Vec? paddle, target;
  late Vec broomPosition;
  Vec _broomGrabOffset = Vec.zero;
  bool holdingBroom = false;
  bool coinOnly = false;
  BallTool get broomTool =>
      settings['v_unlocked'] > 0 ? BallTool.vee : BallTool.broom;

  void enterClosing() {
    releasePointer(cancel: true);
    coinOnly = true;
  }

  BallTool tool;
  final _heldBalls = <Ball, Vec>{};
  Ball? get heldBall => _heldBalls.keys.firstOrNull;
  List<Ball> get heldBalls => List.unmodifiable(_heldBalls.keys);
  int get handCapacity => math.max(1, settings['hand_capacity'].toInt());
  double get ballMagnetRadius => radius * 2 + 24;
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
  double spawnClock = 0;
  double get radius => settings['ball_radius'];
  int get pending => coins.fold(0, (sum, coin) => sum + coin.value);
  double random() {
    randomState = (1664525 * randomState + 1013904223) & 0xffffffff;
    return randomState / 4294967296;
  }

  int releasePointer({bool cancel = false, double? time}) {
    var collected = 0;
    final velocity = cancel ? Vec.zero : _releaseVelocity(time ?? _clock);
    for (final ball in _heldBalls.keys) {
      ball.velocity = velocity;
    }
    if (!cancel && !_dragged && !_heldDuringGesture && _downPoint != null) {
      collected = _collect(_downPoint!, _downPoint!);
    }
    _heldBalls.clear();
    holdingBroom = false;
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
      (c) =>
          c.landing <= 0 &&
          (c.position - paddle!).length <= settings['collection_radius'],
    );
    final handle =
        broomPosition - Vec(math.cos(toolAngle), math.sin(toolAngle)) * 21;
    holdingBroom =
        !coinOnly &&
        broomUnlocked &&
        !onCoin &&
        (segments.any(
              (segment) => (segment.closest(paddle!) - paddle!).length <= 12,
            ) ||
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
    if (direction.length >= 3) {
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
    var amount = 0;
    coins.removeWhere((coin) {
      if (coin.landing > 0 ||
          segmentDistance(coin.position, a, b) >
              settings['collection_radius']) {
        return false;
      }
      amount += coin.value;
      return true;
    });
    return amount;
  }

  void releaseCoin(int value) {
    final angle = random() * math.pi * 2;
    final distance = 40 + random() * 36;
    final point = (hole + Vec(math.cos(angle), math.sin(angle)) * distance)
        .inside(14);
    Coin? closest;
    for (final coin in coins) {
      if (closest == null ||
          (coin.position - point).length < (closest.position - point).length) {
        closest = coin;
      }
    }
    if (closest != null &&
        ((closest.position - point).length < 17 ||
            coins.length >= settings['coin_pile_limit'])) {
      closest.value += value;
      closest.landing = math.max(closest.landing, .2);
    } else {
      coins.add(Coin(nextId++, point, value));
    }
  }

  BoardEvents update(double dt, {required bool producing}) {
    var collected = 0;
    for (final coin in coins) {
      coin.landing = math.max(0, coin.landing - dt);
    }
    if (producing && !coinOnly) {
      spawnClock += dt;
      if (spawnClock + 1e-9 >= settings['spawn_interval']) {
        spawnClock = math.max(0, spawnClock - settings['spawn_interval']);
        final spawn = generator + Vec((random() - .5) * 42, 30);
        if (balls.length < settings['ball_limit'] &&
            balls.every((b) => (b.position - spawn).length > radius * 2.2)) {
          balls.add(Ball(nextId++, spawn, Vec((random() - .5) * 36, 85)));
        }
      }
    }
    if (paddle != null && target != null) {
      final start = paddle!;
      if (settings['magnet_radius'] > 0) {
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
    var captures = 0;
    balls.removeWhere((ball) {
      if ((ball.position - hole).length > settings['hole_capture_radius']) {
        return false;
      }
      _heldBalls.remove(ball);
      captures++;
      return true;
    });
    captured += captures;
    return BoardEvents(captures, collected);
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
          if (_heldBalls.containsKey(ball)) continue;
          final d = (ball.position - heldBall!.position).length;
          if (d < distance) {
            nearest = ball;
            distance = d;
          }
        }
        if (nearest == null) break;
        final angle = (_heldBalls.length - 1) * math.pi / 2;
        _heldBalls[nearest] =
            _grabOffset +
            Vec(math.cos(angle), math.sin(angle)) * (radius * 2 + 2);
      }
      for (final entry in _heldBalls.entries) {
        final ball = entry.key;
        final goal = (target! + entry.value).inside(radius);
        final previous = ball.position;
        ball.position = previous + (goal - previous).limit(700 * dt);
        // Snapshots never restore an active grip or its contact velocity.
        ball.velocity = (ball.position - previous) * (1 / dt);
      }
    }
    if (!holdingBroom) return;
    final previousBroom = broomPosition;
    final goal = (target! + _broomGrabOffset).inside(
      broomHalfWidth + broomThickness,
    );
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
    'robot': robot.position.toJson(),
    'robotTarget': robot.targetId,
  };

  factory Board.fromJson(DaySettings settings, Map<String, dynamic> json) {
    final board = Board(settings, randomState: json['random'] as int);
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
    board.spawnClock = (json['spawnClock'] as num).toDouble();
    for (final row in json['balls'] as List) {
      board.balls.add(
        Ball(row['id'] as int, Vec.fromJson(row['p']), Vec.fromJson(row['v'])),
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
        board.captured < 0) {
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
    return board;
  }
}
