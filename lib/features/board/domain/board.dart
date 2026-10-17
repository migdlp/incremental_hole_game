import 'dart:math' as math;
import '../../../core/vec.dart';
import '../../automation/domain/robot.dart';
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
  Board(this.settings, {this.randomState = 42});
  static const width = 360.0, height = 560.0;
  static const hole = Vec(180, 412);
  static const generator = Vec(180, 60);
  final DaySettings settings;
  final balls = <Ball>[];
  final coins = <Coin>[];
  final robot = Robot();
  Vec? paddle, target;
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

  void releasePointer() {
    paddle = null;
    target = null;
  }

  int touch(Vec point) {
    paddle = point.inside(0);
    target = paddle;
    return _collect(paddle!, paddle!);
  }

  int drag(Vec point) {
    if (target == null) return 0;
    final destination = point.inside(0);
    final amount = _collect(target!, destination);
    target = destination;
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
    if (producing) {
      spawnClock += dt;
      if (spawnClock >= settings['spawn_interval']) {
        spawnClock %= settings['spawn_interval'];
        final spawn = generator + Vec((random() - .5) * 42, 30);
        if (balls.length < settings['ball_limit'] &&
            balls.every((b) => (b.position - spawn).length > radius * 2.2)) {
          balls.add(Ball(nextId++, spawn, Vec((random() - .5) * 36, 85)));
        }
      }
    }
    if (paddle != null && target != null) {
      final start = paddle!;
      final move = (target! - start).limit(1000 * dt);
      final steps = math.max(1, (move.length / 4).ceil());
      for (var i = 1; i <= steps; i++) {
        final point = start + move * (i / steps);
        _push(point, settings['paddle_radius'], move * (1 / dt), 3);
      }
      paddle = start + move;
      if (settings['magnet_radius'] > 0) {
        for (final coin in coins) {
          if (coin.landing <= 0 &&
              (coin.position - paddle!).length <= settings['magnet_radius']) {
            coin.position =
                coin.position + (paddle! - coin.position).limit(140 * dt);
          }
        }
      }
      collected += _collect(start, paddle!);
    }
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
    final friction = math.exp(-1.6 * dt);
    for (final ball in balls) {
      final toHole = hole - ball.position;
      if (toHole.length < settings['hole_capture_radius'] + 15) {
        ball.velocity = ball.velocity + toHole.unit * (220 * dt);
      }
      ball.velocity = ball.velocity.limit(380) * friction;
      ball.position = ball.position + ball.velocity * dt;
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
    var captures = 0;
    balls.removeWhere((ball) {
      if ((ball.position - hole).length > settings['hole_capture_radius']) {
        return false;
      }
      captures++;
      return true;
    });
    captured += captures;
    return BoardEvents(captures, collected);
  }

  void _push(Vec point, double size, Vec velocity, double correction) {
    for (final ball in balls) {
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
            final separation = n * (overlap * .5 + .01);
            ball.position = (ball.position - separation).inside(radius);
            other.position = (other.position + separation).inside(radius);
            final relative = ball.velocity - other.velocity;
            final impulse =
                math.max(0.0, relative.x * n.x + relative.y * n.y) * .65;
            ball.velocity = ball.velocity - n * impulse;
            other.velocity = other.velocity + n * impulse;
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
    'balls': balls.map((b) => b.toJson()).toList(),
    'coins': coins.map((c) => c.toJson()).toList(),
    'robot': robot.position.toJson(),
    'robotTarget': robot.targetId,
  };

  factory Board.fromJson(DaySettings settings, Map<String, dynamic> json) {
    final board = Board(settings, randomState: json['random'] as int);
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
