import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flame/components.dart' show Vector2;
import 'package:incremental_hole_game/features/board/presentation/garden_game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/day_cycle/domain/day_cycle.dart';
import '../test_support.dart';

void frames(GameSession session, int count) {
  for (var i = 0; i < count; i++) {
    session.tick(1 / 60);
  }
}

void main() {
  final catalog = testCatalog();
  test('purchased broom is a persistent item and hand remains available', () {
    final board = Board(catalog.settings({'broom': 1}));
    expect(board.segments, hasLength(1));
    final segment = board.segments.single;
    final center = (segment.a + segment.b) * .5;
    expect(center.x, greaterThan(Board.width / 2));
    expect(center.y, lessThan(Board.height / 2));
    board.touch(center, time: 0);
    board.drag(center + const Vec(-50, 60), time: .1);
    board.update(.1, producing: false);
    board.releasePointer();
    final parked = board.segments.single;
    expect((parked.a - segment.a).length, greaterThan(20));
    final ball = Ball(board.nextId++, const Vec(100, 250), Vec.zero);
    board.balls.add(ball);
    board.touch(ball.position);
    expect(board.heldBall, same(ball));
    board.releasePointer(cancel: true);
    expect(board.segments.single.a.x, parked.a.x);
    expect(board.segments.single.a.y, parked.a.y);
  });

  test(
    'production boundary cancels grip and freezes all non-coin activity',
    () {
      final session = GameSession(catalog, MemoryStore())
        ..levels.addAll({'broom': 1, 'paddle': 1, 'robot': 1})
        ..startDay();
      final board = session.board!;
      final ball = Ball(board.nextId++, const Vec(100, 250), Vec.zero);
      board.balls.add(ball);
      session.cycle!.remaining = 3 + 1 / 60;
      session.touch(ball.position, time: 0);
      session.drag(const Vec(140, 250), time: .01);
      session.tick(1 / 60);
      expect(session.phase, DayPhase.closing);
      expect(board.heldBall, isNull);
      expect(ball.velocity.length, 0);
      final position = ball.position;
      final robot = board.robot.position;
      final spawn = board.spawnClock;
      final captured = board.captured;
      final generated = session.economy.generated;
      session.touch(position);
      session.drag(Board.hole);
      frames(session, 60);
      session.release();
      expect(ball.position, position);
      expect(board.robot.position, robot);
      expect(board.spawnClock, spawn);
      expect(board.captured, captured);
      expect(session.economy.generated, generated);
    },
  );

  test(
    'closing coins land, collect and bank once after exactly three seconds',
    () {
      final session = GameSession(catalog, MemoryStore())..startDay();
      final board = session.board!;
      session.cycle!.remaining = 3 + 1 / 60;
      board.captured = 1;
      session.economy.generated = 2;
      board.coins.add(Coin(board.nextId++, const Vec(90, 300), 2));
      session.tick(1 / 60);
      frames(session, 15);
      session.touch(const Vec(90, 300));
      session.release();
      expect(session.economy.collected, 2);
      frames(session, 164);
      expect(session.running, isTrue);
      frames(session, 1);
      expect(session.running, isFalse);
      expect(session.economy.balance, 2);
      session.finishDay();
      expect(session.economy.balance, 2);
    },
  );

  test('closing reload remains frozen and paused without restoring grips', () {
    final session = GameSession(catalog, MemoryStore())..startDay();
    final board = session.board!;
    board.balls.add(
      Ball(board.nextId++, const Vec(100, 250), const Vec(50, 0)),
    );
    session.cycle!.remaining = 2;
    final restored = GameSession(catalog, MemoryStore())
      ..restore(session.snapshot());
    final ball = restored.board!.balls.single;
    final position = ball.position;
    frames(restored, 60);
    expect(restored.cycle!.remaining, 2);
    restored.resume();
    restored.touch(position);
    restored.drag(Board.hole);
    frames(restored, 60);
    expect(ball.position, position);
    expect(restored.cycle!.remaining, closeTo(1, .0001));
    expect(restored.board!.heldBall, isNull);
  });

  test(
    'old board saves keep broom locked and invalid physical item data is rejected',
    () {
      final board = Board(catalog.settings({}));
      final old = board.toJson()
        ..remove('broomPosition')
        ..remove('broomAngle');
      expect(Board.fromJson(board.settings, old).segments, isEmpty);
      final bad =
          jsonDecode(jsonEncode(board.toJson())) as Map<String, dynamic>;
      bad['broomPosition'] = [-100, 40];
      expect(() => Board.fromJson(board.settings, bad), throwsFormatException);
    },
  );
  test(
    'explicit coin-only state cannot spawn or capture even if producing is requested',
    () {
      final board = Board(catalog.settings({}));
      board.balls.add(Ball(board.nextId++, Board.hole, Vec.zero));
      board.enterClosing();
      final events = board.update(1, producing: true);
      expect(events.captured, 0);
      expect(board.spawnClock, 0);
      expect(board.balls, hasLength(1));
    },
  );

  test(
    'broom pose survives reload without a held gesture and can be picked up again',
    () {
      final session = GameSession(catalog, MemoryStore())
        ..levels.addAll({'hand': 2, 'broom': 1})
        ..startDay();
      final board = session.board!;
      board.touch(board.broomPosition, time: 0);
      board.drag(const Vec(220, 230), time: .1);
      board.update(.2, producing: false);
      final position = board.broomPosition;
      final angle = board.toolAngle;
      final restored = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      expect(restored.board!.broomPosition.x, closeTo(position.x, .0001));
      expect(restored.board!.broomPosition.y, closeTo(position.y, .0001));
      expect(restored.board!.toolAngle, closeTo(angle, .0001));
      expect(restored.board!.holdingBroom, isFalse);
      expect(restored.board!.target, isNull);
      restored.resume();
      restored.touch(restored.board!.broomPosition);
      expect(restored.board!.holdingBroom, isTrue);
      final oldAngle = restored.board!.toolAngle;
      restored.release(cancel: true);
      expect(restored.board!.toolAngle, oldAngle);
    },
  );

  test('parked broom keeps its collision geometry after release', () {
    final board = Board(catalog.settings({'broom': 1}));
    board.broomPosition = const Vec(180, 200);
    final ball = Ball(board.nextId++, const Vec(180, 190), const Vec(0, 120));
    board.balls.add(ball);
    board.touch(board.broomPosition);
    board.releasePointer();
    for (var i = 0; i < 60; i++) {
      board.update(1 / 240, producing: false);
    }
    expect(
      ball.position.y,
      lessThanOrEqualTo(200 - board.radius - Board.broomThickness),
    );
    expect(board.broomPosition.x, 180);
    expect(board.broomPosition.y, 200);
  });

  test(
    'closing cancels a held broom and keeps sweeps available only when purchased',
    () {
      for (final sweep in [false, true]) {
        final session = GameSession(catalog, MemoryStore())
          ..levels.addAll({'broom': 1, if (sweep) 'sweep': 1})
          ..startDay();
        final board = session.board!;
        session.cycle!.remaining = 3 + 1 / 60;
        session.touch(board.broomPosition);
        session.drag(const Vec(240, 200));
        session.tick(1 / 60);
        expect(board.holdingBroom, isFalse);
        final position = board.broomPosition;
        final angle = board.toolAngle;
        session.touch(position);
        session.drag(Board.hole);
        frames(session, 10);
        session.release();
        expect(board.broomPosition, position);
        expect(board.toolAngle, angle);
        board.captured = 1;
        session.economy.generated = 2;
        board.coins.add(
          Coin(board.nextId++, const Vec(100, 300), 2, landing: 0),
        );
        session.touch(const Vec(50, 300));
        session.drag(const Vec(150, 300));
        session.release();
        expect(session.economy.collected, sweep ? 2 : 0);
      }
    },
  );

  test(
    'closing overlay dims scenery, balls and broom but leaves coins bright',
    () async {
      final session = GameSession(catalog, MemoryStore())
        ..levels.addAll({'hand': 2, 'broom': 1})
        ..startDay();
      final board = session.board!;
      board.balls.add(Ball(board.nextId++, const Vec(100, 200), Vec.zero));
      board.coins.add(Coin(board.nextId++, const Vec(100, 300), 2, landing: 0));
      final game = GardenGame(session)..onGameResize(Vector2(360, 560));
      Future<List<int>> pixels() async {
        final recorder = ui.PictureRecorder();
        game.render(ui.Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(360, 560);
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final result = List<int>.of(data.buffer.asUint8List());
        image.dispose();
        picture.dispose();
        return result;
      }

      final day = await pixels();
      board.enterClosing();
      final closing = await pixels();
      List<int> color(List<int> image, int x, int y) =>
          image.sublist((y * 360 + x) * 4, (y * 360 + x) * 4 + 3);
      expect(color(closing, 105, 297), color(day, 105, 297));
      for (final point in [
        const Vec(40, 250),
        const Vec(100, 200),
        board.broomPosition,
      ]) {
        final before = color(day, point.x.round(), point.y.round());
        final after = color(closing, point.x.round(), point.y.round());
        expect(
          after.reduce((a, b) => a + b),
          lessThan(before.reduce((a, b) => a + b) * .5),
        );
      }
      await session.pendingWrites;
      session.dispose();
    },
  );
  test(
    'closing purchased magnet follows the finger without moving objects',
    () {
      final board = Board(catalog.settings({'collection': 1, 'magnet': 1}));
      final ball = Ball(board.nextId++, const Vec(200, 300), const Vec(40, 0));
      board.balls.add(ball);
      board.coins.add(Coin(board.nextId++, const Vec(240, 300), 2, landing: 0));
      board.enterClosing();
      final ballPosition = ball.position;
      final broomPosition = board.broomPosition;
      final broomAngle = board.toolAngle;
      board.touch(const Vec(50, 300));
      board.drag(const Vec(200, 300));
      var collected = 0;
      for (var i = 0; i < 60; i++) {
        collected += board.update(1 / 60, producing: false).collected;
      }
      expect(collected, 2);
      expect(board.pending, 0);
      expect(board.heldBall, isNull);
      expect(ball.position, ballPosition);
      expect(board.broomPosition, broomPosition);
      expect(board.toolAngle, broomAngle);
      expect(board.releasePointer(), 0);
    },
  );
}
