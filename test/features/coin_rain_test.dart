import 'dart:convert';
import 'package:flutter/scheduler.dart';
import 'package:incremental_hole_game/features/rewards/domain/reward_frame_metrics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/features/rewards/domain/coin_plan.dart';
import 'package:incremental_hole_game/features/rewards/domain/reward_delivery.dart';
import 'package:incremental_hole_game/features/rewards/domain/reward_visual_config.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/core/vec.dart';
import '../test_support.dart';

int value(Map<int, int> counts) =>
    counts.entries.fold(0, (sum, e) => sum + e.key * e.value);
void main() {
  const config = RewardVisualConfig();
  test(
    '34 has exactly three tens and four units and emission starts after 200 ms and all seven follow sequentially',
    () {
      final v = RewardVisuals(256, .2);
      for (final n in [10, 10, 10, 4]) {
        v.add(1, n);
      }
      v.advance(.199);
      expect(v.activeCount, 0);
      v.advance(.001);
      expect(v.activeCount, 1);
      for (var i = 0; i < 45; i++) {
        v.advance(1 / 60);
      }
      expect(v.activeCount, 7);
      expect(v.counts, {10: 3, 1: 4});
      expect(
        v.coins.where((c) => c.active).fold<int>(0, (sum, c) => sum + c.amount),
        34,
      );
      expect(v.coins.where((c) => c.active && c.quantity == 1).length, 7);
      expect(v.coins.any((c) => c.active && c.age >= v.delay), isTrue);
      v.advance(.12);
      expect(v.coins.where((c) => c.active && c.age >= v.delay).length, 7);
    },
  );
  test(
    'isolated, zero and boundary captures do not wait for a later capture or cross windows',
    () {
      final v = RewardVisuals(256, .2);
      v.add(1, 0);
      v.advance(.2);
      expect(v.batches, 0);
      v.add(2, 10);
      v.advance(.199);
      v.add(3, 4);
      v.advance(.001);
      expect(v.batches, 1);
      expect(value(v.counts), 14);
      v.add(4, 20);
      v.advance(.199);
      expect(v.batches, 1);
      v.advance(.001);
      expect(v.batches, 2);
      expect(v.counts, {10: 3, 1: 4});
      final single = RewardVisuals(256, .2)
        ..add(1, 1)
        ..advance(.2);
      expect(single.activeCount, 1);
      expect(single.coins.first.amount, 1);
    },
  );
  test(
    'exact expansion preserves value for all amounts, including extreme amounts and alternative denominations',
    () {
      for (var amount = 0; amount <= 5000; amount++) {
        expect(value(planCoins(amount, config)), amount);
      }
      for (final amount in [50000, 1000000000, 0x1fffffffffffff]) {
        final plan = planCoins(amount, config);
        expect(value(plan), amount);
        expect(plan.length, greaterThan(1));
        expect(plan.values.every((n) => n > 0), isTrue);
      }
      for (var amount = 0; amount < 1000; amount++) {
        final plan = planCoins(amount, config, denominations: [1, 5, 20]);
        expect(value(plan), amount);
        expect(plan.keys.every([1, 5, 20].contains), isTrue);
      }
      expect(
        () => planCoins(34, config, denominations: [10, 50]),
        throwsArgumentError,
      );
    },
  );
  test(
    'a meaningful reward is not collapsed to its single highest denomination',
    () {
      for (final amount in [50, 100, 500]) {
        final v = RewardVisuals(192, .2)
          ..add(1, amount)
          ..advance(.2);
        for (var i = 0; i < 30; i++) {
          v.advance(1 / 60);
        }
        expect(v.emittedObjects, greaterThan(1));
        expect(value(v.counts), amount);
        expect(v.grouped, 0);
      }
    },
  );
  test(
    '50,000 creates an abundant varied rain without grouping when capacity is free',
    () {
      final v = RewardVisuals(256, .2)
        ..add(1, 50000)
        ..advance(.2);
      final seen = <Object>{};
      for (var i = 0; i < 300; i++) {
        v.advance(1 / 60);
        seen.addAll(v.coins.where((c) => c.active).map((c) => c.denomination));
      }
      expect(v.emittedObjects, greaterThanOrEqualTo(100));
      expect(seen.length, 5);
      expect(v.grouped, 0);
      expect(v.omitted, 0);
      expect(value(v.counts), 50000);
    },
  );
  test(
    'saturation uses bounded pooled packets and keeps every denomination and amount',
    () {
      final v = RewardVisuals(16, .2);
      final ledger = RewardDelivery(delay: .2);
      for (var wave = 0; wave < 20; wave++) {
        ledger.register(50000);
        v.add(wave + 1, 50000);
        v.advance(.2);
        expect(v.activeCount, lessThanOrEqualTo(16));
        expect(v.coins.length, 16);
        expect(
          v.coins
              .where((c) => c.active)
              .every((c) => c.amount == c.denomination.amount * c.quantity),
          isTrue,
        );
        expect(v.toJson()['counts'], isA<Map>());
      }
      v.clear();
      expect(value(v.counts), 1000000);
      expect(v.grouped, greaterThan(0));
      expect(v.omitted, 0);
      expect(ledger.settle(), 1000000);
      expect(ledger.settle(), 0);
    },
  );
  test(
    'one slow frame never collapses the budget; sustained costs simplify before grouping',
    () {
      final v = RewardVisuals(256, .2);
      v.observeFrame(.1);
      expect(v.limit, 256);
      expect(v.quality, 0);
      for (var i = 0; i < 89; i++) {
        v.observeFrame(.03);
      }
      expect(v.quality, 3);
      expect(v.limit, 256);
      for (var i = 0; i < 30; i++) {
        v.observeFrame(.03);
      }
      expect(v.limit, lessThan(256));
      expect(v.limit, greaterThanOrEqualTo(32));
      for (var i = 0; i < 360; i++) {
        v.observeFrame(.015);
      }
      expect(v.limit, 256);
    },
  );
  test(
    'unfinished batches survive validation and finish without replay or loss',
    () {
      final v = RewardVisuals(256, .2)
        ..add(1, 34)
        ..advance(.1);
      final saved = jsonDecode(jsonEncode(v.toJson())) as Map<String, dynamic>;
      final restored = RewardVisuals(256, .2)
        ..restorePresentation(saved, expected: 34);
      expect(restored.activeCount, 0);
      expect(value(restored.counts), 34);
      restored.advance(.2);
      expect(value(restored.counts), 34);
      final corrupt = {...saved, 'batchAmount': 35};
      expect(
        () => RewardVisuals(256, .2).restorePresentation(corrupt, expected: 34),
        throwsFormatException,
      );
      v.clear();
      expect(value(v.counts), 34);
      expect(v.activeCount, 0);
    },
  );
  test(
    'real captures, pause, restore and results share exact batch denominations without double payment',
    () async {
      final s = GameSession(testCatalog(automaticSpawns: false), MemoryStore())
        ..startDay();
      for (var i = 0; i < 7; i++) {
        final b = s.board!;
        b.balls.add(Ball(b.nextId++, b.holePosition, Vec.zero, golden: i < 3));
      }
      s.tick(1 / 60);
      expect(s.economy.generated, 34);
      s.pause();
      final frozen = jsonEncode(s.rewardVisuals.toJson());
      s.tick(.1);
      expect(jsonEncode(s.rewardVisuals.toJson()), frozen);
      final snapshot = s.snapshot();
      final r = GameSession(s.catalog, MemoryStore())..restore(snapshot);
      expect(r.economy.collected, 34);
      r.resume();
      r.finishDay();
      expect(r.economy.balance, 34);
      expect(r.progress.last!.collectedCoins, {1: 4, 10: 3});
      r.finishDay();
      expect(r.economy.balance, 34);
      s.resume();
      s.finishDay();
      expect(s.progress.last!.collectedCoins, {1: 4, 10: 3});
      await s.pendingWrites;
      await r.pendingWrites;
      s.dispose();
      r.dispose();
    },
  );
  test(
    'diagnostics retain an early spike after its frame leaves the rolling window',
    () {
      FrameTiming frame(int end) => FrameTiming(
        vsyncStart: 0,
        buildStart: 0,
        buildFinish: 1000,
        rasterStart: 1000,
        rasterFinish: end,
        rasterFinishWallTime: end,
      );
      final metrics = RewardFrameMetrics()..add([frame(40000)]);
      metrics.add(List.generate(300, (_) => frame(2000)));
      expect(metrics.totalFrames, 301);
      expect(metrics.count, 240);
      expect(metrics.slowFrames, 1);
      expect(metrics.maximumTotal, 40000);
      expect(metrics.report, contains('máx jornada 40.00 ms'));
      metrics.clear();
      expect(metrics.totalFrames, 0);
    },
  );
  test(
    'DEBUG capture presets and visual tuning never modify the real save',
    () async {
      final store = MemoryStore();
      final s = GameSession(testCatalog(automaticSpawns: false), store)
        ..economy.balance = 777;
      final baseline = s.snapshot();
      s.enterDebug();
      await s.pendingWrites;
      final writes = store.writes.length;
      s.debugSetCoinRainCaptures(100);
      s.debugSetRewardParameter('reward_batch_window', .1);
      s.startDay();
      s.tick(1 / 60);
      expect(s.board!.captured, 100);
      expect(s.rewardConfig.window, .1);
      s.finishDay();
      s.exitDebug();
      await s.pendingWrites;
      expect(s.snapshot(), baseline);
      expect(store.writes.length, writes);
      expect(s.debugCoinRainCaptures, 0);
      expect(s.rewardConfig.window, .2);
      s.dispose();
    },
  );
  test(
    'a v19 interrupted day keeps its physics and adopts microbatches safely',
    () async {
      final s = GameSession(testCatalog(automaticSpawns: false), MemoryStore())
        ..startDay();
      final j = jsonDecode(s.snapshot()) as Map<String, dynamic>;
      j['run']['balanceVersion'] = 19;
      j['run']['settings'] = s.catalog
          .settings({}, balanceVersion: 19)
          .toJson();
      j['run'].remove('rewardPresentation');
      j['run'].remove('rewardCounts');
      final r = GameSession(s.catalog, MemoryStore())..restore(jsonEncode(j));
      expect(r.board!.settings.balanceVersion, 19);
      expect(r.rewardConfig.window, .2);
      r.resume();
      r.finishDay();
      await r.pendingWrites;
      r.startDay();
      expect(r.board!.settings.balanceVersion, 20);
      expect(r.economy.balance, 0);
      await s.pendingWrites;
      await r.pendingWrites;
      s.dispose();
      r.dispose();
    },
  );
}
