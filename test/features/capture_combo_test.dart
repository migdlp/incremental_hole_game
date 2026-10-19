import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flame/components.dart' show Vector2;
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/capture_combo.dart';
import 'package:incremental_hole_game/features/board/domain/coin_denomination.dart';
import 'package:incremental_hole_game/features/board/presentation/garden_game.dart';
import '../test_support.dart';

void capture(GameSession session, {bool golden = false}) {
  final board = session.board!;
  board.balls.add(Ball(board.nextId++, Board.hole, Vec.zero, golden: golden));
  session.tick(1 / 60);
}

void advance(GameSession session, double seconds) {
  for (var i = 0; i < (seconds * 60).round(); i++) {
    session.tick(1 / 60);
  }
}

void main() {
  final catalog = testCatalog();

  test(
    'fifth and tenth capture use new multiplier without retroactive awards',
    () {
      final combo = CaptureCombo();
      expect(List.generate(12, (_) => combo.capture(golden: false)), [
        1,
        1,
        1,
        1,
        2,
        2,
        2,
        2,
        2,
        3,
        3,
        3,
      ]);
      expect(combo.bonusUnits, 11);
      expect(combo.multiplier, 3);
      combo.advance(.8);
      expect(combo.capture(golden: false), 3);
    },
  );

  test('one second is inclusive; exceeding it resets rewards and streak', () {
    final combo = CaptureCombo();
    for (var i = 0; i < 4; i++) {
      combo.capture(golden: false);
    }
    combo.advance(1);
    expect(combo.capture(golden: false), 2);
    combo.advance(1.0001);
    expect(combo.multiplier, 1);
    expect(combo.streak, 0);
    expect(combo.capture(golden: false), 1);
    expect(combo.bonusUnits, 1);
  });

  test('golden and purchased values multiply the current capture only', () {
    final session = GameSession(catalog, MemoryStore())
      ..levels.addAll({'hand': 1, 'reward': 2})
      ..startDay();
    var expectedUnits = 0;
    for (var i = 1; i <= 12; i++) {
      final golden = i == 5 || i == 10;
      expectedUnits +=
          (golden ? 10 : 1) *
          (i < 5
              ? 1
              : i < 10
              ? 2
              : 3);
      capture(session, golden: golden);
      expect(session.economy.generated, expectedUnits * 3);
      expect(session.economy.collected, 0);
      expect(session.economy.balance, 0);
      expect(session.board!.pending, expectedUnits * 3);
    }
    expect(
      session.board!.coins.every(
        (c) => CoinDenomination.values.any((d) => d.amount == c.value),
      ),
      isTrue,
    );
    session.finishDay();
    expect(session.economy.balance, 0);
    expect(session.progress.last!.generated, expectedUnits * 3);
    session.startDay();
    expect(session.board!.combo.streak, 0);
    capture(session);
    expect(session.economy.generated, 3);
  });

  test(
    'same-step normal and golden captures keep their order at threshold',
    () {
      final session = GameSession(catalog, MemoryStore())..startDay();
      for (var i = 0; i < 3; i++) {
        capture(session);
      }
      final board = session.board!;
      board.balls.addAll([
        Ball(board.nextId++, Board.hole + const Vec(-6, 0), Vec.zero),
        Ball(
          board.nextId++,
          Board.hole + const Vec(6, 0),
          Vec.zero,
          golden: true,
        ),
      ]);
      session.tick(1 / 60);
      expect(board.captured, 5);
      expect(session.economy.generated, 3 + 1 + 20);
    },
  );

  test('combo money still requires pickup and is banked exactly once', () {
    final session = GameSession(catalog, MemoryStore())..startDay();
    for (var i = 0; i < 10; i++) {
      capture(session, golden: i == 9);
    }
    final board = session.board!;
    expect(session.economy.generated, 44);
    for (final coin in List.of(board.coins)) {
      coin.landing = 0;
      session.touch(coin.position);
      session.release();
    }
    expect(session.economy.collected, 44);
    expect(board.pending, 0);
    expect(session.economy.balance, 0);
    session.finishDay();
    session.finishDay();
    expect(session.economy.balance, 44);
    final reopened = GameSession(catalog, MemoryStore())
      ..restore(session.snapshot());
    reopened.finishDay();
    expect(reopened.economy.balance, 44);
  });

  test(
    'pause, reload and closing preserve accounting without gifting time',
    () {
      final session = GameSession(catalog, MemoryStore())..startDay();
      for (var i = 0; i < 9; i++) {
        capture(session);
      }
      advance(session, .5);
      session.pause();
      final remaining = session.board!.combo.remaining;
      session.tick(.1);
      expect(session.board!.combo.remaining, remaining);
      final reopened = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      expect(reopened.paused, isTrue);
      expect(reopened.board!.combo.remaining, remaining);
      reopened.resume();
      capture(reopened, golden: true);
      expect(reopened.board!.combo.multiplier, 3);
      expect(reopened.economy.generated, 14 + 30);
      advance(reopened, 1.1);
      expect(reopened.board!.combo.multiplier, 1);
      // An expired chain is not lost from generated-income accounting.
      final expired = GameSession(catalog, MemoryStore())
        ..restore(reopened.snapshot());
      expect(expired.economy.generated, 44);
      expired.board!.enterClosing();
      final before = expired.economy.generated;
      capture(expired);
      expect(expired.board!.combo.streak, 0);
      expect(expired.economy.generated, before);
    },
  );

  test(
    'active v5 day keeps old rewards across reload; next day gains combos',
    () {
      final original = GameSession(catalog, MemoryStore())..startDay();
      final old = jsonDecode(original.snapshot()) as Map<String, dynamic>;
      old['version'] = 5;
      old['run']['board'].remove('combo');
      final migrated = GameSession(catalog, MemoryStore())
        ..restore(jsonEncode(old));
      expect(migrated.board!.combo.enabled, isFalse);
      migrated.resume();
      for (var i = 0; i < 10; i++) {
        capture(migrated);
      }
      expect(migrated.economy.generated, 10);
      final reopened = GameSession(catalog, MemoryStore())
        ..restore(migrated.snapshot());
      expect(reopened.board!.combo.enabled, isFalse);
      expect(reopened.economy.generated, 10);
      reopened.finishDay();
      reopened.startDay();
      for (var i = 0; i < 5; i++) {
        capture(reopened);
      }
      expect(reopened.economy.generated, 6);
    },
  );

  test('invalid combo state and altered rewards reject restore atomically', () {
    final session = GameSession(catalog, MemoryStore())..startDay();
    for (var i = 0; i < 5; i++) {
      capture(session);
    }
    final pristine = session.snapshot();
    for (final mutation in <void Function(Map<String, dynamic>)>[
      (j) => j['run']['board']['combo']['remaining'] = 2,
      (j) => j['run']['board']['combo']['streak'] = 6,
      (j) => j['run']['board']['combo']['bonusUnits'] = -1,
      (j) => j['run']['board']['combo']['bonusUnits'] = 2,
      (j) => j['run']['board']['combo']['enabled'] = false,
      (j) => j['run']['board'].remove('combo'),
    ]) {
      final json = jsonDecode(pristine) as Map<String, dynamic>;
      mutation(json);
      expect(() => session.restore(jsonEncode(json)), throwsFormatException);
      expect(session.snapshot(), pristine);
    }
  });

  test(
    'combo feedback appears only for active multipliers, not in closing',
    () async {
      final session = GameSession(catalog, MemoryStore())..startDay();
      final game = GardenGame(session)..onGameResize(Vector2(360, 560));
      Future<List<int>> pixel() async {
        final recorder = ui.PictureRecorder();
        game.render(ui.Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(360, 560);
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final color = data.buffer.asUint8List().sublist(
          (150 * 360 + 110) * 4,
          (150 * 360 + 110) * 4 + 3,
        );
        image.dispose();
        picture.dispose();
        return color;
      }

      final initial = await pixel();
      session.board!.coinOnly = true;
      final closingBackground = await pixel();
      session.board!.coinOnly = false;
      for (var i = 0; i < 5; i++) {
        capture(session);
      }
      expect(await pixel(), isNot(initial));
      advance(session, 1.1);
      expect(await pixel(), initial);
      for (var i = 0; i < 10; i++) {
        capture(session);
      }
      expect(session.board!.combo.multiplier, 3);
      expect(await pixel(), isNot(initial));
      session.board!.enterClosing();
      expect(await pixel(), closingBackground);
      await session.pendingWrites;
      session.dispose();
    },
  );
}
