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

void carryGently(Board board, Vec destination, {double seconds = 1}) {
  final start = board.target!;
  final frames = (seconds * 240).round();
  for (var i = 1; i <= frames; i++) {
    board.drag(start + (destination - start) * (i / frames));
    step(board, 1);
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
      for (var level = 0; level <= 5; level++) {
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
        carryGently(board, const Vec(180, 250));
        step(board, 240);
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
      expect(
        second.velocity.x,
        cancel ? 0 : inExclusiveRange(0, first.velocity.x),
      );
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
      carryGently(board, Board.hole);
      step(board, 240);
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

  test('magnetic pickup eases in over time instead of snapping into place', () {
    final board = Board(catalog.settings({'hand': 1}));
    final first = ball(board, const Vec(100, 250));
    final second = ball(board, const Vec(130, 250));
    board.touch(first.position);
    step(board, 1);
    expect(second.position.x, closeTo(130, .1));
    step(board, 23); // 100 ms: still approaching its slot at x=114.
    expect(second.position.x, inExclusiveRange(120, 130));
    step(board, 216); // Settles after a short, visible delay.
    expect(second.position.x, closeTo(114, 1));
    expect(second.velocity.length, lessThan(2));
  });

  test('gentle movement keeps the group with visible lag', () {
    final board = Board(catalog.settings({'hand': 1}));
    final first = ball(board, const Vec(80, 250));
    final second = ball(board, const Vec(110, 250));
    board.touch(first.position);
    step(board, 240);
    carryGently(board, const Vec(180, 250));
    expect(board.heldBalls, containsAll([first, second]));
    expect(second.position.x, lessThan(first.position.x + 10));
    step(board, 240);
    expect(second.position.x, closeTo(194, 1));
  });

  test(
    'a sharp pull breaks the extra grip, keeps momentum and cannot reattach immediately',
    () {
      final board = Board(catalog.settings({'hand': 1}));
      final first = ball(board, const Vec(80, 250));
      final second = ball(board, const Vec(110, 250));
      board.touch(first.position);
      step(board, 240);
      board.drag(const Vec(320, 250));
      step(board, 72);
      expect(board.heldBalls, [first]);
      expect(second.velocity.length, greaterThan(0));
      final position = second.position;
      step(board, 12);
      expect((second.position - position).length, greaterThan(0));
      // Bring the manually held ball close again while keeping the gesture active.
      board.drag(second.position - const Vec(20, 0));
      step(board, 240);
      expect(board.heldBalls, [first]);
      board.releasePointer(cancel: true);
      board.touch(second.position);
      expect(board.heldBall, same(second));
    },
  );

  test('spring motion and breakage are consistent at 30, 60 and 120 fps', () {
    Vec run(int hz) {
      final board = Board(catalog.settings({'hand': 1}));
      final first = ball(board, const Vec(80, 250));
      final second = ball(board, const Vec(110, 250));
      board.touch(first.position);
      step(board, 240);
      for (var i = 1; i <= hz; i++) {
        board.drag(Vec(80 + 100 * i / hz, 250));
        board.update(1 / hz, producing: false);
      }
      expect(board.heldBalls, hasLength(2));
      board.drag(const Vec(350, 250));
      for (var i = 0; i < hz ~/ 2; i++) {
        board.update(1 / hz, producing: false);
      }
      expect(board.heldBalls, [first]);
      return second.position;
    }

    final baseline = run(60);
    expect((run(30) - baseline).length, lessThan(5));
    expect((run(120) - baseline).length, lessThan(5));
  });

  test(
    'capturing the manual ball frees its slot without promoting a spring to a rigid grip',
    () {
      final board = Board(catalog.settings({'hand': 1}));
      final first = ball(board, Board.hole + const Vec(0, 52));
      final second = ball(board, Board.hole + const Vec(26, 52));
      board.touch(first.position);
      step(board, 240);
      first.position = Board.hole;
      board.drag(Board.hole);
      step(board, 1);
      expect(board.captured, 1);
      expect(board.heldBalls, [second]);
      final third = ball(board, Board.hole + const Vec(40, 42));
      step(board, 1);
      expect(board.heldBalls, containsAll([second, third]));
      expect(second.position.y, greaterThan(Board.hole.y + 42));
    },
  );

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
    json['version'] = 3;
    json['run']['board'].remove('combo');
    json['run']['board'].remove('specials');
    json['run']['board'].remove('captureAllIds');
    json['run']['balanceVersion'] = 3;
    json['run']['settings'] = catalog.settings({}, balanceVersion: 3).toJson();
    json['run']['remaining'] = 15;
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
      session.levels['hand'] = 2;
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
