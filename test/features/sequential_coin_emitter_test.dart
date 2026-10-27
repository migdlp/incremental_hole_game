import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/rewards/domain/reward_delivery.dart';
import 'package:incremental_hole_game/features/rewards/domain/reward_visual_config.dart';
import '../test_support.dart';

int represented(RewardVisuals v) =>
    v.coins.where((c) => c.active).fold(0, (s, c) => s + c.amount);
void main() {
  test(
    'one global emitter starts at most one object per advance, including long frames',
    () {
      final v = RewardVisuals(192, .2, seed: 1)..add(1, 50000);
      for (var frame = 0; frame < 120; frame++) {
        final before = v.emittedObjects;
        v.advance(frame % 10 == 0 ? .1 : 1 / 60);
        expect(v.emittedObjects - before, inInclusiveRange(0, 1));
        expect(
          v.coins.where((c) => c.active && c.age == v.delay).length,
          lessThanOrEqualTo(1),
        );
      }
      expect(v.emittedObjects, greaterThan(20));
    },
  );
  test(
    'isolated unit starts at 200 ms and seven exact coins for 34 follow individually',
    () {
      final single = RewardVisuals(192, .2, seed: 1)..add(1, 1);
      single.advance(.199);
      expect(single.emittedObjects, 0);
      single.advance(.001);
      expect(single.emittedObjects, 1);
      final v = RewardVisuals(192, .2, seed: 2)..add(1, 34);
      v.advance(.2);
      expect(v.activeCount, 1);
      for (var i = 0; i < 60; i++) {
        v.advance(1 / 60);
      }
      expect(v.emittedObjects, 7);
      expect(v.pendingCount, 0);
      expect(v.grouped, 0);
      expect(represented(v), 34);
      expect(v.counts, {10: 3, 1: 4});
      final starts = v.coins
          .where((c) => c.active)
          .map((c) => c.emittedAt)
          .toSet();
      expect(starts.length, 7);
    },
  );
  test(
    'small bursts spread over the circle and independent waves have different seeds',
    () {
      final firstAngles = <double>{};
      for (var seed = 1; seed <= 20; seed++) {
        final v = RewardVisuals(192, .2, seed: seed)..add(1, 4);
        final angles = <double>[];
        for (var frame = 0; frame < 60; frame++) {
          final before = v.emittedObjects;
          v.advance(1 / 60);
          if (v.emittedObjects > before) {
            angles.add(
              v.coins.firstWhere((c) => c.id == v.emittedObjects).angle,
            );
          }
        }
        expect(angles.length, 4);
        firstAngles.add(angles.first);
        for (var i = 0; i < angles.length; i++) {
          for (var j = i + 1; j < angles.length; j++) {
            final delta = angles[i] - angles[j];
            expect(
              math.atan2(math.sin(delta), math.cos(delta)).abs(),
              greaterThan(.5),
            );
          }
        }
        v.add(2, 1);
        for (var i = 0; i < 20; i++) {
          v.advance(1 / 60);
        }
        expect(v.coins.firstWhere((c) => c.id == 5).angle, isNot(angles.first));
      }
      expect(firstAngles.length, 20);
    },
  );
  test(
    'massive waves rotate clockwise through 360 degrees with smooth dynamic cadence',
    () {
      final v = RewardVisuals(256, .2, seed: 7)..add(1, 50000);
      final angles = <double>[];
      final intervals = <double>[];
      for (var i = 0; i < 90; i++) {
        final before = v.emittedObjects;
        final oldInterval = v.emissionInterval;
        v.advance(1 / 60);
        expect((v.emissionInterval - oldInterval).abs(), lessThan(.012));
        if (v.emittedObjects > before) {
          final c = v.coins.firstWhere((c) => c.id == v.emittedObjects);
          angles.add(c.angle);
          intervals.add(v.emissionInterval);
        }
      }
      expect(angles.length, greaterThan(25));
      for (var i = 1; i < angles.length; i++) {
        expect(angles[i], greaterThan(angles[i - 1]));
      }
      expect(angles.last - angles.first, greaterThan(2 * math.pi));
      expect(intervals[10], lessThan(intervals.first));
      expect(v.grouped, 0);
      final last = angles.last;
      v.add(2, 34);
      for (var i = 0; i < 15; i++) {
        v.advance(1 / 60);
      }
      expect(
        v.coins.firstWhere((c) => c.id == v.emittedObjects).angle,
        greaterThan(last),
      );
    },
  );
  test(
    'origins scale inside the live hole and curves stay inside near every edge',
    () {
      for (final position in [
        Vec(16, 16),
        Vec(344, 16),
        Vec(16, 544),
        Vec(344, 544),
        Vec(180, 123),
      ]) {
        for (final radius in [22.0, 64.0, 100.0]) {
          final v = RewardVisuals(192, .2, seed: 42)
            ..geometry(position.x, position.y, radius)
            ..add(1, 500);
          for (var frame = 0; frame < 120; frame++) {
            v.advance(1 / 60);
          }
          for (final c in v.coins.where((c) => c.active)) {
            expect(
              math.sqrt(c.offsetX * c.offsetX + c.offsetY * c.offsetY),
              lessThan(radius),
            );
            for (var t = 0; t <= 100; t++) {
              c.age = v.delay + (c.jump + c.hold + c.flight) * t / 100;
              expect(
                c.x(320, v.delay, origin: position.x),
                inInclusiveRange(7, 353),
              );
              expect(
                c.y(28, v.delay, origin: position.y),
                inInclusiveRange(7, 553),
              );
            }
          }
        }
      }
    },
  );
  test(
    'saturation bounds the queue representation and keeps exact planned counts',
    () {
      final v = RewardVisuals(192, .2, seed: 1);
      for (var i = 0; i < 900; i++) {
        if (i % 12 == 0) v.add(i, 50000);
        final before = v.emittedObjects;
        v.advance(1 / 60);
        expect(v.emittedObjects - before, lessThanOrEqualTo(1));
        expect(v.activeCount, lessThanOrEqualTo(192));
        expect(v.coins.length, 192);
      }
      for (var i = 0; i < 1200; i++) {
        v.advance(1 / 60);
      }
      expect(v.pendingCount, 0);
      expect(v.grouped, greaterThan(0));
      expect(v.omitted, 0);
      expect(
        v.counts.entries.fold<int>(0, (s, e) => s + e.key * e.value),
        3750000,
      );
      expect(v.arrivedQuantity, v.counts.values.fold<int>(0, (s, n) => s + n));
    },
  );
  test(
    'catch-up physics cannot start two coins in one real session frame; pause and restore stay exact',
    () async {
      final s = GameSession(testCatalog(automaticSpawns: false), MemoryStore())
        ..startDay();
      s.evolution.cardRandom = 0;
      final b = s.board!;
      for (var i = 0; i < 50; i++) {
        b.balls.add(Ball(b.nextId++, b.holePosition, Vec.zero));
      }
      for (var i = 0; i < 20; i++) {
        final before = s.rewardVisuals.emittedObjects;
        s.tick(.1);
        await resolveEvolutionFixture(s);
        expect(s.rewardVisuals.emittedObjects - before, lessThanOrEqualTo(1));
      }
      s.pause();
      final clock = s.rewardVisuals.clock,
          emitted = s.rewardVisuals.emittedObjects;
      s.tick(.1);
      expect(s.rewardVisuals.clock, clock);
      expect(s.rewardVisuals.emittedObjects, emitted);
      final r = GameSession(s.catalog, MemoryStore())..restore(s.snapshot());
      expect(r.economy.collected, 50);
      expect(r.rewardVisuals.activeCount, 0);
      r.resume();
      r.finishDay();
      r.finishDay();
      expect(r.economy.balance, 50);
      s.resume();
      s.finishDay();
      expect(s.economy.balance, 50);
      await s.pendingWrites;
      await r.pendingWrites;
      s.dispose();
      r.dispose();
    },
  );
  test('invalid cadence configuration is rejected', () {
    expect(
      () => RewardVisualConfig.fromMap({
        'reward_emit_min': .05,
        'reward_emit_max': .01,
      }),
      throwsFormatException,
    );
  });
  test(
    'DEBUG can raise the visual pool without touching the real save or denominations',
    () async {
      final s = GameSession(testCatalog(automaticSpawns: false), MemoryStore());
      final original = s.snapshot();
      s.enterDebug();
      s.debugSetRewardParameter('reward_visual_limit', 512);
      expect(s.rewardVisuals.capacity, 512);
      s.startDay();
      expect(s.rewardVisuals.coins.length, 512);
      s.finishDay();
      s.exitDebug();
      expect(s.snapshot(), original);
      await s.pendingWrites;
      s.dispose();
    },
  );
  test(
    'continuous small batches are never grouped merely because the stream stays active',
    () {
      final v = RewardVisuals(192, .2, seed: 17);
      for (var frame = 0; frame < 1200; frame++) {
        if (frame < 900 && frame % 12 == 0) v.add(frame, 4);
        v.advance(1 / 60);
      }
      expect(v.grouped, 0);
      expect(v.emittedObjects, 300);
      expect(v.pendingCount, 0);
      expect(v.counts, {1: 300});
    },
  );
  test(
    'dense clockwise angular steps follow the configured speed rather than a fixed arc',
    () {
      final v = RewardVisuals(256, .2, seed: 12)..add(1, 250000);
      double? previousAngle, previousTime;
      var checked = 0;
      for (var frame = 0; frame < 180; frame++) {
        final before = v.emittedObjects;
        v.advance(1 / 60);
        if (v.emittedObjects == before) continue;
        final c = v.coins.firstWhere((c) => c.id == v.emittedObjects);
        if (previousAngle != null && v.angularSpeed > 14 && checked > 0) {
          final speed =
              (c.angle - previousAngle) / (c.emittedAt - previousTime!);
          expect(
            speed,
            inInclusiveRange(v.angularSpeed * .8, v.angularSpeed * 1.2),
          );
        }
        if (v.angularSpeed > 14) checked++;
        previousAngle = c.angle;
        previousTime = c.emittedAt;
      }
      expect(checked, greaterThan(50));
    },
  );
  test(
    'v20 saved settings remain unchanged while new presentation uses its own defaults',
    () async {
      final s = GameSession(testCatalog(), MemoryStore())..startDay();
      final saved = jsonDecode(s.snapshot()) as Map<String, dynamic>;
      expect(saved['run']['balanceVersion'], 20);
      expect(saved['run']['settings']['reward_max_wait'], .4);
      expect(saved['run']['settings'].containsKey('reward_emit_min'), isFalse);
      final r = GameSession(s.catalog, MemoryStore())
        ..restore(jsonEncode(saved));
      expect(r.board!.settings.balanceVersion, 20);
      expect(r.board!.settings['reward_max_wait'], .4);
      expect(r.rewardConfig.wait, 5);
      r.restore(r.snapshot());
      r.resume();
      r.finishDay();
      r.startDay();
      expect(r.board!.settings.balanceVersion, 20);
      expect(r.economy.balance, 0);
      await s.pendingWrites;
      await r.pendingWrites;
      s.dispose();
      r.dispose();
    },
  );
  test(
    'large repeated bursts drain their backlog after captures stop without a growing visual tail',
    () {
      final v = RewardVisuals(192, .2, seed: 17);
      for (var frame = 0; frame < 1380; frame++) {
        if (frame < 900 && frame % 12 == 0) v.add(frame, 250000);
        v.advance(1 / 60);
      }
      expect(v.pendingCount, 0);
      expect(v.emittedObjects, greaterThan(500));
      expect(v.omitted, 0);
      expect(
        v.counts.entries.fold<int>(0, (s, e) => s + e.key * e.value),
        18750000,
      );
    },
  );
}
