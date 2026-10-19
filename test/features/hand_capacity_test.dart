import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flame/components.dart' show Vector2;
import 'package:incremental_hole_game/features/board/presentation/garden_game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/tool.dart';
import '../test_support.dart';

void step(Board board, [int frames = 30]) {
  for (var i = 0; i < frames; i++) {
    board.update(1 / 240, producing: false);
  }
}

Ball ball(Board board, Vec position) {
  final result = Ball(board.nextId++, position, Vec.zero);
  board.balls.add(result);
  return result;
}

void main() {
  final catalog = testCatalog();

  test('empty hand never attracts, even when dragged past balls', () {
    final board = Board(catalog.settings({'hand': 4}));
    final first = ball(board, const Vec(100, 200));
    board.touch(const Vec(50, 200));
    board.drag(first.position);
    step(board);
    expect(board.heldBalls, isEmpty);
    expect(first.position.x, 100);
    board.releasePointer();
  });

  test(
    'base hand stays single; purchased capacities attract only up to limit',
    () {
      for (var level = 0; level <= 4; level++) {
        final board = Board(catalog.settings({'hand': level}));
        final first = ball(board, const Vec(100, 200));
        for (final offset in [
          const Vec(26, 0),
          const Vec(-26, 0),
          const Vec(0, 26),
          const Vec(0, -26),
          const Vec(25, 25),
        ]) {
          ball(board, first.position + offset);
        }
        final distant = ball(board, const Vec(280, 300));
        board.touch(first.position);
        step(board);
        expect(board.heldBall, same(first));
        expect(board.heldBalls, hasLength(level + 1));
        expect(board.heldBalls, isNot(contains(distant)));
        board.drag(const Vec(180, 250));
        step(board, 60);
        for (final held in board.heldBalls) {
          expect((held.position - const Vec(180, 250)).length, lessThan(16));
        }
        board.releasePointer(cancel: true);
        expect(board.heldBalls, isEmpty);
      }
    },
  );

  test('second ball is picked up only after approaching it with a grip', () {
    final board = Board(catalog.settings({'hand': 1}));
    final first = ball(board, const Vec(80, 200));
    final second = ball(board, const Vec(160, 200));
    board.touch(first.position);
    step(board);
    expect(board.heldBalls, [first]);
    board.drag(const Vec(140, 200));
    step(board);
    expect(board.heldBalls, containsAll([first, second]));
  });

  test('group flick, cancellation and closing apply to every held ball', () {
    for (final cancel in [false, true]) {
      final board = Board(catalog.settings({'hand': 1}));
      final first = ball(board, const Vec(100, 200));
      final second = ball(board, const Vec(125, 200));
      board.touch(first.position, time: 0);
      board.drag(const Vec(120, 200), time: .1);
      step(board);
      expect(board.heldBalls, hasLength(2));
      board.releasePointer(cancel: cancel, time: .1);
      expect(first.velocity.x, cancel ? 0 : closeTo(200, .001));
      expect(second.velocity.x, first.velocity.x);
      expect(board.heldBalls, isEmpty);
      board.touch(first.position);
      step(board);
      board.enterClosing();
      expect(board.heldBalls, isEmpty);
      expect(first.velocity.length, 0);
      expect(second.velocity.length, 0);
    }
  });

  test(
    'group enters hole once and cannot attract again with an empty grip',
    () {
      final board = Board(catalog.settings({'hand': 1}));
      final first = ball(board, const Vec(180, 330));
      ball(board, const Vec(205, 330));
      board.touch(first.position);
      step(board);
      board.drag(Board.hole);
      step(board, 120);
      expect(board.captured, 2);
      expect(board.heldBalls, isEmpty);
      ball(board, const Vec(180, 350));
      board.drag(const Vec(180, 350));
      step(board);
      expect(board.heldBalls, isEmpty);
    },
  );

  test(
    'capacity persists and reload drops all grips without throwing balls',
    () {
      final session = GameSession(catalog, MemoryStore())
        ..levels['hand'] = 4
        ..startDay();
      final board = session.board!;
      final first = ball(board, const Vec(100, 200));
      ball(board, const Vec(126, 200));
      board.touch(first.position);
      board.drag(const Vec(150, 200));
      step(board);
      final restored = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      expect(restored.levels['hand'], 4);
      expect(restored.board!.handCapacity, 5);
      expect(restored.board!.heldBalls, isEmpty);
      expect(
        restored.board!.balls.every((b) => b.velocity.length == 0),
        isTrue,
      );
    },
  );

  test('pause drops every ball without imparting a throw', () {
    final session = GameSession(catalog, MemoryStore())
      ..levels['hand'] = 1
      ..startDay();
    final board = session.board!;
    final first = ball(board, const Vec(100, 200));
    ball(board, const Vec(125, 200));
    session.touch(first.position);
    session.drag(const Vec(130, 200));
    session.tick(1 / 60);
    expect(board.heldBalls, hasLength(2));
    session.pause();
    expect(board.heldBalls, isEmpty);
    expect(board.balls.every((b) => b.velocity.length == 0), isTrue);
  });

  test('locked broom renders neither its head nor its handle', () async {
    Future<List<int>> pixel({
      required bool unlocked,
      required Vec point,
    }) async {
      final session = GameSession(catalog, MemoryStore());
      if (unlocked) session.levels['broom'] = 1;
      session.startDay();
      final game = GardenGame(session)..onGameResize(Vector2(360, 560));
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      final picture = recorder.endRecording();
      final image = await picture.toImage(360, 560);
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final start = (point.y.toInt() * 360 + point.x.toInt()) * 4;
      final result = data.buffer.asUint8List().sublist(start, start + 4);
      image.dispose();
      picture.dispose();
      await session.pendingWrites;
      session.dispose();
      return result;
    }

    // Initial head is at (300,100), with the handle extending upwards.
    for (final point in [const Vec(300, 100), const Vec(300, 80)]) {
      expect(
        await pixel(unlocked: false, point: point),
        isNot(await pixel(unlocked: true, point: point)),
      );
    }
    const background = Vec(90, 300);
    expect(
      await pixel(unlocked: false, point: background),
      await pixel(unlocked: true, point: background),
    );
  });

  test('bug-era saves load with single hand and no free broom', () {
    final session = GameSession(catalog, MemoryStore())..startDay();
    final json = jsonDecode(session.snapshot()) as Map<String, dynamic>;
    json['tool'] = 'broom';
    json['run']['settings'].remove('hand_capacity');
    final restored = GameSession(catalog, MemoryStore())
      ..restore(jsonEncode(json));
    expect(restored.selectedTool, BallTool.hand);
    expect(restored.board!.handCapacity, 1);
    expect(restored.board!.segments, isEmpty);
  });

  test(
    'broom has no grip or collisions until bought, including after reload',
    () {
      final session = GameSession(catalog, MemoryStore())..startDay();
      final board = session.board!;
      expect(session.toolAvailable(BallTool.broom), isFalse);
      expect(board.canUse(BallTool.broom), isFalse);
      expect(board.segments, isEmpty);
      board.touch(board.broomPosition);
      expect(board.holdingBroom, isFalse);
      board.releasePointer();
      final free = ball(board, board.broomPosition);
      step(board);
      expect((free.position - board.broomPosition).length, 0);
      session.finishDay();
      session.economy.balance = 20;
      expect(
        session.purchase(
          catalog.definitions.firstWhere((d) => d.id == 'broom'),
        ),
        isTrue,
      );
      session.startDay();
      final restored = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      expect(restored.board!.segments, hasLength(1));
      restored.resume();
      restored.touch(restored.board!.broomPosition);
      expect(restored.board!.holdingBroom, isTrue);
    },
  );
}
