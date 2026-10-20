import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
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
      expect(find.text('Comenzar día 2'), findsNothing);
      expect(find.text('Ir al árbol de mejoras'), findsOneWidget);
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

  testWidgets(
    'real gesture attracts a second ball only with the hand upgrade',
    (tester) async {
      final session = GameSession(testCatalog(), MemoryStore())
        ..levels['hand'] = 1
        ..startDay();
      await tester.pumpWidget(GardenApp(session: session));
      await tester.pump(const Duration(milliseconds: 100));
      final finder = find.byWidgetPredicate((widget) => widget is GameWidget);
      final game = (tester.widget(finder) as GameWidget).game as GardenGame;
      Offset screen(Vec point) =>
          tester.getTopLeft(finder) +
          game.origin +
          Offset(point.x, point.y) * game.scale;
      final board = session.board!;
      final first = Ball(board.nextId++, const Vec(100, 250), Vec.zero);
      final second = Ball(board.nextId++, const Vec(170, 250), Vec.zero);
      board.balls.addAll([first, second]);
      final gesture = await tester.startGesture(screen(first.position));
      await tester.pump(const Duration(milliseconds: 50));
      expect(board.heldBalls, [first]);
      await gesture.moveTo(screen(const Vec(150, 250)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(board.heldBalls, containsAll([first, second]));
      await gesture.up();
      expect(board.heldBalls, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await session.pendingWrites;
      session.dispose();
    },
  );

  testWidgets('hand picks up the owned physical V broom without a selector', (
    tester,
  ) async {
    final session = GameSession(testCatalog(), MemoryStore());
    session.economy.balance = 500;
    for (final id in ['hand', 'hand', 'broom', 'paddle', 'broom_v']) {
      session.purchase(
        session.catalog.definitions.firstWhere((d) => d.id == id),
      );
    }
    session.startDay();
    await tester.pumpWidget(GardenApp(session: session));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ChoiceChip), findsNothing);
    final finder = find.byWidgetPredicate((widget) => widget is GameWidget);
    final game = (tester.widget(finder) as GameWidget).game as GardenGame;
    Offset screen(Vec point) =>
        tester.getTopLeft(finder) +
        game.origin +
        Offset(point.x, point.y) * game.scale;
    final board = session.board!;
    expect(board.segments, hasLength(2));
    final gesture = await tester.startGesture(screen(board.broomPosition));
    expect(board.holdingBroom, isTrue);
    await gesture.moveBy(const Offset(-30, 40));
    await tester.pump(const Duration(milliseconds: 100));
    final parked = board.broomPosition;
    await gesture.up();
    expect(board.holdingBroom, isFalse);
    expect(board.segments, hasLength(2));
    expect(board.broomPosition, parked);
    final ball = Ball(board.nextId++, const Vec(100, 250), Vec.zero);
    board.balls.add(ball);
    final hand = await tester.startGesture(screen(ball.position));
    expect(board.heldBall, same(ball));
    await hand.up();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await session.pendingWrites;
    session.dispose();
  });
  testWidgets('closing keeps the HUD undimmed while retaining pause controls', (
    tester,
  ) async {
    final session = GameSession(testCatalog(), MemoryStore())..startDay();
    await tester.pumpWidget(GardenApp(session: session));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('closing-hud-dim')), findsNothing);
    session.cycle!.remaining = 5 + 1 / 60;
    for (var i = 0; i < 10; i++) {
      session.tick(1 / 60);
    }
    await tester.pump();
    expect(session.board!.coinOnly, isTrue);
    expect(find.byKey(const ValueKey('closing-hud-dim')), findsNothing);
    expect(find.text('5 s'), findsOneWidget);
    expect(tester.widget<Text>(find.text('5 s')).style!.color!.a, 1);
    await tester.tap(find.byTooltip('Pausar'));
    await tester.pump();
    expect(session.paused, isTrue);
    expect(find.text('Continuar'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await session.pendingWrites;
    session.dispose();
  });
}
