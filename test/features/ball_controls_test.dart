import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/tool.dart';
import '../test_support.dart';

void simulate(Board board, double seconds) {
  for (var i = 0; i < (seconds * 240).round(); i++) {
    board.update(1 / 240, producing: false);
  }
}

Ball addBall(Board board, Vec point) {
  final ball = Ball(board.nextId++, point, Vec.zero);
  board.balls.add(ball);
  return ball;
}

void main() {
  final catalog = testCatalog();

  test('hand keeps one identity and does not grab balls crossed later', () {
    final board = Board(catalog.settings({}));
    final first = addBall(board, const Vec(100, 200));
    final second = addBall(board, const Vec(155, 200));
    board.touch(const Vec(100, 200), time: 0);
    board.drag(const Vec(150, 200), time: .1);
    simulate(board, .2); // enough travel time at the shared 380 u/s cap
    expect(board.heldBall, same(first));
    expect(
      second.position.x,
      greaterThan(155),
    ); // physical contact, no second grip
    board.releasePointer(cancel: true);
    expect(board.heldBall, isNull);
    expect(first.velocity.length, 0);
    board.touch(const Vec(20, 200));
    board.drag(second.position);
    simulate(board, .1);
    expect(board.heldBall, isNull); // an empty gesture cannot acquire mid-drag
  });

  Vec throwVelocity(int hz, {bool stop = false, double speed = 200}) {
    final board = Board(catalog.settings({}));
    final ball = addBall(board, const Vec(80, 160));
    board.touch(ball.position, time: 0);
    for (var i = 1; i <= hz ~/ 5; i++) {
      final time = i / hz;
      board.drag(Vec(80 + speed * time, 160), time: time);
      simulate(board, 1 / hz);
    }
    if (stop) simulate(board, .2);
    board.releasePointer(time: stop ? .4 : .2);
    return ball.velocity;
  }

  test('gentle placement, stopped gesture and flick have distinct inertia', () {
    expect(throwVelocity(60, speed: 10).length, 0);
    expect(throwVelocity(60, stop: true).length, 0);
    final flick = throwVelocity(60);
    expect(flick.x, closeTo(200, .01));
    expect(flick.y, closeTo(0, .01));
    expect(throwVelocity(120).x, closeTo(flick.x, .01));
    expect(throwVelocity(30).x, closeTo(flick.x, .01));
  });

  test('fast drag into packed balls and edge stays finite and bounded', () {
    final board = Board(catalog.settings({}));
    final held = addBall(board, const Vec(40, 180));
    for (var i = 0; i < 14; i++) {
      addBall(board, Vec(60 + i * 12, 180));
    }
    board.touch(held.position, time: 0);
    board.drag(const Vec(10000, 180), time: .001);
    simulate(board, .6);
    board.releasePointer(time: .601);
    simulate(board, 1);
    for (final ball in board.balls) {
      expect(ball.position.x, inInclusiveRange(6, 354));
      expect(ball.position.y, inInclusiveRange(6, 554));
      expect(ball.velocity.length.isFinite, isTrue);
      expect(ball.velocity.length, lessThanOrEqualTo(380));
    }
  });

  test(
    'capture held ball once and never reacquire during the same gesture',
    () {
      final board = Board(catalog.settings({}));
      final ball = addBall(board, Board.hole + const Vec(0, 52));
      board.touch(ball.position);
      board.drag(Board.hole);
      simulate(board, .2);
      expect(board.captured, 1);
      expect(board.heldBall, isNull);
      expect(board.balls, isEmpty);
      addBall(board, Board.hole + const Vec(0, 62));
      board.drag(Board.hole + const Vec(0, 62));
      simulate(board, .1);
      expect(board.heldBall, isNull);
      board.releasePointer();
      expect(board.captured, 1);
    },
  );

  test('one finger translates the broom without changing its orientation', () {
    final board = Board(catalog.settings({'broom': 1}), tool: BallTool.broom);
    board.broomPosition = const Vec(180, 180);
    board.touch(const Vec(180, 180));
    final initial = board.toolAngle;
    board.drag(const Vec(230, 180));
    board.update(1 / 60, producing: false);
    expect((board.toolAngle - initial).abs(), lessThanOrEqualTo(3 / 60 + 1e-6));
    simulate(board, .7);
    final segment = board.segments.single;
    expect((segment.b - segment.a).unit.y.abs(), lessThan(.001));
    expect(board.toolAngle, initial);
    final angle = board.toolAngle;
    board.drag(const Vec(230.1, 180.1));
    simulate(board, .4);
    expect(board.toolAngle, closeTo(angle, .001));
  });

  test('straight broom carries a front group without radial scatter', () {
    final board = Board(catalog.settings({'broom': 1}), tool: BallTool.broom);
    final balls = [
      for (final x in [155.0, 180.0, 205.0]) addBall(board, Vec(x, 210)),
    ];
    board.broomPosition = const Vec(180, 180);
    board.touch(const Vec(180, 180));
    for (var i = 1; i <= 60; i++) {
      board.drag(Vec(180, 180 + i * 1.0));
      board.update(1 / 60, producing: false);
    }
    for (var i = 0; i < balls.length; i++) {
      expect(balls[i].position.y, greaterThan(240));
      expect(balls[i].position.x, closeTo([155.0, 180.0, 205.0][i], .1));
    }
  });

  test('greater width really reaches balls outside narrow broom', () {
    double sweep(int level) {
      final board = Board(
        catalog.settings({'broom': 1, 'paddle': level}),
        tool: BallTool.broom,
      );
      final ball = addBall(board, const Vec(235, 210));
      board.broomPosition = const Vec(180, 180);
      board.touch(const Vec(180, 180));
      for (var i = 1; i <= 60; i++) {
        board.drag(Vec(180, 180 + i * 1.0));
        board.update(1 / 60, producing: false);
      }
      return ball.position.y;
    }

    expect(sweep(0), closeTo(210, .01));
    expect(sweep(3), greaterThan(240));
  });

  test('V gathers both sides towards its center without remote attraction', () {
    final board = Board(
      catalog.settings({'broom': 1, 'paddle': 1, 'broom_v': 1}),
      tool: BallTool.vee,
    );
    final left = addBall(board, const Vec(150, 257));
    final right = addBall(board, const Vec(210, 257));
    final outside = addBall(board, const Vec(50, 252));
    board.broomPosition = const Vec(180, 292);
    board.toolAngle = -math.pi / 2;
    board.touch(board.broomPosition);
    expect(board.segments.length, 2);
    for (var i = 1; i <= 120; i++) {
      board.drag(Vec(180, 292 - i * .6));
      board.update(1 / 60, producing: false);
    }
    expect(left.position.x, greaterThan(150));
    expect(right.position.x, lessThan(210));
    expect(right.position.x - left.position.x, lessThan(60));
    expect(outside.position.x, 50);
    expect(outside.position.y, 252);
    expect(board.captured, 0);
    for (var i = 121; i <= 450; i++) {
      board.drag(Vec(180, 292 - i * .6));
      board.update(1 / 60, producing: false);
    }
    board.releasePointer();
    // Deliver both gathered balls to the relocated hole with the same physical tool.
    for (final item in [left, right]) {
      item.position = board.holePosition;
    }
    board.update(1 / 60, producing: false);
    expect(board.captured, 2);
    expect(board.balls, [outside]);
  });

  test('tap commits on release; drag starting on coin cannot collect free', () {
    final board = Board(catalog.settings({}, balanceVersion: 14));
    board.coins.add(Coin(board.nextId++, const Vec(100, 250), 7, landing: 0));
    expect(board.touch(const Vec(100, 250)), 0);
    expect(board.drag(const Vec(200, 250)), 0);
    simulate(board, .5);
    expect(board.releasePointer(), 0);
    expect(board.pending, 7);
    board.touch(const Vec(20, 250));
    board.drag(const Vec(200, 250));
    simulate(board, .5);
    expect(board.releasePointer(), 0);
    expect(board.pending, 7);
    board.touch(const Vec(100, 250));
    expect(board.releasePointer(), 7);
    expect(board.releasePointer(), 0);
    expect(board.pending, 0);
  });

  test(
    'cancel and pause neither collect a pending tap nor throw held ball',
    () {
      final session = GameSession(catalog, MemoryStore())..startDay();
      final board = session.board!;
      board.coins.add(Coin(board.nextId++, const Vec(90, 300), 2, landing: 0));
      session.touch(const Vec(90, 300));
      session.pause();
      expect(board.pending, 2);
      expect(session.economy.collected, 0);
      session.resume();
      final ball = addBall(board, const Vec(80, 160));
      session.touch(ball.position, time: 0);
      session.drag(const Vec(140, 160), time: .1);
      simulate(board, .1);
      session.pause();
      expect(board.heldBall, isNull);
      expect(ball.velocity.length, 0);
    },
  );

  test(
    'tool purchase and selection persist; locked tool cannot be selected',
    () {
      final session = GameSession(catalog, MemoryStore());
      session.selectTool(BallTool.vee);
      expect(session.selectedTool, BallTool.hand);
      session.economy.balance = 500;
      for (final id in ['hand', 'hand', 'broom', 'paddle', 'broom_v']) {
        expect(
          session.purchase(catalog.definitions.firstWhere((d) => d.id == id)),
          isTrue,
        );
      }
      expect(session.selectedTool, BallTool.vee);
      final restored = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      expect(restored.selectedTool, BallTool.vee);
      restored.startDay();
      expect(restored.board!.tool, BallTool.vee);
      expect(restored.board!.sweepEnabled, isFalse);
      restored.selectTool(BallTool.hand);
      expect(restored.board!.tool, BallTool.hand);
    },
  );

  test(
    'night clears a held ball, landing coins and old input across reload',
    () {
      final session = GameSession(catalog, MemoryStore())..startDay();
      final board = session.board!;
      final ball = addBall(board, const Vec(80, 160));
      session.touch(ball.position);
      board.coins.add(Coin(board.nextId++, const Vec(90, 300), 2));
      board.captured = 1;
      session.economy.generated = 2;
      session.economy.balance = 50;
      session.finishDay();
      session.finishDay();
      final restored = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      expect(restored.running, isFalse);
      expect(restored.economy.balance, 50);
      expect(restored.progress.last!.lost, 2);
      restored.startDay();
      expect(restored.board!.balls, isEmpty);
      expect(restored.board!.coins, isEmpty);
      expect(restored.board!.heldBall, isNull);
      expect(restored.board!.target, isNull);
    },
  );

  test(
    'midday snapshot keeps held ball but restores no grip or fake throw',
    () {
      final session = GameSession(catalog, MemoryStore())..startDay();
      final ball = addBall(session.board!, const Vec(80, 160));
      session.touch(ball.position, time: 0);
      session.drag(const Vec(160, 160), time: .1);
      simulate(session.board!, .1);
      final restored = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      expect(
        restored.board!.balls.single.position.x,
        closeTo(ball.position.x, .001),
      );
      expect(restored.board!.balls.single.velocity.length, 0);
      expect(restored.board!.heldBall, isNull);
      expect(restored.paused, isTrue);
    },
  );

  test(
    'legacy v1 migrates savings and old width purchases without free sweep',
    () {
      final session = GameSession(catalog, MemoryStore());
      session.levels.addAll({'broom': 1, 'paddle': 1, 'robot': 1});
      session.economy.balance = 123;
      session.startDay();
      final data = jsonDecode(session.snapshot()) as Map<String, dynamic>;
      data['version'] = 1;
      data['run']['board'].remove('combo');
      data['run']['board'].remove('specials');
      data['run']['board'].remove('captureAllIds');
      data['run']['settings'] = catalog
          .settings(session.levels, balanceVersion: 1)
          .toJson();
      data['run'].remove('balanceVersion');
      data.remove('tool');
      data['levels'].remove('broom');
      data['run']['settings'].remove('broom_unlocked');
      final restored = GameSession(catalog, MemoryStore())
        ..restore(jsonEncode(data));
      expect(restored.economy.balance, 123);
      expect(restored.levels['paddle'], 1);
      expect(restored.levels['robot'], 1);
      expect(restored.levels['broom'], 1);
      expect(restored.selectedTool, BallTool.broom);
      expect(restored.board!.settings['robot_count'], 1);
      expect(restored.board!.sweepEnabled, isFalse);
      expect(restored.paused, isTrue);
      expect(jsonDecode(restored.snapshot())['version'], 13);
    },
  );

  test('current save rejects forged tool unlocks and settings atomically', () {
    final session = GameSession(catalog, MemoryStore())..startDay();
    final data = jsonDecode(session.snapshot()) as Map<String, dynamic>;
    data['tool'] = 'vee';
    data['balance'] = 10000;
    expect(() => session.restore(jsonEncode(data)), throwsFormatException);
    expect(session.economy.balance, 0);
    data['tool'] = 'hand';
    data['run']['settings']['coin_sweep'] = 1;
    expect(() => session.restore(jsonEncode(data)), throwsFormatException);
  });

  test('geometry is perpendicular and V opens towards motion', () {
    final straight = broomSegments(BallTool.broom, Vec.zero, 0, 40).single;
    expect(straight.a.x, closeTo(0, .001));
    expect(straight.b.y - straight.a.y, closeTo(80, .001));
    final vee = broomSegments(BallTool.vee, Vec.zero, math.pi / 2, 40);
    expect(vee.first.a.y, greaterThan(vee.first.b.y));
    expect(vee.last.b.y, greaterThan(vee.last.a.y));
  });
}
