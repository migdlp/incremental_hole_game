import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/coin_denomination.dart';
import 'package:incremental_hole_game/features/board/presentation/garden_game.dart';
import 'package:incremental_hole_game/features/rewards/domain/daily_coin_collection.dart';
import 'package:incremental_hole_game/features/rewards/domain/reward_delivery.dart';
import 'package:incremental_hole_game/features/rewards/presentation/collection_painter.dart';
import '../test_support.dart';

void advance(GameSession s, double seconds) {
  for (var frame = 0; frame < (seconds * 60).round(); frame++) {
    s.tick(1 / 60);
  }
}

Future<void> capture(GameSession s, int count) async {
  s.evolution.cardRandom = 0;
  final b = s.board!;
  for (var i = 0; i < count; i++) {
    b.balls.add(Ball(b.nextId++, b.holePosition, Vec.zero));
  }
  s.tick(1 / 60);
  await resolveEvolutionFixture(s);
}

void main() {
  test(
    'stacks overlap in layers bottom to top, then fill the next column without moving slots',
    () {
      for (final size in [(320.0, 460.0), (360.0, 680.0), (600.0, 900.0)]) {
        final g = CollectionGrid(size.$1, size.$2);
        expect(g.rows, inInclusiveRange(4, 10));
        expect(g.x(0), g.x(g.rows - 1));
        expect(g.y(1), g.y(0) - CollectionGrid.layerStep);
        expect(CollectionGrid.layerStep, lessThan(CollectionGrid.faceHeight));
        expect(g.x(1), g.x(0));
        expect(g.y(g.rows), g.y(0));
        expect(g.x(g.rows), g.x(0) + CollectionGrid.columnPitch);
        final positions = {for (var i = 0; i < 500; i++) (g.x(i), g.y(i))};
        expect(positions.length, 500);
      }
    },
  );
  test(
    'arrival order is a contiguous prefix and denomination order is never sorted',
    () {
      final c = DailyCoinCollection()..begin('1:1');
      for (final d in [
        CoinDenomination.hundred,
        CoinDenomination.one,
        CoinDenomination.ten,
      ]) {
        c.reserve(d, 1);
      }
      expect(c.arrive(2, '1:1'), 0);
      expect(c.placed, 0);
      expect(c.arrive(0, '1:1'), 1);
      expect(c.placed, 1);
      expect(c.arrive(1, '1:1'), 2);
      expect(c.placed, 3);
      expect(c.coins.map((c) => c.denomination.amount), [100, 1, 10]);
      expect(c.arrive(1, '1:1'), 0);
      c.begin('1:2');
      c.reserve(CoinDenomination.fiveHundred, 1);
      expect(c.arrive(0, '1:1'), 0);
      expect(c.placed, 0);
    },
  );
  test(
    'BUG-002 reserves unique slots and variable flights finish in emission order',
    () {
      final v = RewardVisuals(192, .2, seed: 1)..add(1, 50000);
      var lastFinish = 0.0, checked = 0;
      for (var frame = 0; frame < 600; frame++) {
        final before = v.emittedObjects;
        v.advance(1 / 60);
        if (v.emittedObjects > before) {
          final coin = v.coins.firstWhere((c) => c.id == v.emittedObjects);
          expect(coin.collectionSlot, v.emittedObjects - 1);
          final finish = coin.emittedAt + coin.jump + coin.hold + coin.flight;
          expect(finish, greaterThan(lastFinish));
          lastFinish = finish;
          checked++;
        }
        expect(
          v.collection.coins.take(v.collection.placed).every((c) => c.ready),
          isTrue,
        );
      }
      expect(checked, greaterThan(100));
      expect(v.collection.placed, v.collection.coins.length);
      expect(
        v.arrivedQuantity,
        v.collection.coins.fold<int>(0, (s, c) => s + c.quantity),
      );
    },
  );
  test(
    'pause, restore, day finish, purchases and next day keep presentation separate from money',
    () async {
      final s = GameSession(testCatalog(automaticSpawns: false), MemoryStore())
        ..economy.balance = 1000
        ..startDay();
      await capture(s, 34);
      advance(s, .8);
      final state = jsonEncode(s.rewardVisuals.collection.toJson());
      final clock = s.rewardVisuals.clock;
      s.pause();
      advance(s, 1);
      expect(jsonEncode(s.rewardVisuals.collection.toJson()), state);
      expect(s.rewardVisuals.clock, clock);
      final r = GameSession(s.catalog, MemoryStore())..restore(s.snapshot());
      expect(r.economy.balance, 1000);
      expect(r.economy.collected, 34);
      expect(
        r.rewardVisuals.collection.coins.length,
        s.rewardVisuals.collection.coins.length,
      );
      expect(
        r.rewardVisuals.collection.placed,
        r.rewardVisuals.collection.coins.length,
      );
      final before = r.economy.collected;
      r.resume();
      advance(r, 3);
      expect(r.economy.collected, before);
      r.finishDay();
      await r.pendingWrites;
      expect(r.economy.balance, 1034);
      final collection = jsonEncode(r.rewardVisuals.collection.toJson());
      final hand = r.catalog.definitions.firstWhere((d) => d.id == 'hand');
      expect(r.purchase(hand), isTrue);
      expect(jsonEncode(r.rewardVisuals.collection.toJson()), collection);
      final balance = r.economy.balance;
      r.startDay();
      expect(r.rewardVisuals.collection.coins, isEmpty);
      expect(r.economy.balance, balance);
      await capture(r, 1);
      advance(r, 3);
      expect(r.rewardVisuals.collection.placed, 1);
      expect(r.rewardVisuals.collection.day, '1:2');
      await s.pendingWrites;
      await r.pendingWrites;
      s.dispose();
      r.dispose();
    },
  );
  test(
    'finishing with flights settles only existing reservations and never credits twice',
    () async {
      final s = GameSession(testCatalog(automaticSpawns: false), MemoryStore())
        ..startDay();
      await capture(s, 100);
      await resolveEvolutionFixture(s);
      advance(s, .4);
      final reserved = s.rewardVisuals.collection.coins.length;
      expect(reserved, greaterThan(0));
      s.finishDay();
      s.finishDay();
      final emissions = s.rewardVisuals.emittedObjects;
      for (var frame = 0; frame < 6; frame++) {
        s.advanceRewardTransition(.1);
      }
      expect(s.rewardVisuals.emittedObjects, emissions);
      expect(s.economy.balance, 100);
      expect(s.rewardVisuals.collection.placed, reserved);
      expect(s.rewardVisuals.activeCount, 0);
      expect(s.rewardVisuals.pendingCount, 0);
      await s.pendingWrites;
      s.dispose();
    },
  );
  test(
    'invalid optional collection metadata never discards a valid economic save',
    () async {
      final s = GameSession(testCatalog(automaticSpawns: false), MemoryStore())
        ..startDay();
      await capture(s, 34);
      advance(s, 1);
      final r = GameSession(s.catalog, MemoryStore());
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (c) => c['day'] = '2:1',
        (c) => c['coins'][0][0] = 7,
        (c) => c['coins'][0][1] = 999999999,
        (c) => c['placed'] = -1,
      ]) {
        final raw = jsonDecode(s.snapshot()) as Map<String, dynamic>;
        mutate(raw['run']['rewardPresentation']['collection']);
        r.restore(jsonEncode(raw));
        expect(r.economy.collected, 34);
        expect(r.rewardVisuals.collection.coins, isEmpty);
      }
      final legacy = jsonDecode(s.snapshot()) as Map<String, dynamic>;
      legacy['run'].remove('rewardPresentation');
      r.restore(jsonEncode(legacy));
      expect(r.economy.collected, 34);
      expect(r.rewardVisuals.collection.coins, isEmpty);
      r.resume();
      await capture(r, 1);
      advance(r, 3);
      final again = GameSession(s.catalog, MemoryStore())
        ..restore(r.snapshot());
      expect(again.rewardVisuals.collection.day, '1:1');
      expect(again.rewardVisuals.collection.placed, greaterThan(0));
      expect(again.economy.collected, 35);
      await again.pendingWrites;
      again.dispose();
      await s.pendingWrites;
      await r.pendingWrites;
      s.dispose();
      r.dispose();
    },
  );
  testWidgets(
    'HUD has only a collection strip between timer and playable board, with no balance counter',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = GameSession(testCatalog(automaticSpawns: false), MemoryStore())
        ..startDay();
      await tester.pumpWidget(GardenApp(session: s));
      await tester.pump();
      await tester.pump();
      final strip = find.byKey(const ValueKey('daily-coin-collection'));
      final board = find.byKey(const ValueKey('gameplay-board'));
      expect(strip, findsOneWidget);
      expect(find.byKey(const ValueKey('gameplay-balance')), findsNothing);
      expect(
        tester.getBottomLeft(strip).dy,
        closeTo(tester.getTopLeft(board).dy, .01),
      );
      expect(
        tester.getTopLeft(strip).dy,
        greaterThan(
          tester.getBottomLeft(find.byKey(const ValueKey('phase-timer'))).dy,
        ),
      );
      final originalRect = tester.getRect(board);
      await capture(s, 34);
      advance(s, 2);
      await tester.pump();
      expect(tester.getRect(board), originalRect);
      final game =
          (tester.widget(find.byWidgetPredicate((w) => w is GameWidget))
                      as GameWidget)
                  .game
              as GardenGame;
      expect(game.externalCoinLayer, isTrue);
      final gesture = await tester.startGesture(
        tester.getTopLeft(find.byWidgetPredicate((w) => w is GameWidget)) +
            game.origin +
            const Offset(100, 250) * game.scale,
      );
      await gesture.up();
      expect(tester.takeException(), isNull);
      s.finishDay();
      await tester.pump();
      expect(find.byKey(const ValueKey('results-wallet')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await s.pendingWrites;
      s.dispose();
    },
  );
  test(
    'hundreds of placed icons clip safely and cached painting resets between days',
    () async {
      final s = GameSession(testCatalog(automaticSpawns: false), MemoryStore())
        ..startDay();
      final c = s.rewardVisuals.collection;
      for (var i = 0; i < 500; i++) {
        c.reserve(CoinDenomination.values[i % 5], 1);
      }
      c.resolve();
      final picture = CollectionPicture();
      final grid = CollectionGrid(320, 600);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final painter = DailyCollectionPainter(s, grid, 320 * 560 / 360, picture);
      painter.paint(canvas, Size(320, grid.height + 320 * 560 / 360));
      final scene = recorder.endRecording();
      final image = await scene.toImage(320, 700);
      expect(await image.toByteData(), isNotNull);
      image.dispose();
      scene.dispose();
      c.begin('1:2');
      expect(c.coins, isEmpty);
      picture.dispose();
      await s.pendingWrites;
      s.dispose();
    },
  );
  test(
    'background freezes bounded end-of-day flights and a new day rejects old slots',
    () async {
      final s = GameSession(testCatalog(automaticSpawns: false), MemoryStore())
        ..startDay();
      await capture(s, 4);
      advance(s, .4);
      s.finishDay();
      expect(s.rewardTransitionActive, isTrue);
      s.setBackgrounded(true);
      final clock = s.rewardVisuals.clock;
      s.advanceRewardTransition(.1);
      expect(s.rewardVisuals.clock, clock);
      s.setBackgrounded(false);
      for (var i = 0; i < 6; i++) {
        s.advanceRewardTransition(.1);
      }
      expect(s.rewardTransitionActive, isFalse);
      expect(s.economy.balance, 4);
      expect(
        s.rewardVisuals.collection.placed,
        s.rewardVisuals.collection.coins.length,
      );
      s.startDay();
      s.advanceRewardTransition(.1);
      expect(s.rewardVisuals.collection.coins, isEmpty);
      s.rewardVisuals.collection.reserve(CoinDenomination.one, 1);
      expect(s.rewardVisuals.collection.arrive(0, '1:1'), 0);
      await s.pendingWrites;
      s.dispose();
    },
  );
  test(
    'voluntary prestige clears collection and pending flights without changing permanent rules',
    () async {
      final s = GameSession(testCatalog(automaticSpawns: false), MemoryStore())
        ..enterDebug()
        ..startDay();
      await capture(s, 34);
      advance(s, 3);
      s.finishDay();
      expect(s.rewardVisuals.collection.placed, greaterThan(0));
      expect(s.debugPurchase('prestige', 1, confirmPrestige: true), isTrue);
      expect(s.rewardVisuals.collection.coins, isEmpty);
      expect(s.rewardTransitionActive, isFalse);
      expect(s.beginNewRun(), isTrue);
      s.startDay();
      expect(s.rewardVisuals.collection.day, '2:1');
      expect(s.rewardVisuals.collection.coins, isEmpty);
      s.finishDay();
      s.exitDebug();
      await s.pendingWrites;
      s.dispose();
    },
  );
  testWidgets(
    'portrait layouts retain fixed collection and board bounds at several sizes',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      for (final size in [
        const Size(280, 480),
        const Size(320, 568),
        const Size(360, 800),
        const Size(432, 960),
      ]) {
        tester.view.physicalSize = size;
        final s = GameSession(
          testCatalog(automaticSpawns: false),
          MemoryStore(),
        )..startDay();
        await tester.pumpWidget(GardenApp(session: s));
        await tester.pump();
        await tester.pump();
        final strip = tester.getRect(
          find.byKey(const ValueKey('daily-coin-collection')),
        );
        final board = tester.getRect(
          find.byKey(const ValueKey('gameplay-board')),
        );
        expect(strip.bottom, closeTo(board.top, .01));
        expect(strip.width, closeTo(board.width, .01));
        expect(board.bottom, lessThanOrEqualTo(size.height));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await s.pendingWrites;
        s.dispose();
      }
    },
  );
}
