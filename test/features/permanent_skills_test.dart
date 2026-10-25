import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/prestige/domain/meta_progress.dart';
import 'package:incremental_hole_game/features/prestige/domain/permanent_skills.dart';
import 'package:incremental_hole_game/features/prestige/domain/star_rewards.dart';
import 'package:incremental_hole_game/features/prestige/domain/star_bubbles.dart';
import '../test_support.dart';
import 'package:incremental_hole_game/features/feeding/domain/feeding_progress.dart';
import 'package:incremental_hole_game/core/vec.dart';

class PurchaseFaultStore extends MemoryStore {
  bool failMain = false;
  @override
  Future<void> save(String contents, {String? previous}) async {
    if (failMain) throw StateError('interrupted normal save');
    await super.save(contents, previous: previous);
  }
}

void main() {
  final catalog = testCatalog();
  GameSession shop({int stars = 28, MemoryStore? store}) {
    final s = GameSession(catalog, store ?? MemoryStore(), eventSeed: 42);
    final j = jsonDecode(s.snapshot());
    j['meta'] = MetaProgress(stars: stars).end(voluntary: true).toJson();
    s.restore(jsonEncode(j));
    return s;
  }

  Future<void> buyAll(GameSession s) async {
    await s.save();
    for (final skill in PermanentSkill.catalogue) {
      expect(s.buyPermanent(skill.id), isTrue);
      expect(s.buyPermanent(skill.id), isFalse);
      await s.pendingWrites;
    }
  }

  test(
    'four approved single purchases, exact prices, no freebies and full shop restore',
    () async {
      final s = shop();
      await buyAll(s);
      expect(s.meta.stars, 0);
      expect(s.meta.upgrades, {'H01': 1, 'H02': 1, 'H04': 1, 'H13': 1});
      final restored = GameSession(catalog, MemoryStore())
        ..restore(s.snapshot());
      expect(restored.meta.phase, PrestigePhase.shop);
      expect(restored.meta.upgrades, s.meta.upgrades);
      expect(
        restored.beginNewRun(),
        isFalse,
      ); // Must checkpoint restored shop first.
      await restored.save();
      expect(restored.beginNewRun(), isTrue);
      await restored.pendingWrites;
      expect(restored.running, isTrue);
      expect(restored.progress.day, 1);
      expect(restored.economy.balance, 100);
      expect(restored.economy.generated, 0);
      expect(restored.rewardVisuals.collection.coins, isEmpty);
      expect(restored.normalShopAvailable, isFalse);
      final again = GameSession(catalog, MemoryStore())
        ..restore(restored.snapshot());
      expect(again.economy.balance, 100);
      expect(again.permanentRun.cycles, 0);
      again.dispose();
      restored.dispose();
      s.dispose();
    },
  );
  test(
    'insufficient, invalid and already owned purchases never change stars',
    () async {
      final s = shop(stars: 2);
      await s.save();
      expect(s.buyPermanent('H02'), isFalse);
      expect(s.buyPermanent('unknown'), isFalse);
      expect(s.buyPermanent('H01'), isTrue);
      await s.pendingWrites;
      expect(s.meta.stars, 0);
      final raw = s.snapshot();
      expect(s.buyPermanent('H01'), isFalse);
      expect(s.snapshot(), raw);
      s.dispose();
    },
  );
  test(
    'zero-star prestige can continue, no consolation or mandatory purchase',
    () async {
      final s = shop(stars: 0);
      await s.save();
      expect(s.beginNewRun(), isTrue);
      await s.pendingWrites;
      expect(s.running, isTrue);
      expect(s.economy.balance, 0);
      expect(s.meta.stars, 0);
      s.dispose();
    },
  );
  test(
    'first-day normal purchases blocked for every run, available after closing',
    () async {
      final s = GameSession(catalog, MemoryStore());
      s.economy.balance = 1000;
      final first = catalog.definitions.firstWhere((d) => d.id == 'hand');
      expect(s.purchase(first), isFalse);
      s.startDay();
      expect(s.purchase(first), isFalse);
      s.finishDay();
      expect(s.normalShopAvailable, isTrue);
      expect(s.purchase(first), isTrue);
      await s.pendingWrites;
      s.dispose();
    },
  );
  test(
    'echo counts cycles, not balls, and retries five real balls without recursion',
    () {
      final settings = catalog.settings({});
      final state = PermanentRun()..cycles = 19;
      final board = Board(settings)
        ..permanentRun = state
        ..productionEcho = true;
      board.spawnClock = settings['spawn_interval'];
      board.update(1 / 60, producing: true);
      expect(state.cycles, 0);
      expect(state.pendingEcho, 0);
      expect(board.spawned, 6);
      expect(board.balls.length, 6);
      state.cycles = 19;
      board.balls.clear();
      board.spawnClock = settings['spawn_interval'];
      board.update(1 / 60, producing: true);
      expect(board.spawned, 12);
      expect(state.cycles, 0);
      final restored = PermanentRun.fromJson(state.toJson());
      expect(restored.cycles, 0);
      final before = state.toJson();
      board.update(1, producing: false);
      expect(state.toJson(), before);
    },
  );
  test(
    'echo partial cycle survives days and restoration, resets only on new run',
    () async {
      final s = shop(stars: 6);
      await s.save();
      s.buyPermanent('H02');
      await s.pendingWrites;
      s.beginNewRun();
      await s.pendingWrites;
      s.permanentRun.cycles = 19;
      s.finishDay();
      await s.pendingWrites;
      final r = GameSession(catalog, MemoryStore())..restore(s.snapshot());
      expect(r.permanentRun.cycles, 19);
      await r.save();
      r.startDay();
      r.board!.spawnClock = r.board!.settings['spawn_interval'];
      r.tick(1 / 60);
      expect(r.permanentRun.cycles, 0);
      expect(r.board!.spawned, 6);
      r.dispose();
      s.dispose();
    },
  );
  test(
    'astral duplicate ledger preserves category/value, identities and exactly-once payout',
    () {
      final config = StarConfig(catalog.base);
      final ordinary = const StarLedger().award(1, config);
      final doubled = const StarLedger().award(1, config, duplicate: true);
      expect(doubled.pending.length, ordinary.pending.length * 2);
      expect(
        doubled.pending.map((r) => (r.category, r.value)),
        [
          ...ordinary.pending,
          ...ordinary.pending,
        ].map((r) => (r.category, r.value)),
      );
      expect(
        identical(doubled.award(1, config, duplicate: true), doubled),
        isTrue,
      );
      final parsed = StarLedger.fromJson(doubled.toJson());
      final tx = parsed.redeem(parsed.pending.map((r) => r.id));
      expect(tx.paid, doubled.pending.fold(0, (int n, r) => n + r.value));
      expect(tx.ledger.redeem(parsed.pending.map((r) => r.id)).paid, 0);
    },
  );
  test(
    'all astral bubbles materialize immediately above previous cap and restore',
    () {
      final config = StarConfig(catalog.base).changed('star_active_limit', 1);
      var ledger = const StarLedger();
      for (var q = 1; q <= 12; q++) {
        ledger = ledger.award(q, config, duplicate: true);
      }
      final bubbles = StarBubbles(config, ballRadius: 7)
        ..sync(ledger)
        ..populateImmediate();
      expect(bubbles.bodies.length, ledger.pending.length);
      final restored = StarBubbles.restore(
        bubbles.toJson(),
        ledger,
        ballRadius: 7,
        maximumSpeed: 380,
        hole: Board.hole,
      );
      expect(restored.bodies.length, ledger.pending.length);
      expect(bubbles.broken, isEmpty);
    },
  );
  test(
    'golden state and echo pending validate and round trip without fresh random draws',
    () {
      final state = PermanentRun()
        ..cycles = 19
        ..pendingEcho = 5;
      state.beginDay(goldenTime: 3);
      state.elapsed = 2;
      final restored = PermanentRun.fromJson(state.toJson());
      expect(restored.toJson(), state.toJson());
      expect(
        () => PermanentRun.fromJson({...state.toJson(), 'cycles': 20}),
        throwsFormatException,
      );
    },
  );
  test(
    'golden extra is independent, once per day, paused and restored without duplicate',
    () async {
      final s = shop(stars: 8);
      await s.save();
      s.buyPermanent('H04');
      await s.pendingWrites;
      s.beginNewRun();
      await s.pendingWrites;
      final at = s.permanentRun.goldenAt!;
      expect(at, greaterThan(0));
      expect(at, lessThan(s.cycle!.production));
      s.pause();
      s.tick(at);
      expect(s.permanentRun.elapsed, 0);
      final r = GameSession(catalog, MemoryStore())..restore(s.snapshot());
      expect(r.permanentRun.goldenAt, at);
      r.resume();
      for (var i = 0; i < at * 60 + 2; i++) {
        r.board!.balls.clear();
        r.tick(1 / 60);
      }
      expect(r.permanentRun.goldenSpawned, isTrue);
      final restored = GameSession(catalog, MemoryStore())
        ..restore(r.snapshot());
      expect(restored.permanentRun.goldenSpawned, isTrue);
      final oldSpawned = restored.board!.spawned;
      restored.resume();
      restored.board!.balls.clear();
      restored.tick(1 / 60);
      expect(restored.board!.spawned - oldSpawned, lessThanOrEqualTo(1));
      restored.finishDay();
      await restored.pendingWrites;
      restored.startDay();
      expect(restored.permanentRun.goldenSpawned, isFalse);
      expect(restored.permanentRun.elapsed, 0);
      restored.dispose();
      r.dispose();
      s.dispose();
    },
  );
  test(
    'guaranteed gold does not count as echo, capacity reserved and extras are physical',
    () {
      final state = PermanentRun()..cycles = 19;
      state.beginDay(goldenTime: .01);
      final b = Board(catalog.settings({}))
        ..permanentRun = state
        ..productionEcho = true;
      final limit = b.settings['ball_limit'].toInt();
      expect(b.ordinaryBallLimit, limit - 1);
      b.update(1 / 60, producing: true);
      expect(state.goldenSpawned, isTrue);
      expect(state.cycles, 19);
      expect(b.balls.single.golden, isTrue);
      expect(b.balls.single.position.y, lessThan(Board.generator.y));
      expect(b.ordinaryBallLimit, limit);
      b.spawnClock = b.settings['spawn_interval'];
      b.update(1 / 60, producing: true);
      expect(state.cycles, 0);
      expect(b.spawned, 7);
    },
  );
  test(
    'three completed quotas each draw astral independently and persist entitlement once',
    () async {
      final s = shop(stars: 12);
      await s.save();
      s.buyPermanent('H13');
      await s.pendingWrites;
      s.beginNewRun();
      await s.pendingWrites;
      s.feeding = FeedingProgress(
        startDay: 1,
        target: 1,
      ); // Small quotas isolate independent rolls.
      var rng = jsonDecode(s.snapshot())['eventRandom'] as int;
      final config = s.starConfig;
      var expected = 0;
      for (var q = 1; q <= 3; q++) {
        rng = (1664525 * rng + 1013904223) & 0xffffffff;
        expected += config['star_count'].toInt() * (rng < 0x80000000 ? 2 : 1);
      }
      for (var i = 0; i < 111; i++) {
        s.board!.balls.add(
          Ball(s.board!.nextId++, s.board!.holePosition, Vec.zero),
        );
      }
      s.tick(1 / 60);
      expect(s.meta.starLedger.quota, 3);
      expect(s.meta.starLedger.pending.length, expected);
      expect(s.board!.starBubbles!.bodies.length, expected);
      expect(s.meta.stars, 0);
      final r = GameSession(catalog, MemoryStore())..restore(s.snapshot());
      expect(
        r.meta.starLedger.pending.map((p) => p.toJson()),
        s.meta.starLedger.pending.map((p) => p.toJson()),
      );
      r.resume();
      r.tick(1 / 60);
      expect(r.meta.starLedger.quota, 3);
      expect(jsonDecode(r.snapshot())['eventRandom'], rng);
      r.dispose();
      s.dispose();
    },
  );
  test(
    'purchase checkpoint recovers a whole transaction after normal save failure',
    () async {
      final store = PurchaseFaultStore();
      final s = shop(stars: 8, store: store);
      await s.save();
      store.failMain = true;
      expect(s.buyPermanent('H04'), isTrue);
      await s.pendingWrites;
      expect(s.saveError, isNotNull);
      final r = GameSession(catalog, store);
      await r.load();
      expect(r.meta.phase, PrestigePhase.shop);
      expect(r.meta.stars, 0);
      expect(r.meta.owns('H04'), isTrue);
      expect(r.buyPermanent('H04'), isFalse);
      store.failMain = false;
      await r.save();
      expect(r.beginNewRun(), isTrue);
      await r.pendingWrites;
      expect(r.running, isTrue);
      expect(r.permanentRun.goldenAt, isNotNull);
      r.dispose();
      s.dispose();
    },
  );
  test(
    'multiple prestiges preserve all purchases, reset counters and grant inheritance once',
    () async {
      final s = shop();
      await buyAll(s);
      for (var run = 0; run < 3; run++) {
        expect(s.beginNewRun(), isTrue);
        await s.pendingWrites;
        expect(s.economy.balance, 100);
        expect(s.permanentRun.cycles, 0);
        expect(s.meta.upgrades.length, 4);
        expect(s.meta.stars, 0);
        s.permanentRun.cycles = 19;
        for (var i = 0; i < 100; i++) {
          s.board!.balls.add(
            Ball(s.board!.nextId++, s.board!.holePosition, Vec.zero),
          );
        }
        s.tick(1 / 60);
        expect(s.meta.starLedger.pending, isNotEmpty);
        s.finishDay();
        await s.pendingWrites;
        for (final d in catalog.definitions.where((d) => d.id != 'prestige')) {
          s.levels[d.id] = d.levels.length;
        }
        final node = catalog.definitions.firstWhere((d) => d.id == 'prestige');
        s.economy.balance = node.levels.first.cost;
        expect(s.purchase(node, confirmPrestige: true), isTrue);
        await s.pendingWrites;
        expect(s.meta.phase, PrestigePhase.shop);
        expect(s.economy.balance, 0);
        expect(s.meta.starLedger.pending, isEmpty);
        expect(s.meta.stars, 0);
        expect(s.permanentRun.cycles, 0);
        expect(s.permanentRun.pendingEcho, 0);
        expect(s.meta.upgrades.length, 4);
      }
      s.dispose();
    },
  );
  test(
    'many physical bubbles remain accounted and speed-limited with the broad phase',
    () {
      final config = StarConfig(catalog.base);
      var ledger = const StarLedger();
      for (var q = 1; q <= 50; q++) {
        ledger = ledger.award(q, config, duplicate: true);
      }
      final bubbles = StarBubbles(config, ballRadius: 7)
        ..sync(ledger)
        ..populateImmediate();
      final b = Board(catalog.settings({}))..starBubbles = bubbles;
      for (var frame = 0; frame < 120; frame++) {
        b.update(1 / 60, producing: true);
      }
      expect(
        bubbles.bodies.length + bubbles.broken.length,
        ledger.pending.length,
      );
      expect(
        bubbles.bodies.map((x) => x.reward.id).toSet().length,
        bubbles.bodies.length,
      );
      for (final body in bubbles.bodies) {
        expect(body.velocity.length, lessThanOrEqualTo(380.00001));
        expect(
          (body.position - body.position.inside(bubbles.radius(body))).length,
          lessThan(1e-5),
        );
      }
    },
  );
  test(
    'multi-ball normal cycle counts once and launcher emission never counts for echo',
    () {
      final state = PermanentRun()..cycles = 19;
      final b = Board(catalog.settings({'double_spawn': 1, 'launcher': 1}))
        ..permanentRun = state
        ..productionEcho = true;
      b.launcher.clock = b.launcher.interval;
      b.update(1 / 60, producing: true);
      expect(b.launcher.shots, 1);
      expect(state.cycles, 19);
      b.balls.clear();
      b.spawnClock = b.settings['spawn_interval'];
      b.update(1 / 60, producing: true);
      expect(state.cycles, 0);
      expect(state.pendingEcho, 0);
      expect(b.balls.length, 7);
    },
  );
  testWidgets(
    'all four cards, purchase cancellation and confirmation, shop restored',
    (tester) async {
      final s = shop();
      await s.save();
      await tester.pumpWidget(GardenApp(session: s));
      await tester.pumpAndSettle();
      expect(find.text('Herencia'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('permanent-buy-H01')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(s.meta.stars, 28);
      expect(s.meta.owns('H01'), isFalse);
      await tester.tap(find.byKey(const ValueKey('permanent-buy-H01')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('permanent-confirm-H01')));
      await tester.pumpAndSettle();
      expect(s.meta.stars, 26);
      expect(find.text('Adquirida'), findsOneWidget);
      expect(s.meta.phase, PrestigePhase.shop);
      await tester.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
}
