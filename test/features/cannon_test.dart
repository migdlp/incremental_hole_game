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

  group('touch and body', () {
    final g1 = cannonSlots[0].position;

    test('touching the cannon fires instead of grabbing', () {
      final board = Board(catalog.settings({}));
      board.balls.add(Ball(board.nextId++, const Vec(168, 66), Vec.zero));
      board.touch(g1);
      expect(board.balls.length, 2);
      expect(board.heldBalls, isEmpty);
      expect(board.releasePointer(), 0);
    });

    test('touching the cannon never collects coins', () {
      final board = Board(catalog.settings({'sweep': 1}));
      board.coins.add(Coin(board.nextId++, const Vec(180, 70), 2, landing: 0));
      expect(board.touch(g1), 0);
      expect(board.drag(const Vec(180, 90)), 0);
      expect(board.releasePointer(), 0);
      expect(board.coins.length, 1);
    });

    test('closing touch on the cannon collects coins normally', () {
      final board = Board(catalog.settings({}));
      board.enterClosing();
      board.coins.add(Coin(board.nextId++, const Vec(190, 60), 2, landing: 0));
      board.touch(g1);
      expect(board.releasePointer(), 2);
      expect(board.balls, isEmpty);
    });

    test('balls bounce off the cannon body', () {
      final board = Board(catalog.settings({}));
      board.balls.add(
        Ball(board.nextId++, const Vec(180, 120), const Vec(0, -300)),
      );
      for (var i = 0; i < 30; i++) {
        board.update(1 / 60, producing: false);
        expect(
          (board.balls.single.position - g1).length,
          greaterThanOrEqualTo(22 - 1e-6),
        );
      }
    });

    test(
      'fast shots stay inside the board and outside bodies at 30, 60 and 120 fps',
      () {
        for (final dt in [1 / 30, 1 / 60, 1 / 120]) {
          final board = Board(catalog.settings({}));
          for (var shot = 0; shot < 50; shot++) {
            board.cannons.first.cooldown = 0;
            board.fireCannon(board.cannons.first);
            for (var t = 0.0; t < .2 - 1e-9; t += dt) {
              board.update(dt, producing: true);
              for (final ball in board.balls) {
                expect(ball.position.x, inInclusiveRange(0, 360));
                expect(ball.position.y, inInclusiveRange(0, 560));
                expect((ball.position - g1).length, greaterThanOrEqualTo(21.5));
              }
            }
          }
        }
      },
    );

    test('fast ball does not knock a held ball out of the hand', () {
      final board = Board(catalog.settings({}));
      final held = Ball(board.nextId++, const Vec(180, 300), Vec.zero);
      board.balls.add(held);
      board.touch(const Vec(180, 300));
      expect(board.heldBalls, contains(held));
      board.balls.add(
        Ball(board.nextId++, const Vec(180, 200), const Vec(0, 520)),
      );
      for (var i = 0; i < 20; i++) {
        board.update(1 / 60, producing: true);
      }
      expect(board.heldBalls, contains(held));
    });

    test('touch at exactly 28 units fires and at 29 grabs the ball', () {
      final board = Board(catalog.settings({}));
      board.touch(g1 + const Vec(28, 0));
      expect(board.balls.length, 1);
      board.releasePointer();
      final other = Board(catalog.settings({}));
      other.balls.add(Ball(other.nextId++, g1 + const Vec(29, 0), Vec.zero));
      other.touch(g1 + const Vec(29, 0));
      expect(other.balls.length, 1);
      expect(other.heldBalls, isNotEmpty);
    });

    test('a drag that starts on the cannon grabs and collects nothing', () {
      final board = Board(catalog.settings({'sweep': 1}));
      board.balls.add(Ball(board.nextId++, const Vec(180, 120), Vec.zero));
      board.coins.add(Coin(board.nextId++, const Vec(180, 100), 2, landing: 0));
      board.touch(g1);
      board.drag(const Vec(180, 120));
      expect(board.heldBalls, isEmpty);
      expect(board.releasePointer(), 0);
      expect(board.coins.length, 1);
    });
  });

  group('automatic fire', () {
    Board automatic({double? interval}) {
      final settings = catalog.settings({});
      settings.values['g1_automatic'] = 1;
      if (interval != null) settings.values['g1_auto_interval'] = interval;
      return Board(settings);
    }

    void run(Board board, double seconds) {
      for (var i = 0; i < (seconds * 60).round(); i++) {
        board.update(1 / 60, producing: true);
      }
    }

    test('automatic cannon fires every interval', () {
      final board = automatic();
      run(board, 3);
      expect(board.balls.length, 2);
    });

    test('manual tap resets the automatic clock', () {
      final board = automatic();
      run(board, 1);
      expect(board.fireCannon(board.cannons.first), isTrue);
      expect(board.balls.length, 1);
      var shotAt = -1.0;
      for (var step = 0; step < 300 && shotAt < 0; step++) {
        final before = board.balls.length;
        board.update(1 / 60, producing: true);
        if (board.balls.length > before) shotAt = 1 + (step + 1) / 60;
      }
      expect(shotAt, inInclusiveRange(2.48, 2.52));
    });

    test('automatic shot sets the shared cooldown', () {
      double cooldownAfterFirstShot(Board board) {
        while (board.balls.isEmpty) {
          board.update(1 / 60, producing: true);
        }
        return board.cannons.first.cooldown;
      }

      expect(cooldownAfterFirstShot(automatic()), closeTo(1, 1e-9));
      expect(
        cooldownAfterFirstShot(automatic(interval: .8)),
        closeTo(.8, 1e-9),
      );
    });

    test('blocked automatic shot retries without losing its turn', () {
      final board = automatic();
      run(board, 1.45);
      final cannon = board.cannons.first;
      final muzzle = cannon.muzzle(board.cannonAngle(cannon));
      final blocker = Ball(board.nextId++, muzzle, Vec.zero);
      board.balls.add(blocker);
      // The sweep keeps moving, so pin the aim by freezing the clock reading.
      for (var i = 0; i < 9; i++) {
        blocker.position = cannon.muzzle(board.cannonAngle(cannon));
        blocker.velocity = Vec.zero;
        board.update(1 / 60, producing: true);
      }
      expect(board.balls.length, 1);
      expect(cannon.autoClock, greaterThanOrEqualTo(1.5));
      board.balls.clear();
      board.update(1 / 60, producing: true);
      expect(board.balls.length, 1);
    });

    test('manual cannon never fires on its own', () {
      final board = Board(catalog.settings({}));
      run(board, 5);
      expect(board.balls, isEmpty);
    });

    test('automatic clock freezes during closing', () {
      final board = automatic();
      run(board, .5);
      board.enterClosing();
      final clock = board.cannons.first.autoClock;
      board.update(1, producing: true);
      expect(board.cannons.first.autoClock, clock);
    });
  });
}
