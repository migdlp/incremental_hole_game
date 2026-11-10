import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import '../test_support.dart';

void main() {
  final catalog = testCatalog();

  test('fast free ball crosses the hole without being captured', () {
    final board = Board(catalog.settings({}));
    board.balls.add(
      Ball(board.nextId++, Board.hole - const Vec(40, 0), const Vec(400, 0)),
    );
    for (var i = 0; i < 10; i++) {
      board.update(1 / 60, producing: false);
    }
    expect(board.captured, 0);
  });

  test('slow free ball inside the hole is captured', () {
    final board = Board(catalog.settings({}));
    board.balls.add(Ball(board.nextId++, Board.hole, Vec.zero));
    board.update(1 / 60, producing: false);
    expect(board.captured, 1);
  });

  test('free ball at exactly the capture speed is captured', () {
    final board = Board(catalog.settings({}));
    // The hole attraction is zero at its centre, so only friction acts.
    board.balls.add(Ball(board.nextId++, Board.hole, const Vec(140, 0)));
    board.update(1 / 240, producing: false);
    expect(board.captured, 1);
  });

  test('wall bounce keeps configured restitution', () {
    final board = Board(catalog.settings({}));
    final ball = Ball(board.nextId++, const Vec(354, 300), const Vec(500, 0));
    board.balls.add(ball);
    board.update(1 / 240, producing: false);
    final friction = math.exp(-1.6 / 240);
    expect(ball.velocity.x, closeTo(-500 * 0.55 * friction, 2));
  });

  test('free ball speed is capped at max_ball_speed', () {
    final board = Board(catalog.settings({}));
    final ball = Ball(board.nextId++, const Vec(100, 300), const Vec(900, 0));
    board.balls.add(ball);
    board.update(1 / 60, producing: false);
    expect(ball.velocity.length, lessThanOrEqualTo(600));
  });
}
