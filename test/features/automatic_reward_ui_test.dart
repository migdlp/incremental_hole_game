import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/special_abilities.dart';
import 'package:incremental_hole_game/features/rewards/presentation/collection_painter.dart';
import 'package:incremental_hole_game/features/board/presentation/garden_game.dart';
import '../test_support.dart';

void main() {
  test(
    '200-ball Capture total preserves every golden and combo reward at any visual budget',
    () async {
      for (final budget in [0, 1, 24]) {
        final s = GameSession(
          testCatalog(automaticSpawns: false),
          MemoryStore(),
        )..enterDebug();
        s.debugPurchase('reward', 5);
        s.debugPurchase('capture_all', 1);
        s.debugSetRewardLimit(budget);
        s.startDay();
        final b = s.board!;
        var expected = 0;
        for (var i = 1; i <= 200; i++) {
          final golden = i % 10 == 0;
          b.balls.add(
            Ball(b.nextId++, const Vec(90, 300), Vec.zero, golden: golden),
          );
          expected +=
              13 *
              (golden ? 10 : 1) *
              (i < 5
                  ? 1
                  : i < 10
                  ? 2
                  : 3);
        }
        b.specials.captureCharge = b.specials.cooldown(
          SpecialAbility.captureAll,
        );
        expect(s.activateSpecial(SpecialAbility.captureAll), isTrue);
        s.tick(1 / 60);
        expect(b.captured, 200);
        expect(s.economy.generated, expected);
        expect(s.feeding.points, BigInt.from(100));
        expect(s.rewardVisuals.activeCount, lessThanOrEqualTo(budget));
        await resolveEvolutionFixture(s);
        s.finishDay();
        expect(s.economy.balance, expected);
        expect(s.progress.last!.lost, 0);
        s.exitDebug();
        expect(s.economy.balance, 0);
        s.dispose();
      }
    },
  );

  testWidgets(
    'reward destination matches the collection grid and real gestures still grab balls',
    (tester) async {
      final s = GameSession(testCatalog(automaticSpawns: false), MemoryStore())
        ..startDay();
      await tester.pumpWidget(GardenApp(session: s));
      await tester.pump();
      await tester.pump();
      final finder = find.byWidgetPredicate((w) => w is GameWidget);
      final game = (tester.widget(finder) as GameWidget).game as GardenGame;
      expect(game.externalCoinLayer, isTrue);
      final layer = find.byKey(const ValueKey('daily-coin-layer'));
      final painter =
          tester.widget<CustomPaint>(layer).painter! as DailyCollectionPainter;
      final target =
          tester.getTopLeft(layer) +
          Offset(painter.grid.x(0), painter.grid.y(0));
      expect(
        tester
            .getRect(find.byKey(const ValueKey('daily-coin-collection')))
            .contains(target),
        isTrue,
      );
      expect(target.dy, lessThan(tester.getTopLeft(finder).dy));
      final b = s.board!;
      b.balls.add(Ball(b.nextId++, b.holePosition, Vec.zero));
      s.tick(1 / 60);
      for (var i = 0; i < 70; i++) {
        s.tick(1 / 60);
      }
      final ball = Ball(b.nextId++, const Vec(100, 250), Vec.zero);
      b.balls.add(ball);
      final gesture = await tester.startGesture(
        tester.getTopLeft(finder) +
            game.origin +
            const Offset(100, 250) * game.scale,
      );
      expect(b.heldBall, same(ball));
      await gesture.up();
      for (var i = 0; i < 160; i++) {
        s.tick(1 / 60);
      }
      await tester.pump();
      expect(s.economy.collected, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      s.dispose();
    },
  );

  test(
    'coin rendering changes across phases without mutating money or persisted state',
    () async {
      final s = GameSession(testCatalog(automaticSpawns: false), MemoryStore())
        ..startDay();
      s.board!.balls.add(Ball(s.board!.nextId++, Board.hole, Vec.zero));
      s.tick(1 / 60);
      final game = GardenGame(s)..onGameResize(Vector2(360, 560));
      Future<List<int>> render() async {
        final before = s.snapshot();
        final recorder = ui.PictureRecorder();
        game.render(ui.Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(360, 560);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final result = List<int>.of(bytes.buffer.asUint8List());
        image.dispose();
        picture.dispose();
        expect(s.snapshot(), before);
        return result;
      }

      final delayed = await render();
      s.rewardVisuals.advance(1.1);
      final jump = await render();
      s.rewardVisuals.advance(.4);
      final resting = await render();
      s.rewardVisuals.advance(.4);
      expect(await render(), orderedEquals(resting));
      s.rewardVisuals.advance(.8);
      final flight = await render();
      expect(jump, isNot(orderedEquals(delayed)));
      expect(flight, isNot(orderedEquals(jump)));
      expect(s.economy.generated, 1);
      expect(s.economy.collected, 0);
      s.dispose();
    },
  );
}
