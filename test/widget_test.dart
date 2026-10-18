import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/tool.dart';
import 'package:incremental_hole_game/features/board/presentation/garden_game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'test_support.dart';

void main() {
  testWidgets(
    'night shows actual balance, progression, and starts a playable day',
    (tester) async {
      final session = GameSession(testCatalog(), MemoryStore());
      await tester.pumpWidget(GardenApp(session: session));
      expect(find.text('JARDÍN MECÁNICO'), findsOneWidget);
      expect(find.text('Comenzar día 1'), findsOneWidget);
      await tester.tap(find.text('Comenzar día 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(session.running, isTrue);
      expect(find.byTooltip('Pausar'), findsOneWidget);
      await tester.tap(find.byTooltip('Pausar'));
      await tester.pump();
      expect(find.text('Un pequeño descanso'), findsOneWidget);
      final remaining = session.cycle!.remaining;
      await tester.pump(const Duration(seconds: 2));
      expect(session.cycle!.remaining, remaining);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(session.paused, isFalse);
      session.finishDay();
      await tester.pump();
      expect(find.text('Comenzar día 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await session.pendingWrites;
      session.dispose();
    },
  );
  testWidgets(
    'real pointer distinguishes tapping coins from dragging over them',
    (tester) async {
      final session = GameSession(testCatalog(), MemoryStore())..startDay();
      await tester.pumpWidget(GardenApp(session: session));
      await tester.pump(const Duration(milliseconds: 100));
      final gameFinder = find.byWidgetPredicate(
        (widget) => widget is GameWidget,
      );
      final game = (tester.widget(gameFinder) as GameWidget).game as GardenGame;
      Offset screen(Vec point) =>
          tester.getTopLeft(gameFinder) +
          game.origin +
          Offset(point.x, point.y) * game.scale;
      final board = session.board!;
      board.captured = 1;
      session.economy.generated = 2;
      board.coins.add(Coin(board.nextId++, const Vec(100, 300), 2, landing: 0));
      final drag = await tester.createGesture();
      await drag.down(
        screen(const Vec(100, 300)),
        timeStamp: const Duration(seconds: 1),
      );
      await drag.moveTo(
        screen(const Vec(170, 300)),
        timeStamp: const Duration(milliseconds: 1100),
      );
      await drag.up(timeStamp: const Duration(milliseconds: 1200));
      expect(session.economy.collected, 0);
      expect(board.pending, 2);
      await tester.tapAt(screen(const Vec(100, 300)));
      expect(session.economy.collected, 2);
      expect(board.pending, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await session.pendingWrites;
      session.dispose();
    },
  );

  testWidgets(
    'real hand gesture moves a single ball and stops before release',
    (tester) async {
      final session = GameSession(testCatalog(), MemoryStore())..startDay();
      await tester.pumpWidget(GardenApp(session: session));
      await tester.pump(const Duration(milliseconds: 100));
      final finder = find.byWidgetPredicate((widget) => widget is GameWidget);
      final game = (tester.widget(finder) as GameWidget).game as GardenGame;
      Offset screen(Vec point) =>
          tester.getTopLeft(finder) +
          game.origin +
          Offset(point.x, point.y) * game.scale;
      final board = session.board!;
      final ball = Ball(board.nextId++, const Vec(100, 200), Vec.zero);
      board.balls.add(ball);
      final gesture = await tester.createGesture();
      await gesture.down(
        screen(ball.position),
        timeStamp: const Duration(seconds: 1),
      );
      expect(board.heldBall, same(ball));
      await gesture.moveTo(
        screen(const Vec(140, 200)),
        timeStamp: const Duration(milliseconds: 1100),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(ball.position.x, closeTo(140, .01));
      await gesture.up(timeStamp: const Duration(milliseconds: 1400));
      expect(board.heldBall, isNull);
      expect(ball.velocity.length, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await session.pendingWrites;
      session.dispose();
    },
  );

  testWidgets('owned tools can be switched in the playable screen', (
    tester,
  ) async {
    final session = GameSession(testCatalog(), MemoryStore());
    session.economy.balance = 500;
    for (final id in ['broom', 'paddle', 'broom_v']) {
      session.purchase(
        session.catalog.definitions.firstWhere((d) => d.id == id),
      );
    }
    session.startDay();
    await tester.pumpWidget(GardenApp(session: session));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Mano'));
    await tester.pump();
    expect(session.board!.tool, BallTool.hand);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Escoba'));
    await tester.pump();
    expect(session.board!.tool, BallTool.broom);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Escoba en V'));
    await tester.pump();
    expect(session.board!.tool, BallTool.vee);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await session.pendingWrites;
    session.dispose();
  });
}
