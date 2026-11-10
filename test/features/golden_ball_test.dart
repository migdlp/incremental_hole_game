import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flame/components.dart' show Vector2;
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/presentation/garden_game.dart';
import '../test_support.dart';

class RollsBoard extends Board {
  RollsBoard(super.settings, this.rolls);
  final List<double> rolls;
  int index = 0;
  @override
  double random() => rolls[index++ % rolls.length];
}

void main() {
  final catalog = testCatalog();

  test('golden chance is one percent per successfully emitted ball', () {
    for (final roll in [.0, .009999, .01, .5, .99999]) {
      final board = RollsBoard(catalog.settings({}), [roll]);
      board.spawnClock = board.settings['spawn_interval'];
      board.update(1 / 60, producing: true);
      expect(board.balls.single.golden, roll < .01);
    }
    final pair = RollsBoard(catalog.settings({'double_spawn': 1}), [
      .5,
      .5,
      .009,
      .5,
      .02,
    ]);
    pair.spawnClock = pair.settings['spawn_interval'];
    pair.update(1 / 60, producing: true);
    expect(pair.balls.map((b) => b.golden), [true, false]);
    final full = RollsBoard(catalog.settings({})..values['ball_limit'] = 1, [
      .001,
    ]);
    full.balls.add(Ball(full.nextId++, const Vec(50, 300), Vec.zero));
    full.spawnClock = full.settings['spawn_interval'];
    full.update(1 / 60, producing: true);
    expect(full.balls.single.golden, isFalse);
    full.enterClosing();
    full.balls.clear();
    full.update(1, producing: true);
    expect(full.balls, isEmpty);
  });

  test(
    'base golden capture creates a ten dollar denomination and banks once',
    () {
      final session = GameSession(catalog, MemoryStore())..startDay();
      final board = session.board!;
      board.balls.add(Ball(board.nextId++, Board.hole, Vec.zero, golden: true));
      for (var i = 0; i < 16; i++) {
        session.tick(1 / 60);
      }
      expect(board.captured, 1);
      expect(board.goldenCaptured, 1);
      expect(session.economy.generated, 10);
      expect(session.rewards.outstanding, 10);
      expect(board.coins, isEmpty);
      session.finishDay();
      session.finishDay();
      expect(session.economy.balance, 10);
      expect(session.progress.last!.captured, 1);
    },
  );

  test(
    'mixed captures use ten times the purchased value for each golden ball',
    () {
      final session = GameSession(catalog, MemoryStore())
        ..levels.addAll({'hand': 1, 'reward': 2})
        ..startDay();
      final board = session.board!;
      for (final golden in [false, true, false, true]) {
        board.balls.add(
          Ball(board.nextId++, Board.hole, Vec.zero, golden: golden),
        );
      }
      session.tick(1 / 60);
      expect(board.captured, 4);
      expect(board.goldenCaptured, 2);
      expect(session.economy.generated, (2 + 20) * 3);
      expect(session.rewards.outstanding, 66);
      final restored = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      expect(restored.economy.generated, 66);
      expect(restored.board!.goldenCaptured, 2);
      restored.resume();
      restored.tick(1 / 60);
      expect(restored.economy.generated, 66);
    },
  );

  test(
    'golden type, capture accounting and random sequence survive reload',
    () {
      final session = GameSession(catalog, MemoryStore())..startDay();
      final board = session.board!;
      board.balls.add(
        Ball(board.nextId++, const Vec(100, 200), Vec.zero, golden: true),
      );
      final restored = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      final loaded = restored.board!;
      expect(loaded.balls.single.golden, isTrue);
      loaded.balls.single.position = Board.hole;
      restored.resume();
      restored.tick(1 / 60);
      expect(restored.economy.generated, 10);
      expect(loaded.goldenCaptured, 1);
      final reopened = GameSession(catalog, MemoryStore())
        ..restore(restored.snapshot());
      expect(reopened.economy.generated, 10);
      expect(reopened.board!.goldenCaptured, 1);
      final a = Board.fromJson(board.settings, board.toJson());
      for (var i = 0; i < 300; i++) {
        board.balls.clear();
        a.balls.clear();
        board.spawnClock = a.spawnClock = board.settings['spawn_interval'];
        board.update(1 / 60, producing: true);
        a.update(1 / 60, producing: true);
        expect(a.balls.single.golden, board.balls.single.golden);
        expect(a.randomState, board.randomState);
      }
    },
  );

  test(
    'old board data restores normal balls and invalid golden accounting is rejected atomically',
    () {
      final session = GameSession(catalog, MemoryStore())..startDay();
      final board = session.board!;
      board.balls.add(Ball(board.nextId++, const Vec(100, 200), Vec.zero));
      final json = jsonDecode(session.snapshot()) as Map<String, dynamic>;
      final saved = json['run']['board'];
      saved.remove('goldenCaptured');
      saved['balls'][0].remove('golden');
      final restored = GameSession(catalog, MemoryStore())
        ..restore(jsonEncode(json));
      expect(restored.board!.goldenCaptured, 0);
      expect(restored.board!.balls.single.golden, isFalse);
      saved['goldenCaptured'] = 1;
      expect(() => restored.restore(jsonEncode(json)), throwsFormatException);
      expect(restored.board!.goldenCaptured, 0);
      saved['goldenCaptured'] = -1;
      expect(() => restored.restore(jsonEncode(json)), throwsFormatException);
      saved['goldenCaptured'] = 0;
      saved['balls'][0]['golden'] = 'yes';
      expect(() => restored.restore(jsonEncode(json)), throwsFormatException);
      // Even a numerically plausible capture count must match generated money.
      saved['balls'][0]['golden'] = false;
      saved['captured'] = 1;
      saved['goldenCaptured'] = 1;
      json['run']['generated'] = 1;
      json['run']['collected'] = 1;
      expect(() => restored.restore(jsonEncode(json)), throwsFormatException);
    },
  );

  test(
    'golden ball is visibly gold while an ordinary ball stays gray',
    () async {
      final session = GameSession(catalog, MemoryStore())..startDay();
      final board = session.board!;
      board.balls.addAll([
        Ball(board.nextId++, const Vec(100, 200), Vec.zero),
        Ball(board.nextId++, const Vec(200, 200), Vec.zero, golden: true),
      ]);
      final game = GardenGame(session)..onGameResize(Vector2(360, 560));
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      final picture = recorder.endRecording();
      final image = await picture.toImage(360, 560);
      final pixels = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      List<int> at(int x, int y) => pixels.buffer.asUint8List().sublist(
        (y * 360 + x) * 4,
        (y * 360 + x) * 4 + 3,
      );
      expect(at(103, 202), [0x69, 0x75, 0x83]);
      expect(at(203, 202), [0xea, 0xb3, 0x08]);
      image.dispose();
      picture.dispose();
      await session.pendingWrites;
      session.dispose();
    },
  );
}
