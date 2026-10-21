import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/coin_denomination.dart';
import 'package:incremental_hole_game/features/board/presentation/coin_icon.dart';
import 'package:incremental_hole_game/features/board/presentation/coin_painter.dart';
import 'package:incremental_hole_game/features/upgrades/presentation/skill_tree_screen.dart';
import '../test_support.dart';

void main() {
  final catalog = testCatalog();

  test(
    'payouts split into physical denominations without merging nearby coins',
    () {
      final board = Board(catalog.settings({}));
      for (final amount in [2, 4, 13, 661]) {
        board.releaseCoin(amount);
      }
      expect(board.pending, 680);
      expect(
        board.coins.every((c) => [1, 10, 50, 100, 500].contains(c.value)),
        isTrue,
      );
      expect(board.coins.where((c) => c.value == 1), hasLength(10));
      final reopened = Board.fromJson(board.settings, board.toJson());
      expect(
        reopened.coins.map((c) => c.value),
        board.coins.map((c) => c.value),
      );
      expect(reopened.pending, 680);
    },
  );

  test(
    'manual area precedes magnet and collects a group without sweep or magnet',
    () {
      Board board(int level) {
        final result = Board(
          catalog.settings({'hand': 1, 'collection': level}),
        );
        for (final x in [100.0, 122.0, 140.0]) {
          result.coins.add(Coin(result.nextId++, Vec(x, 250), 1, landing: 0));
        }
        return result;
      }

      final initial = board(0), upgraded = board(1);
      expect(upgraded.sweepEnabled, isFalse);
      expect(upgraded.settings['magnet_radius'], 0);
      initial.touch(const Vec(100, 250));
      upgraded.touch(const Vec(100, 250));
      expect(initial.releasePointer(), 1);
      expect(upgraded.releasePointer(), 2);
      expect(upgraded.coins.single.position.x, 140);
      expect(upgraded.collectedCoins, {1: 2});
      final magnet = catalog.definitions.firstWhere((d) => d.id == 'magnet');
      expect(
        catalog.requirementsMet(magnet.levels.first, {
          'hand': 1,
          'collection': 2,
        }),
        isFalse,
      );
      expect(
        catalog.requirementsMet(magnet.levels.first, {
          'hand': 1,
          'collection': 3,
        }),
        isTrue,
      );
      expect(magnet.levels.single.cost, 300);
    },
  );

  test(
    'holding a ball disables collection and attraction throughout the gesture',
    () {
      final board = Board(
        catalog.settings({'hand': 1, 'sweep': 1, 'collection': 3, 'magnet': 1}),
      );
      board.balls.add(Ball(board.nextId++, const Vec(80, 250), Vec.zero));
      final coin = Coin(board.nextId++, const Vec(130, 250), 10, landing: 0);
      board.coins.add(coin);
      expect(board.touch(const Vec(80, 250)), 0);
      expect(board.heldBall, isNotNull);
      expect(board.canCollectCoins, isFalse);
      expect(board.drag(const Vec(112, 250)), 0);
      expect(board.update(1 / 60, producing: false).collected, 0);
      expect(coin.position.x, 130);
      expect(board.pending, 10);
      expect(board.releasePointer(cancel: true), 0);
      expect(board.canCollectCoins, isTrue);
      board.touch(const Vec(170, 250));
      expect(board.update(1 / 60, producing: false).collected, 0);
      expect(coin.position.x, greaterThan(130));
    },
  );

  test('first price is 13 and each integer reward follows rounded x1.65', () {
    final hand = catalog.definitions.firstWhere((d) => d.id == 'hand');
    expect(hand.levels.first.cost, 13);
    final session = GameSession(catalog, MemoryStore())..economy.balance = 13;
    expect(session.purchase(hand), isTrue);
    expect(session.economy.balance, 0);
    var previous = 1;
    final reward = catalog.definitions.firstWhere((d) => d.id == 'reward');
    expect(reward.levels.map((l) => l.value), [2, 3, 5, 8, 13]);
    for (final level in reward.levels) {
      expect(level.value, (previous * 1.65).round());
      previous = level.value.toInt();
    }
  });

  test(
    'v4 purchases and v5 active-day value survive the new magnet prerequisite',
    () {
      final owned = {
        'hand': 1,
        'sweep': 1,
        'collection': 1,
        'magnet': 1,
        'reward': 5,
      };
      final settings = catalog.settings(owned, balanceVersion: 5);
      final board = Board(settings)..captured = 1;
      board.coins.add(
        Coin(board.nextId++, const Vec(110, 300), 11, landing: 0),
      );
      final oldBoard = board.toJson()
        ..remove('collectedCoins')
        ..remove('queuedCoins')
        ..remove('combo');
      final data =
          jsonDecode(GameSession(catalog, MemoryStore()).snapshot())
              as Map<String, dynamic>;
      data['version'] = 4;
      data.remove('previousTree');
      data['levels'] = owned;
      data['run'] = {
        'remaining': 7.0,
        'collected': 0,
        'generated': 11,
        'settings': settings.toJson(),
        'balanceVersion': 5,
        'board': oldBoard,
      };
      final session = GameSession(catalog, MemoryStore())
        ..restore(jsonEncode(data));
      expect(session.levels, owned);
      expect(session.levels['collection'], 1);
      expect(session.board!.settings['ball_value'], 11);
      expect(session.board!.pending, 11);
      expect(session.board!.coins.map((c) => c.value).toSet(), {10, 1});
      expect(session.board!.collectedCoins, isNull);
      final reopened = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      reopened.finishDay();
      reopened.startDay();
      expect(reopened.board!.settings.balanceVersion, 10);
      expect(reopened.board!.settings['ball_value'], 13);
      expect(reopened.board!.settings['magnet_radius'], 65);
      expect(reopened.levels['collection'], 1);
      expect(
        GameSession(catalog, MemoryStore())..restore(reopened.snapshot()),
        isA<GameSession>(),
      );
    },
  );

  GameSession completedDay() {
    final session = GameSession(catalog, MemoryStore())
      ..levels.addAll({'hand': 1, 'reward': 3})
      ..startDay();
    final board = session.board!;
    board.balls.addAll([
      Ball(board.nextId++, Board.hole, Vec.zero),
      Ball(board.nextId++, Board.hole, Vec.zero, golden: true),
    ]);
    for (var i = 0; i < 16; i++) {
      session.tick(1 / 60);
    }
    while (board.coins.isNotEmpty) {
      session.touch(board.coins.first.position);
      session.release();
    }
    session.finishDay();
    return session;
  }

  test(
    'exact collected denominations persist in the daily result and forged counts fail atomically',
    () {
      final session = completedDay();
      expect(session.progress.last!.income, 55);
      expect(session.progress.last!.collectedCoins, {50: 1, 1: 5});
      final reopened = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      expect(reopened.progress.last!.collectedCoins, {50: 1, 1: 5});
      final data = jsonDecode(session.snapshot()) as Map<String, dynamic>;
      data['last']['collectedCoins'] = {'50': 2};
      expect(() => reopened.restore(jsonEncode(data)), throwsFormatException);
      expect(reopened.economy.balance, 55);
      data['last']['collectedCoins'] = {'2': 1};
      expect(() => reopened.restore(jsonEncode(data)), throwsFormatException);
    },
  );

  test(
    'coin silhouettes have identical width and height across all five denominations',
    () async {
      (int, int, int, int)? expected;
      for (final denomination in CoinDenomination.values) {
        final recorder = ui.PictureRecorder();
        paintCoin(Canvas(recorder), const Offset(20, 20), denomination);
        final picture = recorder.endRecording();
        final image = await picture.toImage(40, 40);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        var left = 40, top = 40, right = 0, bottom = 0;
        for (var y = 0; y < 40; y++) {
          for (var x = 0; x < 40; x++) {
            if (bytes.getUint8((y * 40 + x) * 4 + 3) == 0) continue;
            if (x < left) left = x;
            if (x > right) right = x;
            if (y < top) top = y;
            if (y > bottom) bottom = y;
          }
        }
        expected ??= (left, top, right, bottom);
        expect((left, top, right, bottom), expected);
        picture.dispose();
        image.dispose();
      }
    },
  );

  testWidgets(
    'summary removes its bar, sorts exact coin counts and money uses icons without dollar symbols',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final session = completedDay();
      await tester.pumpWidget(GardenApp(session: session));
      await tester.pumpAndSettle();
      final summary = find.byKey(const ValueKey('visual-day-results'));
      expect(
        find.descendant(
          of: summary,
          matching: find.byType(LinearProgressIndicator),
        ),
        findsNothing,
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('collected-coin-50'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('collected-coin-1'))).dy,
        ),
      );
      expect(find.text('× 5'), findsOneWidget);
      expect(find.text('× 1'), findsOneWidget);
      expect(find.byType(CoinIcon), findsWidgets);
      for (final widget in tester.widgetList<Text>(find.byType(Text))) {
        expect(
          widget.data ?? widget.textSpan?.toPlainText(),
          isNot(contains(r'$')),
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(home: SkillTreeScreen(session: session)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('node-hand:1')));
      await tester.pumpAndSettle();
      for (final widget in tester.widgetList<Text>(find.byType(Text))) {
        expect(
          widget.data ?? widget.textSpan?.toPlainText(),
          isNot(contains(r'$')),
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await session.pendingWrites;
      session.dispose();
    },
  );

  testWidgets(
    'one timer stays in place and changes color when collection begins',
    (tester) async {
      final session = GameSession(catalog, MemoryStore())
        ..startDay()
        ..pause();
      await tester.pumpWidget(GardenApp(session: session));
      await tester.pump();
      expect(find.text('15 s'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const ValueKey('phase-timer')),
            )
            .value,
        1,
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final timer = find.byKey(const ValueKey('phase-timer'));
      final timerElement = tester.element(timer);
      final timerRect = tester.getRect(timer);
      final productionColor = tester
          .widget<LinearProgressIndicator>(timer)
          .color;
      final seconds = find.byKey(const ValueKey('remaining-seconds'));
      expect(tester.getRect(seconds).bottom, lessThan(timerRect.top));
      expect(tester.getRect(seconds).right, closeTo(timerRect.right, .01));
      expect(tester.widget<Text>(seconds).style!.fontSize, lessThan(16));
      final boardRect = tester.getRect(
        find.byKey(const ValueKey('gameplay-board')),
      );
      final balanceRect = tester.getRect(
        find.byKey(const ValueKey('gameplay-balance')),
      );
      expect(boardRect.contains(balanceRect.topLeft), isTrue);
      expect(boardRect.contains(balanceRect.bottomRight), isTrue);
      expect(balanceRect.center.dx, greaterThan(boardRect.center.dx));
      expect(
        boardRect.contains(tester.getCenter(find.byTooltip('Pausar'))),
        isTrue,
      );
      expect(
        find.textContaining(RegExp(r'D[Íí]A?\s*\d', caseSensitive: false)),
        findsNothing,
      );
      expect(find.text('Día'), findsNothing);
      expect(find.text('Recogida'), findsNothing);
      expect(find.textContaining('Agarra'), findsNothing);
      session.cycle!.advance(15);
      session.board!.enterClosing();
      session.resume();
      session.pause();
      await tester.pump();
      expect(find.text('5 s'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.element(timer), same(timerElement));
      expect(tester.getRect(timer), timerRect);
      final collectionTimer = tester.widget<LinearProgressIndicator>(timer);
      expect(collectionTimer.value, 1);
      expect(collectionTimer.color, isNot(productionColor));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await session.pendingWrites;
      session.dispose();
    },
  );
}
