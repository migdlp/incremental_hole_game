import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/rewards/domain/reward_delivery.dart';
import '../test_support.dart';

class SlowStore extends MemoryStore {
  final gate = Completer<void>();
  int calls = 0, active = 0, peak = 0;
  @override
  Future<void> save(String contents, {String? previous}) async {
    calls++;
    active++;
    if (active > peak) peak = active;
    await gate.future;
    await super.save(contents, previous: previous);
    active--;
  }
}

void main() {
  final catalog = testCatalog(automaticSpawns: false);
  GameSession start() =>
      GameSession(catalog, MemoryStore(), eventSeed: 42)..startDay();
  void capture(GameSession s, {int count = 1}) {
    for (var i = 0; i < count; i++) {
      s.board!.balls.add(Ball(s.board!.nextId++, Board.hole, Vec.zero));
    }
    s.tick(1 / 60);
  }

  void tick(GameSession s, double seconds) {
    for (var i = 0; i < (seconds * 60).round(); i++) {
      s.tick(1 / 60);
    }
  }

  test(
    'capture guarantees full reward, delays display and pays without input',
    () {
      final s = start();
      capture(s);
      expect(s.economy.generated, 1);
      expect(s.economy.collected, 0);
      expect(s.rewards.outstanding, 1);
      expect(s.feeding.points, 1);
      expect(s.board!.coins, isEmpty);
      tick(s, .8);
      expect(s.economy.collected, 0);
      tick(s, 2);
      expect(s.economy.collected, 1);
      expect(s.rewards.outstanding, 0);
      s.finishDay();
      s.finishDay();
      expect(s.economy.balance, 1);
    },
  );
  test(
    'touch and sweep cannot collect rewards or interfere with their delivery',
    () {
      final s = start();
      capture(s);
      s.touch(Board.hole);
      s.drag(const Vec(310, 28));
      s.release();
      expect(s.economy.collected, 0);
      tick(s, 3);
      expect(s.economy.collected, 1);
    },
  );
  test(
    'end of production settles late captures before results without collection phase',
    () {
      final s = start();
      tick(s, 14.8);
      capture(s, count: 200);
      expect(s.rewards.outstanding, 200);
      tick(s, .3);
      expect(s.running, isFalse);
      expect(s.progress.last!.income, 200);
      expect(s.progress.last!.lost, 0);
      expect(s.economy.balance, 200);
    },
  );
  test(
    'restore pays pending once, replayed serialized receipt never doubles banked money',
    () {
      final s = start();
      capture(s, count: 7);
      final snapshot = s.snapshot();
      for (var i = 0; i < 4; i++) {
        s.restore(snapshot);
        expect(s.economy.collected, 7);
        expect(s.rewards.outstanding, 0);
        s.restore(s.snapshot());
        expect(s.economy.collected, 7);
      }
      s.finishDay();
      expect(s.economy.balance, 7);
      s.restore(s.snapshot());
      expect(s.economy.balance, 7);
    },
  );
  test('pause and background freeze ledger and visual ages exactly', () {
    final s = start();
    capture(s);
    tick(s, 1.1);
    s.pause();
    final before = s.snapshot(), age = s.rewardVisuals.coins.first.age;
    tick(s, 3);
    expect(s.snapshot(), before);
    expect(s.rewardVisuals.coins.first.age, age);
    s.resume();
    tick(s, 1);
    expect(s.economy.collected, 1);
    s.setBackgrounded(true);
    final saved = s.snapshot();
    tick(s, 5);
    expect(s.snapshot(), saved);
  });
  test(
    'bounded ledger batches hundreds of thousands of exact rewards with unique ranges',
    () {
      final ledger = RewardDelivery(capacity: 4);
      var sum = 0;
      for (var i = 1; i <= 100000; i++) {
        ledger.register(i);
        sum += i;
      }
      expect(ledger.pending.length, 4);
      expect(ledger.pending.last.last, 100000);
      expect(ledger.outstanding, sum);
      final restored = RewardDelivery.fromJson(
        ledger.toJson(),
        outstanding: sum,
        delay: 1,
        capacity: 4,
      );
      expect(restored.advance(3), sum);
      expect(restored.advance(3), 0);
    },
  );
  test(
    'overlapping IDs, nonfinite clocks and wrong amounts reject restore atomically',
    () {
      final s = start();
      capture(s, count: 2);
      final raw = s.snapshot();
      for (final corrupt in <void Function(Map<String, dynamic>)>[
        (j) => j['run']['rewards']['pending'][1]['first'] = 1,
        (j) => j['run']['rewards']['pending'][0]['amount'] = 30,
        (j) => j['run']['rewards']['nextId'] = 1,
        (j) => j['run']['rewards']['clock'] = -1,
        (j) => j['run'].remove('rewards'),
      ]) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        corrupt(json);
        expect(() => s.restore(jsonEncode(json)), throwsFormatException);
        expect(s.snapshot(), raw);
      }
    },
  );
  test(
    'legacy v8 physical money and queued reserves settle without refunding removed purchases',
    () {
      final oldLevels = {
        'hand': 1,
        'collection': 3,
        'magnet': 1,
        'attraction': 1,
        'sweep': 1,
      };
      final b = Board(catalog.settings(oldLevels, balanceVersion: 14));
      b.balls.add(Ball(b.nextId++, b.holePosition, Vec.zero));
      b.update(1 / 60, producing: true);
      b.releaseCoin(1);
      final j =
          jsonDecode(GameSession(catalog, MemoryStore()).snapshot())
              as Map<String, dynamic>;
      j['version'] = 8;
      j['balance'] = 100;
      j['levels'] = oldLevels;
      j['feeding']['completedDays'] = 0;
      j['feeding']['normal'] = 1;
      j['feeding']['runNormal'] = 1;
      j['run'] = {
        'remaining': 20 - 1 / 60,
        'settings': b.settings.toJson(),
        'balanceVersion': 14,
        'board': b.toJson(),
        'collected': 0,
        'generated': 1,
      };
      final s = GameSession(catalog, MemoryStore())..restore(jsonEncode(j));
      expect(s.levels, {'hand': 1});
      expect(s.economy.balance, 100);
      expect(s.economy.collected, 1);
      expect(s.board!.coins, isEmpty);
      expect(s.cycle!.closing, 0);
      s.restore(s.snapshot());
      expect(s.economy.collected, 1); // frozen settings still reconstruct
      s.finishDay();
      expect(s.economy.balance, 101);
      s.startDay();
      expect(s.board!.settings.balanceVersion, 19);
    },
  );
  test(
    'visual pool reuses objects, groups bursts and can be disabled without losing income',
    () {
      final pool = RewardVisuals(4, 1);
      final objects = List.of(pool.coins);
      for (var i = 1; i <= 200; i++) {
        pool.add(i, i);
      }
      expect(pool.activeCount, 4);
      expect(pool.grouped, 196);
      pool.advance(3);
      pool.add(201, 7);
      expect(pool.coins.first, same(objects.first));
      final s = GameSession(catalog, MemoryStore())..enterDebug();
      s.debugSetRewardLimit(0);
      s.startDay();
      capture(s, count: 200);
      expect(s.rewardVisuals.activeCount, 0);
      s.finishDay();
      expect(s.economy.balance, 200);
      s.exitDebug();
      expect(s.economy.balance, 0);
    },
  );
  test(
    'curves stay hidden until delay, vary between coins and converge on wallet',
    () {
      final a = RewardCoin()..reset(1, 1), b = RewardCoin()..reset(2, 1);
      expect(a.x(310, 1), 180);
      expect(a.y(28, 1), 50);
      a.age = b.age = 1.1;
      expect(a.x(310, 1), isNot(b.x(310, 1)));
      a.age = 1 + a.jump + a.flight;
      expect(a.x(310, 1), closeTo(310, 1e-8));
      expect(a.y(28, 1), closeTo(28, 1e-8));
    },
  );
  test(
    'adaptive quality lowers visual budget and recovers without touching economics',
    () {
      final v = RewardVisuals(24, 1);
      v.observeFrame(.04);
      expect(v.limit, 12);
      for (var i = 0; i < 150; i++) {
        v.observeFrame(1 / 60);
      }
      expect(v.limit, greaterThan(12));
    },
  );
  test(
    'capture checkpoints coalesce while disk is busy without losing any reward',
    () async {
      final store = SlowStore();
      final s = GameSession(catalog, store)..startDay();
      for (var i = 0; i < 100; i++) {
        capture(s);
      }
      expect(store.calls, 1);
      expect(store.peak, 1);
      store.gate.complete();
      await s.pendingWrites;
      expect(store.calls, 2);
      expect(store.peak, 1);
      final saved = jsonDecode(store.writes.last);
      expect(saved['run']['generated'], 100);
      final restored = GameSession(catalog, MemoryStore())
        ..restore(store.writes.last);
      expect(restored.economy.collected, 100);
      expect(restored.feeding.points, 100);
      s.dispose();
      restored.dispose();
    },
  );

  test('retired upgrades cannot be bought or found in active catalog', () {
    expect(
      catalog.definitions.where(
        (d) => {'sweep', 'collection', 'magnet', 'attraction'}.contains(d.id),
      ),
      isEmpty,
    );
    final s = GameSession(catalog, MemoryStore())..enterDebug();
    expect(s.debugPurchase('magnet', 1), isFalse);
    expect(
      catalog.definitions
          .firstWhere((d) => d.id == 'robot')
          .levels
          .first
          .requirements,
      ['paddle:2'],
    );
  });
  test(
    'removed prerequisites never invalidate a second restore of a v4 inherited Robot',
    () {
      final j =
          jsonDecode(GameSession(catalog, MemoryStore()).snapshot())
              as Map<String, dynamic>;
      j['version'] = 4;
      j['levels'] = {
        'hand': 2,
        'broom': 1,
        'paddle': 2,
        'sweep': 1,
        'robot': 1,
      };
      final s = GameSession(catalog, MemoryStore())..restore(jsonEncode(j));
      expect(s.levels.containsKey('sweep'), isFalse);
      expect(s.levels['robot'], 1);
      s.restore(s.snapshot());
      expect(s.levels['robot'], 1);
      s.enterDebug();
      expect(s.debugPurchase('robot_speed', 1), isTrue);
      s.exitDebug();
      expect(s.levels['robot'], 1);
      s.dispose();
    },
  );
}
