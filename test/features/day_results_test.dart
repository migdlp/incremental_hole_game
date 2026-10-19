import 'dart:convert';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/tool.dart';
import 'package:incremental_hole_game/features/board/presentation/garden_game.dart';
import '../test_support.dart';

void main() {
  Future<void> close(WidgetTester tester, GameSession session) async {
    await tester.pumpWidget(const SizedBox());
    await session.pendingWrites;
    session.dispose();
  }

  testWidgets(
    'finished day is a blocking popup on the same frozen game and next day resumes cleanly',
    (tester) async {
      final session = GameSession(testCatalog(), MemoryStore())
        ..economy.balance = 100;
      session.startDay();
      await tester.pumpWidget(GardenApp(session: session));
      await tester.pump(const Duration(milliseconds: 100));
      final gameFinder = find.byWidgetPredicate(
        (widget) => widget is GameWidget,
      );
      final game = (tester.widget(gameFinder) as GameWidget).game as GardenGame;
      final board = session.board!;
      board.balls.add(
        Ball(board.nextId++, const Vec(60, 300), const Vec(40, 0)),
      );
      board.captured = 3;
      board.releaseCoin(2);
      session.economy.generated = 6;
      session.economy.collected = 4;
      session.finishDay();
      await tester.pumpAndSettle();
      final popup = find.byKey(const ValueKey('day-results-popup'));
      expect(popup, findsOneWidget);
      expect(
        find.descendant(
          of: popup,
          matching: find.byWidgetPredicate(
            (widget) => widget is ButtonStyleButton,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: popup, matching: find.byType(FilledButton)),
        findsNothing,
      );
      expect((tester.widget(gameFinder) as GameWidget).game, same(game));
      expect(game.paused, isTrue);
      expect(
        find.descendant(of: popup, matching: find.text('Dinero ganado')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: popup, matching: find.text('\$4')),
        findsNWidgets(2),
      );
      expect(
        find.descendant(of: popup, matching: find.text('Bolas al hoyo')),
        findsOneWidget,
      );
      expect(session.economy.balance, 104);
      expect(session.board, isNull);
      expect(jsonDecode(session.snapshot())['run'], isNull);
      final position = board.balls.single.position;
      final spawn = board.spawnClock;
      await tester.tapAt(const Offset(5, 5));
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(seconds: 4));
      expect(popup, findsOneWidget);
      expect(board.balls.single.position, position);
      expect(board.spawnClock, spawn);
      expect(session.selectedTool, BallTool.hand);
      expect(session.economy.balance, 104);
      expect(session.progress.day, 2);
      await tester.tap(find.text('Ir al árbol de mejoras'));
      await tester.pumpAndSettle();
      expect(popup, findsNothing);
      expect(find.byKey(const ValueKey('node-hand:1')), findsOneWidget);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('hold-purchase'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3100));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(session.levels['hand'], 1);
      expect(session.economy.balance, 84);
      expect(game.paused, isTrue);
      expect(find.text('\$84'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tree-start-day')));
      await tester.pump();
      expect(popup, findsNothing);
      expect((tester.widget(gameFinder) as GameWidget).game, same(game));
      expect(session.running, isTrue);
      expect(game.paused, isFalse);
      expect(session.board!.balls, isEmpty);
      expect(session.board!.coins, isEmpty);
      expect(session.economy.balance, 84);
      expect(session.board!.handCapacity, 2);
      await close(tester, session);
    },
  );

  testWidgets(
    'starting the next day cancels an unfinished purchase on mobile',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = GameSession(testCatalog(), MemoryStore())
        ..economy.balance = 100;
      session.startDay();
      session.finishDay();
      await tester.pumpWidget(GardenApp(session: session));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ir al árbol de mejoras'));
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('node-hand:1'))),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('tree-start-day')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await gesture.up();
      await tester.pump(const Duration(seconds: 4));
      expect(session.running, isTrue);
      expect(session.levels, isEmpty);
      expect(session.economy.balance, 100);
      expect(find.byKey(const ValueKey('day-results-popup')), findsNothing);
      expect(find.byKey(const ValueKey('tree-start-day')), findsNothing);
      expect(tester.takeException(), isNull);
      await close(tester, session);
    },
  );

  testWidgets(
    'restored night opens a separate tree screen and returning cancels an unfinished purchase',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final saved = GameSession(testCatalog(), MemoryStore())
        ..economy.balance = 100;
      saved.startDay();
      saved.finishDay();
      final session = GameSession(testCatalog(), MemoryStore())
        ..restore(saved.snapshot());
      await tester.pumpWidget(GardenApp(session: session));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('day-results-popup')), findsOneWidget);
      await tester.tap(find.text('Ir al árbol de mejoras'));
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('hold-purchase'))),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await gesture.up();
      expect(session.levels, isEmpty);
      expect(session.economy.balance, 100);
      expect(tester.takeException(), isNull);
      await close(tester, session);
      await saved.pendingWrites;
      saved.dispose();
    },
  );
}
