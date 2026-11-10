import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/evolution/domain/evolution.dart';
import 'package:incremental_hole_game/features/prestige/domain/meta_progress.dart';
import '../test_support.dart';

class EvolutionFaultStore extends MemoryStore {
  bool failMain = false;
  @override
  Future<void> save(String contents, {String? previous}) async {
    if (failMain) throw StateError('interrupted normal write');
    await super.save(contents, previous: previous);
  }
}

void main() {
  GameSession game([MemoryStore? store]) => GameSession(
    testCatalog(automaticSpawns: false),
    store ?? MemoryStore(),
    eventSeed: 42,
  );
  void capture(GameSession s, int n) {
    for (var i = 0; i < n; i++) {
      s.board!.balls.add(
        Ball(s.board!.nextId++, s.board!.holePosition, Vec.zero),
      );
    }
    s.tick(1 / 60);
  }

  test(
    'millionaire total, bonus ledger and daily accounting restore once, feeding remains one per ball',
    () async {
      final s = game();
      final j = jsonDecode(s.snapshot());
      j['meta']['evolution'] = {'E03-10': 1};
      s.restore(jsonEncode(j));
      s.startDay();
      capture(s, 10);
      await s.pendingWrites;
      expect(s.economy.generated, 11);
      expect(s.board!.evolutionBonus, 1);
      expect(s.feeding.points, BigInt.from(10));
      final r = game()..restore(s.snapshot());
      expect(r.economy.generated, 11);
      expect(r.board!.evolutionBonus, 1);
      expect(r.evolution.moneyMultiplier, 2);
      r.finishDay();
      await r.pendingWrites;
      expect(r.economy.balance, 11);
      r.finishDay();
      expect(r.economy.balance, 11);
      expect(r.evolution.moneyMultiplier, 1);
      expect(r.evolution.millionaire.cooldown, 10);
      r.dispose();
      s.dispose();
    },
  );
  test(
    'luck then millionaire yields exactly 42 from a base of seven and no extra feeding',
    () async {
      final catalog = testCatalog(automaticSpawns: false);
      catalog.base['ball_value'] = 7;
      final s = GameSession(catalog, MemoryStore());
      final j = jsonDecode(s.snapshot());
      j['meta']['evolution'] = {'E03-10': 5, 'E03-12': 5};
      s.restore(jsonEncode(j));
      s.startDay();
      for (var i = 0; i < 9; i++) {
        s.evolution.randomState = 0;
        capture(s, 1);
      }
      expect(s.economy.generated, 63);
      s.evolution.randomState = 1972;
      capture(s, 1);
      expect(s.economy.generated, 105);
      expect(s.feeding.points, BigInt.from(10));
      expect(s.meta.stars, 0);
      final r = GameSession(catalog, MemoryStore())..restore(s.snapshot());
      expect(r.economy.generated, 105);
      r.dispose();
      s.dispose();
    },
  );
  test(
    'permanent evolution survives death, resets transient state, and repeated quotas grant another choice',
    () async {
      final s = game()..startDay();
      capture(s, 25);
      await s.pendingWrites;
      final id = s.evolution.options.first;
      expect(s.chooseEvolution(id, serial: 0), isTrue);
      await s.pendingWrites;
      s.finishDay();
      await s.pendingWrites;
      for (var i = 0; i < 3; i++) {
        s.startDay();
        s.finishDay();
        await s.pendingWrites;
      }
      expect(s.meta.phase, PrestigePhase.defeat);
      expect(s.meta.evolutionLevels[id], 1);
      expect(s.evolution.lastQuota, 0);
      expect(s.evolution.pending, 0);
      expect(s.evolution.dayElapsed, 0);
      expect(s.continueToPrestigeShop(), isTrue);
      await s.pendingWrites;
      s.beginNewRun();
      await s.pendingWrites;
      expect(s.meta.evolutionLevels[id], 1);
      capture(s, 25);
      await s.pendingWrites;
      expect(s.evolution.pending, 1);
      expect(s.evolution.lastQuota, 1);
      expect(s.meta.starLedger.quota, 1);
      s.dispose();
    },
  );
  test(
    'all skills maxed never open an empty selector but preserve every other quota reward',
    () async {
      final s = game();
      final j = jsonDecode(s.snapshot());
      j['meta']['evolution'] = {
        for (final k in EvolutionSkill.catalogue) k.id: 5,
      };
      s.restore(jsonEncode(j));
      s.startDay();
      capture(s, 25);
      await s.pendingWrites;
      expect(s.evolution.pending, 0);
      expect(s.evolutionBlocked, isFalse);
      expect(s.feeding.growths, 1);
      expect(s.meta.starLedger.quota, 1);
      expect(s.meta.starLedger.pending, isNotEmpty);
      expect(
        s.meta.evolutionLevels.values.fold(0, (int n, int v) => n + v),
        60,
      );
      s.dispose();
    },
  );
  test(
    'selection is either fully checkpointed or remains pending after ordinary write failure',
    () async {
      final store = EvolutionFaultStore();
      final s = game(store)..startDay();
      capture(s, 25);
      await s.pendingWrites;
      final id = s.evolution.options.first, serial = s.evolution.serial;
      store.failMain = true;
      expect(s.chooseEvolution(id, serial: serial), isTrue);
      await s.pendingWrites;
      expect(s.saveError, isNotNull);
      expect(s.evolutionBlocked, isTrue);
      final before = s.evolution.dayElapsed;
      s.tick(10);
      expect(s.evolution.dayElapsed, before);
      final r = game(store);
      await r.load();
      expect(r.meta.evolutionLevels[id], 1);
      expect(r.evolution.pending, 0);
      expect(r.chooseEvolution(id, serial: serial), isFalse);
      store.failMain = false;
      await r.save();
      r.resume();
      r.tick(1 / 60);
      expect(r.meta.evolutionLevels[id], 1);
      r.dispose();
      s.dispose();
    },
  );
  test(
    'checkpoint after the last closing-time selection finishes results on recovery',
    () async {
      final store = EvolutionFaultStore();
      final s = game(store)..startDay();
      advanceToProductionBoundary(s, 1 / 60);
      capture(s, 25);
      await s.pendingWrites;
      final beforeChoice = s.snapshot();
      store.failMain = true;
      s.chooseEvolution(s.evolution.options.first, serial: s.evolution.serial);
      await s.pendingWrites;
      expect(s.evolution.closingPending, isTrue);
      store.candidates = [beforeChoice, beforeChoice];
      store.failMain = false;
      final r = game(store);
      await r.load();
      await r.pendingWrites;
      expect(r.running, isFalse);
      expect(r.progress.last!.captured, 25);
      expect(r.meta.phase, PrestigePhase.playing);
      expect(r.evolution.pending, 0);
      expect(r.evolution.closingPending, isFalse);
      r.dispose();
      s.dispose();
    },
  );
  test(
    'legacy v15 initializes zero levels and no retroactive cards, preserving the quota deadline',
    () async {
      final s = game()..startDay();
      capture(s, 25);
      await resolveEvolutionFixture(s);
      final j = jsonDecode(s.snapshot());
      j['version'] = 15;
      j.remove('evolution');
      j['meta'].remove('evolution');
      final r = game()..restore(jsonEncode(j));
      expect(r.meta.evolutionLevels, isEmpty);
      expect(r.evolution.lastQuota, 1);
      expect(r.evolution.pending, 0);
      expect(r.feeding.period, 2);
      expect(r.feeding.quotaStartDay, 1);
      expect(r.feeding.growths, 1);
      expect(r.meta.starLedger.toJson(), s.meta.starLedger.toJson());
      expect(r.economy.generated, s.economy.generated);
      r.dispose();
      s.dispose();
    },
  );
  test(
    'DEBUG choices change no normal checkpoint, permanent level or run data',
    () async {
      final s = game();
      await s.save();
      final baseline = s.snapshot();
      s.enterDebug();
      s.startDay();
      capture(s, 25);
      await resolveEvolutionFixture(s);
      expect(s.meta.evolutionLevels, isNotEmpty);
      s.exitDebug();
      expect(s.snapshot(), baseline);
      expect(s.meta.evolutionLevels, isEmpty);
      s.dispose();
    },
  );
}
