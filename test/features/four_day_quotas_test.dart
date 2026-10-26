import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/feeding/domain/feeding_progress.dart';
import 'package:incremental_hole_game/features/prestige/domain/meta_progress.dart';
import 'package:incremental_hole_game/features/results/domain/results_data.dart';
import '../test_support.dart';

class QuotaFaultStore extends MemoryStore {
  bool failMain = false;
  @override
  Future<void> save(String contents, {String? previous}) async {
    if (failMain) throw StateError('interrupted normal save');
    await super.save(contents, previous: previous);
  }
}

void main() {
  final catalog = testCatalog(automaticSpawns: false);
  GameSession game([MemoryStore? store]) =>
      GameSession(catalog, store ?? MemoryStore(), eventSeed: 42);
  Future<void> capture(GameSession s, int n) async {
    s.evolution.cardRandom = 0;
    for (var i = 0; i < n; i++) {
      s.board!.balls.add(
        Ball(
          s.board!.nextId++,
          s.board!.holePosition,
          Vec.zero,
          golden: i.isEven,
        ),
      );
    }
    s.tick(1 / 60);
    await resolveEvolutionFixture(s);
  }

  Future<void> closeEmpty(GameSession s) async {
    s.startDay();
    s.finishDay();
    await s.pendingWrites;
  }

  for (var day = 1; day <= 4; day++) {
    test(
      'quota completed on day $day starts the next deadline on that same day',
      () async {
        final s = game();
        for (var i = 1; i < day; i++) {
          await closeEmpty(s);
        }
        s.startDay();
        expect(s.progress.day, day);
        await capture(s, 100);
        expect(s.feeding.period, 2);
        expect(s.feeding.quotaStartDay, day);
        expect(s.feeding.quotaDay(day), 1);
        expect(s.feeding.futureDays(day), 3);
        s.finishDay();
        await s.pendingWrites;
        expect(s.canPlayRun, isTrue);
        expect(s.progress.day, day);
        final data = ResultsData(
          result: s.progress.last!,
          feeding: s.feeding,
          balance: s.economy.balance,
        );
        expect(data.quotaLevel, 2);
        expect(data.foodAfter, BigInt.zero);
        expect(data.quotaDay, 1);
        expect(data.futureDays, 3);
        final r = game()..restore(s.snapshot());
        expect(r.feeding.quotaStartDay, day);
        expect(r.feeding.growths, 1);
        final state = r.snapshot();
        expect(() => r.restore(state), returnsNormally);
        r.dispose();
        s.dispose();
      },
    );
  }
  test(
    '99 at fourth close defeats immediately, clears run, preserves permanent resources',
    () async {
      final s = game();
      final j = jsonDecode(s.snapshot());
      j['meta']['stars'] = 7;
      j['meta']['upgrades'] = {'H01': 1};
      s.restore(jsonEncode(j));
      await s.save();
      for (var i = 0; i < 3; i++) {
        await closeEmpty(s);
      }
      s.startDay();
      await capture(s, 99);
      s.finishDay();
      await s.pendingWrites;
      expect(s.meta.phase, PrestigePhase.defeat);
      expect(s.meta.stars, 7);
      expect(s.meta.owns('H01'), isTrue);
      expect(s.progress.last, isNull);
      expect(s.board, isNull);
      expect(s.levels, isEmpty);
      final revision = s.meta.revision;
      s.finishDay();
      s.startDay();
      s.tick(1);
      expect(s.meta.revision, revision);
      expect(s.running, isFalse);
      expect(s.continueToPrestigeShop(), isTrue);
      await s.pendingWrites;
      expect(s.beginNewRun(), isTrue);
      await s.pendingWrites;
      expect(s.progress.day, 1);
      expect(s.feeding.quotaStartDay, 1);
      expect(s.feeding.points, BigInt.zero);
      expect(s.feeding.target, BigInt.from(100));
      expect(s.feeding.growths, 0);
      expect(s.economy.balance, 100);
      expect(s.normalShopAvailable, isFalse);
      s.dispose();
    },
  );
  test(
    'capture at final valid instant avoids death and grants no extra simulation',
    () async {
      final oldDuration = catalog.base['production_duration']!;
      catalog.base['production_duration'] = 15.005;
      addTearDown(() => catalog.base['production_duration'] = oldDuration);
      final s = game();
      for (var i = 0; i < 3; i++) {
        await closeEmpty(s);
      }
      s.startDay();
      await capture(s, 99);
      advanceToProductionBoundary(s, .005);
      s.board!.balls.add(
        Ball(s.board!.nextId++, s.board!.holePosition, Vec.zero),
      );
      s.tick(.1);
      await s.pendingWrites;
      await resolveEvolutionFixture(s);
      expect(s.meta.phase, PrestigePhase.playing);
      expect(s.progress.last!.captured, 100);
      expect(s.feeding.period, 2);
      expect(s.feeding.quotaStartDay, 4);
      expect(s.meta.starLedger.quota, 1);
      expect(s.feeding.growths, 1);
      s.dispose();
    },
  );
  test(
    'moving balls outside the hole at timeout never save an expired quota',
    () async {
      final oldDuration = catalog.base['production_duration']!;
      catalog.base['production_duration'] = 15.005;
      addTearDown(() => catalog.base['production_duration'] = oldDuration);
      final s = game();
      for (var i = 0; i < 3; i++) {
        await closeEmpty(s);
      }
      s.startDay();
      await capture(s, 99);
      advanceToProductionBoundary(s, .005);
      s.board!.balls.add(
        Ball(
          s.board!.nextId++,
          s.board!.holePosition + const Vec(0, 50),
          const Vec(0, -380),
        ),
      );
      s.tick(.1);
      await s.pendingWrites;
      expect(s.meta.phase, PrestigePhase.defeat);
      expect(s.meta.stars, 0);
      expect(s.progress.last, isNull);
      s.tick(10);
      expect(s.running, isFalse);
      s.dispose();
    },
  );
  test(
    'excess and multiple completions at close preserve exact quotas, growth and rewards',
    () async {
      final s = game();
      await closeEmpty(s);
      s.startDay();
      advanceToProductionBoundary(s, 1 / 60);
      await capture(s, 11200);
      await s.pendingWrites;
      expect(s.meta.phase, PrestigePhase.playing);
      expect(s.progress.day, 2);
      expect(s.feeding.period, 4);
      expect(s.feeding.target, BigInt.from(100000));
      expect(s.feeding.points, BigInt.from(100));
      expect(s.feeding.quotaStartDay, 2);
      expect(s.feeding.growths, 3);
      expect(s.meta.starLedger.quota, 3);
      final r = game()..restore(s.snapshot());
      await r.save();
      r.startDay();
      expect(
        r.board!.captureRadius,
        closeTo(
          catalog.base['hole_capture_radius']! * math.pow(1.16, 1.5),
          1e-8,
        ),
      );
      expect(
        r.meta.starLedger.pending.length,
        s.meta.starLedger.pending.length,
      );
      expect(r.feeding.quotaDay(r.progress.day), 2);
      r.dispose();
      s.dispose();
    },
  );
  test(
    'quota due day is its own start plus three, not a global cycle',
    () async {
      final s = game();
      await closeEmpty(s);
      await closeEmpty(s);
      s.startDay();
      await capture(s, 100);
      s.finishDay();
      await s.pendingWrites;
      expect(s.feeding.quotaStartDay, 3);
      await closeEmpty(s);
      await closeEmpty(s);
      expect(s.canPlayRun, isTrue);
      s.startDay();
      expect(s.progress.day, 6);
      s.finishDay();
      await s.pendingWrites;
      expect(s.meta.phase, PrestigePhase.defeat);
      s.dispose();
    },
  );
  test(
    'pause, background and restores keep third/fourth day deadline and partial progress',
    () async {
      final s = game();
      await closeEmpty(s);
      await closeEmpty(s);
      s.startDay();
      await capture(s, 90);
      s.pause();
      final raw = s.snapshot();
      s.tick(1000);
      expect(s.snapshot(), raw);
      final r = game()..restore(raw);
      expect(r.paused, isTrue);
      expect(r.progress.day, 3);
      expect(r.feeding.quotaStartDay, 1);
      expect(r.feeding.points, BigInt.from(90));
      r.resume();
      r.finishDay();
      await r.pendingWrites;
      r.startDay();
      r.pause();
      final fourth = game()..restore(r.snapshot());
      expect(fourth.progress.day, 4);
      expect(fourth.feeding.quotaDay(4), 4);
      fourth.resume();
      await capture(fourth, 10);
      fourth.finishDay();
      await fourth.pendingWrites;
      expect(fourth.canPlayRun, isTrue);
      s.dispose();
      r.dispose();
      fourth.dispose();
    },
  );
  test(
    'legacy balls save gets safe deadline without re-awarding progress or money',
    () async {
      final s = game()..startDay();
      await capture(s, 1200);
      s.finishDay();
      await s.pendingWrites;
      final j = jsonDecode(s.snapshot());
      j['version'] = 14;
      j['day'] = 30;
      j['last']['day'] = 29;
      j['feeding']['rules'] = 'balls-v1';
      j['feeding'].remove('quotaStartDay');
      j['feeding'].remove('dayClosed');
      j['feeding']['completedDays'] = 29;
      final r = game()..restore(jsonEncode(j));
      expect(r.progress.day, 29);
      expect(r.feeding.quotaStartDay, 29);
      expect(r.feeding.points, BigInt.from(100));
      expect(r.feeding.period, 3);
      expect(r.feeding.growths, 2);
      expect(r.meta.starLedger.toJson(), s.meta.starLedger.toJson());
      expect(r.economy.balance, s.economy.balance);
      await r.save();
      r.startDay();
      expect(r.progress.day, 30);
      expect(r.feeding.quotaDay(30), 2);
      r.finishDay();
      await r.pendingWrites;
      expect(r.canPlayRun, isTrue);
      final rr = game()..restore(r.snapshot());
      expect(rr.feeding.quotaStartDay, 29);
      rr.dispose();
      r.dispose();
      s.dispose();
    },
  );
  test(
    'death checkpoint overrides stale active saves and restores defeat then the same shop',
    () async {
      final store = QuotaFaultStore();
      final s = game(store);
      for (var i = 0; i < 3; i++) {
        await closeEmpty(s);
      }
      s.startDay();
      await s.pendingWrites;
      final stale = s.snapshot();
      store.failMain = true;
      s.finishDay();
      await s.pendingWrites;
      store.candidates = [stale, stale];
      final r = game(store);
      await r.load();
      expect(r.meta.phase, PrestigePhase.defeat);
      expect(r.running, isFalse);
      expect(() => r.restore(stale), throwsFormatException);
      store.failMain = false;
      await r.save();
      expect(r.continueToPrestigeShop(), isTrue);
      await r.pendingWrites;
      final rr = game(store);
      await rr.load();
      expect(rr.meta.phase, PrestigePhase.shop);
      expect(rr.meta.stars, 0);
      expect(rr.beginNewRun(), isTrue);
      await rr.pendingWrites;
      expect(rr.progress.day, 1);
      rr.dispose();
      r.dispose();
      s.dispose();
    },
  );
  test('huge exact quota values retain the independent deadline in JSON', () {
    final f = FeedingProgress(startDay: 1);
    f.creditBalls(1, normal: BigInt.from(10).pow(500), instant: BigInt.zero);
    f.finishDay(1);
    final r = FeedingProgress.fromJson(
      jsonDecode(jsonEncode(f.toJson())),
      day: 1,
      running: false,
    );
    expect(r.toJson(), f.toJson());
    expect(r.quotaStartDay, 1);
    expect(r.futureDays(1), 3);
  });
  test(
    'legacy closed monetary period with zero completed days migrates consistently',
    () async {
      final s = game()..startDay();
      s.finishDay();
      await s.pendingWrites;
      final j = jsonDecode(s.snapshot());
      j['version'] = 13;
      j['day'] = 6;
      j['last']['day'] = 5;
      j['feeding'] = {
        'startDay': 6,
        'period': 2,
        'completedDays': 0,
        'normal': 0,
        'instant': 0,
        'runNormal': 0,
        'runInstant': 0,
        'target': 20,
        'quotaStep': 10,
        'growths': 1,
        'growthPeriod': 1,
      };
      final r = game()..restore(jsonEncode(j));
      expect(r.progress.day, 5);
      expect(r.feeding.quotaStartDay, 5);
      expect(r.feeding.growths, 1);
      expect(r.feeding.target, BigInt.from(1000));
      expect(r.meta.starLedger.pending, isEmpty);
      final rr = game()..restore(r.snapshot());
      await rr.save();
      rr.startDay();
      expect(rr.progress.day, 6);
      expect(rr.feeding.quotaDay(6), 2);
      rr.dispose();
      r.dispose();
      s.dispose();
    },
  );
  test(
    'invalid deadline state rejects atomically, and new days advance only on start',
    () async {
      final s = game();
      await closeEmpty(s);
      final before = s.snapshot();
      expect(s.progress.day, 1);
      expect(s.normalShopAvailable, isTrue);
      for (final mutate in [
        (Map j) => j['feeding']['quotaStartDay'] = 2,
        (Map j) => j['feeding']['dayClosed'] = false,
        (Map j) => j['feeding']['completedDays'] = 0,
        (Map j) => j['feeding'].remove('quotaStartDay'),
      ]) {
        final j = jsonDecode(before);
        mutate(j);
        expect(() => s.restore(jsonEncode(j)), throwsFormatException);
        expect(s.snapshot(), before);
      }
      s.startDay();
      expect(s.progress.day, 2);
      s.pause();
      final paused = s.snapshot();
      s.tick(100);
      expect(s.snapshot(), paused);
      s.dispose();
    },
  );
  testWidgets(
    'deadline appears in results only and defeat skips both reward blocks',
    (tester) async {
      final s = game();
      await tester.pumpWidget(GardenApp(session: s));
      expect(find.textContaining('Jornada 1 de 4'), findsNothing);
      s.startDay();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('results-quota-day')), findsNothing);
      s.finishDay();
      await s.pendingWrites;
      await tester.pump();
      // Skip coins, then reveal the hole card.
      await tester.tap(find.byKey(const ValueKey('visual-day-results')));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.byKey(const ValueKey('visual-day-results')));
      await tester.pumpAndSettle();
      expect(find.text('Jornada 1 de 4'), findsOneWidget);
      expect(find.text('Quedan 3 jornadas'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await closeEmpty(s);
      }
      await tester.pumpAndSettle();
      expect(find.text('DERROTA'), findsOneWidget);
      expect(find.byKey(const ValueKey('visual-day-results')), findsNothing);
      expect(find.byKey(const ValueKey('results-quota-day')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('prestige-continue')));
      await s.pendingWrites;
      await tester.pumpAndSettle();
      expect(find.text('Herencia'), findsOneWidget);
      expect(find.text('DERROTA'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
}
