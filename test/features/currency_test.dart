import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/coin_denomination.dart';
import 'package:incremental_hole_game/features/board/presentation/coin_painter.dart';
import '../test_support.dart';

void main() {
  final catalog = testCatalog();

  test('base capture creates one dollar, collected and banked only once', () {
    final session = GameSession(catalog, MemoryStore())..startDay();
    session.board!.balls.add(
      Ball(session.board!.nextId++, Board.hole, Vec.zero),
    );
    for (var i = 0; i < 16; i++) {
      session.tick(1 / 60);
    }
    expect(session.economy.generated, 1);
    final point = session.board!.coins.single.position;
    expect(session.board!.coins.single.value, 1);
    session.touch(point);
    session.release();
    session.touch(point);
    session.release();
    session.finishDay();
    session.finishDay();
    expect(session.economy.balance, 1);
    expect(session.progress.last!.income, 1);
  });

  test(
    'denominations preserve every dollar including mixed and large piles',
    () {
      expect(CoinDenomination.values.map((d) => d.amount), [
        1,
        10,
        50,
        100,
        500,
      ]);
      for (final amount in [
        1,
        9,
        10,
        25,
        49,
        50,
        99,
        100,
        499,
        500,
        661,
        1000001,
      ]) {
        final stacks = CoinDenomination.split(amount);
        expect(
          stacks.fold<int>(
            0,
            (sum, s) => sum + s.count * s.denomination.amount,
          ),
          amount,
        );
        expect(stacks.length, lessThanOrEqualTo(5));
        expect(stacks.every((s) => s.count > 0), isTrue);
      }
      final settings = catalog.settings({})..values['coin_pile_limit'] = 2;
      final board = Board(settings);
      for (var i = 0; i < 1000; i++) {
        board.releaseCoin(661);
      }
      final restored = Board.fromJson(settings, board.toJson());
      expect(restored.coins.length, lessThanOrEqualTo(2));
      expect(restored.pending, 661000);
    },
  );

  test(
    'coin faces use their denomination color with no central numeral',
    () async {
      for (final denomination in CoinDenomination.values) {
        final recorder = ui.PictureRecorder();
        paintCoin(Canvas(recorder), const Offset(20, 20), denomination);
        final picture = recorder.endRecording();
        final image = await picture.toImage(40, 40);
        final pixels = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final color = coinColor(denomination);
        // A numeral or symbol in the center would replace this solid face color.
        for (var y = 17; y <= 21; y++) {
          for (var x = 18; x <= 22; x++) {
            final offset = (y * 40 + x) * 4;
            expect(pixels!.getUint8(offset), (color.r * 255).round());
            expect(pixels.getUint8(offset + 1), (color.g * 255).round());
            expect(pixels.getUint8(offset + 2), (color.b * 255).round());
          }
        }
        picture.dispose();
        image.dispose();
      }
    },
  );
}
