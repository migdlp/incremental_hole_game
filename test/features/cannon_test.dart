import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/cannon.dart';
import '../test_support.dart';

void main() {
  final catalog = testCatalog();
  double deg(double degrees) => degrees * math.pi / 180;

  test('G1 sweeps a 150 degree arc at constant speed', () {
    final cannon = Cannon(cannonSlots[0]);
    double at(double t) => cannon.angleAt(t, arcDegrees: 150, period: 2);
    final base = math.pi / 2;
    expect(at(0), closeTo(base - deg(75), 1e-9));
    expect(at(.5), closeTo(base, 1e-9));
    expect(at(1), closeTo(base + deg(75), 1e-9));
    expect(at(1.5), closeTo(base, 1e-9));
    expect(at(2), closeTo(base - deg(75), 1e-9));
  });

  test('slots are phase shifted by a quarter period', () {
    final angle = Cannon(cannonSlots[1]).angleAt(0, arcDegrees: 150, period: 2);
    expect(angle, closeTo(0 + 0, 1e-9));
  });

  test('muzzle is 24 units along the aim', () {
    final muzzle = Cannon(cannonSlots[0]).muzzle(math.pi / 2);
    expect(muzzle.x, closeTo(180, 1e-9));
    expect(muzzle.y, closeTo(84, 1e-9));
  });

  test('tick never makes timers negative', () {
    final cannon = Cannon(cannonSlots[0], cooldown: .3)
      ..blockedFlash = .1
      ..recoil = .1;
    cannon.tick(1);
    expect(cannon.cooldown, 0);
    expect(cannon.blockedFlash, 0);
    expect(cannon.recoil, 0);
  });

  test('fromJson rejects mismatched slot and negative values', () {
    expect(
      () => Cannon.fromJson(cannonSlots[0], {
        'slot': 2,
        'cooldown': 0,
        'autoClock': 0,
      }),
      throwsFormatException,
    );
    expect(
      () => Cannon.fromJson(cannonSlots[0], {
        'slot': 1,
        'cooldown': -.1,
        'autoClock': 0,
      }),
      throwsFormatException,
    );
  });

  test('toJson roundtrip', () {
    final cannon = Cannon(cannonSlots[2], cooldown: .4, autoClock: 1.1);
    final restored = Cannon.fromJson(cannonSlots[2], cannon.toJson());
    expect(restored.cooldown, .4);
    expect(restored.autoClock, 1.1);
    expect(restored.slot.position, isA<Vec>());
  });

  group('G1 in the board', () {
    Board newBoard({int seed = 42}) =>
        Board(catalog.settings({}), randomState: seed);

    void run(Board board, double seconds) {
      for (var i = 0; i < (seconds * 60).round(); i++) {
        board.update(1 / 60, producing: true);
      }
    }

    test('manual shots respect cooldown', () {
      final board = newBoard();
      final cannon = board.cannons.first;
      expect(board.fireCannon(cannon), isTrue);
      run(board, .5);
      expect(board.fireCannon(cannon), isFalse);
      expect(board.balls.length, 1);
      run(board, .5);
      board.balls.clear();
      expect(board.fireCannon(cannon), isTrue);
      expect(board.balls.length, 1);
    });

    test('two shots a full cooldown apart create two balls', () {
      final board = newBoard();
      final cannon = board.cannons.first;
      expect(board.fireCannon(cannon), isTrue);
      run(board, 1);
      expect(board.fireCannon(cannon), isTrue);
      expect(board.balls.length, 2);
    });

    test('shot leaves from the muzzle at shot speed', () {
      final board = newBoard();
      final cannon = board.cannons.first;
      board.fireCannon(cannon);
      final ball = board.balls.single;
      expect((ball.position - cannon.slot.position).length, closeTo(24, 1e-6));
      expect(ball.velocity.length, closeTo(520, .001));
    });

    test('blocked muzzle keeps cooldown and flashes', () {
      final board = newBoard();
      final cannon = board.cannons.first;
      final muzzle = cannon.muzzle(board.cannonAngle(cannon));
      board.balls.add(Ball(board.nextId++, muzzle, Vec.zero));
      expect(board.fireCannon(cannon), isFalse);
      expect(cannon.cooldown, 0);
      expect(cannon.blockedFlash, greaterThan(0));
      expect(board.balls.length, 1);
    });

    test('ball limit blocks shooting', () {
      final board = newBoard();
      final limit = board.settings['ball_limit'].toInt();
      for (var i = 0; i < limit; i++) {
        board.balls.add(
          Ball(
            board.nextId++,
            Vec(20.0 + (i % 15) * 20, 300 + (i ~/ 15) * 20),
            Vec.zero,
          ),
        );
      }
      expect(board.fireCannon(board.cannons.first), isFalse);
    });

    test('closing freezes the cannon', () {
      final board = newBoard();
      run(board, .5);
      board.enterClosing();
      final clock = board.cannonClock;
      expect(board.fireCannon(board.cannons.first), isFalse);
      board.update(1, producing: true);
      expect(board.cannonClock, clock);
    });

    test('same seed and taps give identical shots', () {
      final a = newBoard(seed: 7), b = newBoard(seed: 7);
      for (var step = 0; step < 300; step++) {
        if (step % 70 == 0) {
          a.fireCannon(a.cannons.first);
          b.fireCannon(b.cannons.first);
        }
        a.update(1 / 60, producing: true);
        b.update(1 / 60, producing: true);
      }
      expect(a.balls.length, b.balls.length);
      for (var i = 0; i < a.balls.length; i++) {
        expect(a.balls[i].position.x, b.balls[i].position.x);
        expect(a.balls[i].position.y, b.balls[i].position.y);
        expect(a.balls[i].velocity.x, b.balls[i].velocity.x);
      }
    });

    test('cannon state survives save and restore', () {
      final board = newBoard();
      board.fireCannon(board.cannons.first);
      run(board, .4);
      final restored = Board.fromJson(board.settings, board.toJson());
      expect(restored.cannonClock, closeTo(board.cannonClock, 1e-9));
      expect(
        restored.cannons.first.cooldown,
        closeTo(board.cannons.first.cooldown, 1e-9),
      );
    });

    test('saved cannons with the wrong count or cooldown are rejected', () {
      final board = newBoard();
      final json = board.toJson();
      expect(
        () => Board.fromJson(board.settings, {...json, 'cannons': []}),
        throwsFormatException,
      );
      expect(
        () => Board.fromJson(board.settings, {
          ...json,
          'cannons': [
            {'slot': 1, 'cooldown': 1.5, 'autoClock': 0},
          ],
        }),
        throwsFormatException,
      );
    });

    test('the cooldown stays frozen outside production', () {
      final board = newBoard();
      board.fireCannon(board.cannons.first);
      run(board, .6);
      final cooldown = board.cannons.first.cooldown;
      board.update(2, producing: false);
      expect(board.cannons.first.cooldown, cooldown);
    });

    test('a full day without taps creates no ball', () {
      final board = newBoard();
      run(board, 13);
      expect(board.balls, isEmpty);
    });
  });
}
