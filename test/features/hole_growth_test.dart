import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/presentation/garden_game.dart';
import '../test_support.dart';

void main() {
  final catalog = testCatalog(automaticSpawns: false);
  GameSession start([MemoryStore? store]) =>
      GameSession(catalog, store ?? MemoryStore())..startDay();
  void capture(GameSession s, int amount) {
    final b = s.board!;
    for (var i = 0; i < amount; i++) {
      b.balls.add(Ball(b.nextId++, b.holePosition, Vec.zero));
    }
    s.tick(1 / 60);
  }

  Future<void> nextDay(GameSession s) async {
    for (var i = 0; i < 1; i++) {
      s.finishDay();
      await s.pendingWrites;
      s.startDay();
    }
  }

  test(
    'quota completion grows area by 16% immediately, once per quota',
    () async {
      final s = start();
      final base = s.board!.captureRadius;
      capture(s, 99);
      expect(s.board!.captureRadius, base);
      capture(s, 1);
      expect(s.feeding.growths, 1);
      expect(s.board!.captureRadius / base, closeTo(math.sqrt(1.16), 1e-12));
      capture(s, 30);
      s.tick(.1);
      expect(s.feeding.growths, 1);
      await nextDay(s);
      expect(s.feeding.period, 2);
      expect(s.board!.captureRadius / base, closeTo(math.sqrt(1.16), 1e-12));
      capture(s, s.feeding.remaining!.toInt());
      expect(s.feeding.growths, 2);
      expect(s.board!.captureRadius / base, closeTo(1.16, 1e-12));
      expect(
        math.pow(s.board!.captureRadius / base, 2),
        closeTo(math.pow(1.16, 2), 1e-12),
      );
      s.dispose();
    },
  );

  test('new capture zone catches a ball outside the original radius', () {
    final s = start();
    final base = s.board!.captureRadius;
    capture(s, 100);
    final b = s.board!;
    final before = b.captured;
    final distance = (base + b.captureRadius) / 2;
    b.balls.add(
      Ball(
        b.nextId++,
        b.holePosition + Vec(distance, 0),
        Vec.zero,
        golden: true,
      ),
    );
    s.tick(1 / 60);
    expect(b.captured, before + 1);
    expect(s.economy.generated, 110);
    expect(s.feeding.growths, 1);
    s.dispose();
  });

  test(
    'disk restart and repeated restore preserve growth without applying it again',
    () async {
      final store = MemoryStore();
      final s = start(store);
      capture(s, 100);
      await s.pendingWrites;
      final saved = store.candidates.first;
      final restored = GameSession(catalog, store);
      await restored.load();
      final radius = s.board!.captureRadius;
      expect(restored.feeding.growths, 1);
      expect(restored.board!.captureRadius, radius);
      for (var i = 0; i < 3; i++) {
        restored.restore(saved);
        restored.resume();
        restored.tick(.1);
        expect(restored.feeding.growths, 1);
        expect(restored.board!.captureRadius, radius);
      }
      restored.finishDay();
      restored.startDay();
      expect(restored.board!.captureRadius, radius);
      s.dispose();
      restored.dispose();
    },
  );

  test('extreme growth covers the physical board without overflow', () {
    final board = Board(catalog.settings({}))..syncHoleGrowth(100000);
    expect(board.captureRadius.isFinite, isTrue);
    expect(board.holeGrowths, 100000);
    board.balls.add(Ball(1, const Vec(350, 550), Vec.zero));
    board.update(1 / 60, producing: true);
    expect(board.captured, 1);
  });

  test('fast balls use the enlarged swept capture zone', () {
    for (final growths in [0, 4]) {
      final board = Board(catalog.settings({}))..syncHoleGrowth(growths);
      board.balls.add(
        Ball(1, board.holePosition + const Vec(26, -18), const Vec(0, 380)),
      );
      board.update(.1, producing: true);
      expect(board.captured, growths == 0 ? 0 : 1);
    }
  });

  test('invalid growth records reject restoration atomically', () {
    final s = start();
    capture(s, 100);
    final original = s.snapshot();
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (j) => j['feeding']['growths'] = -1,
      (j) => j['feeding']['growths'] = 2,
      (j) => j['feeding']['growthPeriod'] = 0,
      (j) => j['feeding'].remove('growths'),
    ]) {
      final j = jsonDecode(original) as Map<String, dynamic>;
      mutate(j);
      expect(() => s.restore(jsonEncode(j)), throwsFormatException);
      expect(s.snapshot(), original);
    }
    s.dispose();
  });

  test('DEBUG growth is discarded on exit and run reset clears it', () async {
    final s = GameSession(catalog, MemoryStore());
    final baseline = s.snapshot();
    s.enterDebug();
    s.startDay();
    capture(s, 100);
    expect(s.feeding.growths, 1);
    s.finishDay();
    s.debugBuyAll();
    expect(s.debugPurchase('prestige', 1, confirmPrestige: true), isTrue);
    expect(s.beginNewRun(), isTrue);
    expect(s.feeding.growths, 0);
    s.startDay();
    expect(s.board!.captureRadius, 22);
    s.exitDebug();
    expect(s.snapshot(), baseline);
    s.dispose();
  });

  test('visible dark hole and real capture radius grow together', () async {
    final s = start();
    capture(s, 100);
    final game = GardenGame(s)..onGameResize(Vector2(360, 560));
    final recorder = ui.PictureRecorder();
    game.render(ui.Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(360, 560);
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    // Rightmost interior edge: dark capture circle extends beyond the old 22px.
    final x = (s.board!.holePosition.x + s.board!.captureRadius - 1).floor();
    final y = s.board!.holePosition.y.floor();
    final offset = (y * 360 + x) * 4;
    expect(data.getUint8(offset), lessThan(40));
    expect(data.getUint8(offset + 1), lessThan(60));
    image.dispose();
    picture.dispose();
    s.dispose();
  });
}
