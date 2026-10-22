import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/special_abilities.dart';
import 'package:incremental_hole_game/features/board/presentation/garden_game.dart';
import 'package:incremental_hole_game/features/feeding/domain/feeding_progress.dart';
import 'package:incremental_hole_game/features/feeding/presentation/feeding_summary.dart';
import 'package:incremental_hole_game/features/upgrades/domain/catalog.dart';
import '../test_support.dart';

void main() {
  final catalog = testCatalog();
  void capture(GameSession s, {bool golden = false}) {
    final b = s.board!;
    b.balls.add(Ball(b.nextId++, b.holePosition, Vec.zero, golden: golden));
    s.tick(1 / 60);
  }

  void tick(GameSession s, double seconds) {
    for (var i = 0; i < (seconds * 60).round(); i++) {
      s.tick(1 / 60);
    }
  }

  GameSession session({
    MemoryStore? store,
    Map<String, int> levels = const {},
  }) {
    return GameSession(catalog, store ?? MemoryStore(), eventSeed: 42)
      ..levels.addAll(levels);
  }

  test(
    'base economic value feeds immediately without collecting coins or consuming money',
    () {
      final s = session(levels: {'hand': 1, 'reward': 2})
        ..economy.balance = 500;
      s.startDay();
      capture(s);
      expect(s.feeding.points, 3);
      expect(s.economy.generated, 3);
      expect(s.economy.collected, 0);
      expect(s.economy.balance, 500);
      capture(s, golden: true);
      expect(s.feeding.points, 33);
      expect(s.rewards.outstanding, 33);
      s.finishDay(); // Uncollected coins are lost, feeding stays.
      expect(s.economy.balance, 533);
      expect(s.feeding.points, 33);
      expect(s.feeding.completedDays, 1);
      s.dispose();
    },
  );

  test(
    'all purchased global values, golden times ten and streaks feed at full reward',
    () {
      for (var level = 0; level <= 5; level++) {
        final s = session(
          levels: {'hand': 1, 'combo': 1, if (level > 0) 'reward': level},
        )..startDay();
        final value = [1, 2, 3, 5, 8, 13][level];
        for (var i = 0; i < 12; i++) {
          capture(s, golden: i == 4 || i == 9);
        }
        expect(s.feeding.points, 68 * value);
        expect(s.board!.combo.multiplier, 3);
        expect(s.economy.generated, s.feeding.points);
        expect(s.board!.normalFood, s.feeding.points);
        s.dispose();
      }
    },
  );

  test(
    'Board capture events report base feeding exactly once, including swept fast capture',
    () {
      final b = Board(catalog.settings({}));
      b.balls.add(
        Ball(
          b.nextId++,
          b.holePosition + const Vec(0, 25),
          const Vec(0, -380),
          golden: true,
        ),
      );
      var food = 0;
      for (var i = 0; i < 30; i++) {
        final events = b.update(1 / 240, producing: false);
        food += events.normalFood + events.instantFood;
      }
      expect(food, 10);
      expect(b.normalFood, 10);
      expect(b.captured, 1);
      expect(b.balls, isEmpty);
    },
  );

  test(
    'same-step ordinary and golden captures maintain their individual base values',
    () {
      final s = session()..startDay();
      final b = s.board!;
      b.balls.addAll([
        Ball(b.nextId++, b.holePosition, Vec.zero),
        Ball(b.nextId++, b.holePosition, Vec.zero, golden: true),
      ]);
      s.tick(1 / 60);
      expect(s.feeding.points, 11);
      expect(s.feeding.runNormal, 11);
      expect(b.captured, 2);
      s.tick(1 / 60);
      expect(s.feeding.points, 11);
      s.dispose();
    },
  );

  test(
    'Capture total also feeds its full normal, golden and streak rewards once',
    () {
      final s = session(
        levels: {'hand': 1, 'capture_all': 1, 'reward': 1, 'combo': 1},
      )..startDay();
      for (var i = 0; i < 4; i++) {
        capture(s);
      }
      final b = s.board!;
      b.balls.addAll([
        Ball(b.nextId++, const Vec(100, 250), Vec.zero),
        Ball(b.nextId++, const Vec(240, 250), Vec.zero, golden: true),
      ]);
      b.specials.captureCharge = b.specials.cooldown(SpecialAbility.captureAll);
      expect(s.activateSpecial(SpecialAbility.captureAll), isTrue);
      s.tick(1 / 60);
      expect(s.feeding.normalPoints, 8);
      expect(s.feeding.instantPoints, 44);
      expect(s.feeding.points, 52);
      expect(s.economy.generated, 52);
      s.tick(1 / 60);
      expect(s.feeding.points, 52);
      capture(s);
      expect(s.feeding.normalPoints, 12);
      expect(s.feeding.points, 56);
      s.dispose();
    },
  );

  test(
    'early completion neither ends the five-day period nor grants additional money',
    () {
      final s = session()..economy.balance = 300;
      s.enterDebug();
      s.debugConfigureFeeding(quotas: true, target: 1);
      s.startDay();
      capture(s);
      expect(s.feeding.met, isTrue);
      expect(s.feeding.due, isFalse);
      expect(s.running, isTrue);
      expect(s.economy.balance, 300);
      s.finishDay();
      expect(s.feeding.remainingDays, 4);
      for (var i = 0; i < 4; i++) {
        s.startDay();
        expect(s.feeding.points, 1);
        s.finishDay();
      }
      expect(s.feeding.due, isTrue);
      expect(s.feeding.met, isTrue);
      expect(s.feeding.period, 1);
      expect(s.economy.balance, 301);
      s.startDay();
      expect(s.feeding.period, 2);
      expect(s.feeding.points, 0);
      expect(s.feeding.target, 1 + s.feedingQuotaStep);
      expect(s.feeding.remainingDays, 5);
      s.dispose();
    },
  );

  test(
    'five-day accumulation resets only when the next period actually begins',
    () {
      final feed = FeedingProgress(startDay: 1, target: 10, quotaStep: 5);
      for (var day = 1; day <= 5; day++) {
        feed.beginDay(day);
        feed.credit(day, normal: 3, instant: 0);
        feed.finishDay(day);
        expect(feed.points, day * 3);
        expect(feed.remainingDays, 5 - day);
      }
      expect(feed.target, 10);
      expect(feed.nextTarget, 15);
      expect(feed.points, 15);
      feed.beginDay(6);
      expect(feed.target, 15);
      expect(feed.points, 0);
      expect(feed.runNormal, 0);
    },
  );

  test(
    'exact quota succeeds and overfeeding never carries as debt or a credit into the next period',
    () {
      for (final amount in [10, 25]) {
        final feed = FeedingProgress(startDay: 1, target: 10, quotaStep: 10);
        for (var day = 1; day <= 5; day++) {
          feed.beginDay(day);
          if (day == 1) feed.credit(day, normal: amount, instant: 0);
          feed.finishDay(day);
        }
        expect(feed.met, isTrue);
        expect(feed.missed, isFalse);
        feed.beginDay(6);
        expect(feed.points, 0);
        expect(feed.target, 20);
      }
    },
  );

  test(
    'trial failure at the fifth deadline is reversible and never resets real progress',
    () async {
      final store = MemoryStore();
      final s = session(store: store)..economy.balance = 777;
      final baseline = s.snapshot();
      s.enterDebug();
      await s.pendingWrites;
      final writes = store.writes.length;
      s.debugConfigureFeeding(quotas: true, target: 10);
      for (var i = 0; i < 4; i++) {
        s.debugSimulateEmptyDay();
        expect(s.debugFeedingFailed, isFalse);
      }
      s.debugSimulateEmptyDay();
      expect(s.feeding.missed, isTrue);
      expect(s.debugFeedingFailed, isTrue);
      expect(s.feeding.remainingDays, 0);
      s.startDay();
      expect(s.running, isFalse);
      expect(s.economy.balance, 777);
      await s.save();
      expect(store.writes.length, writes);
      s.debugRestartFeedingPeriod();
      expect(s.debugFeedingFailed, isFalse);
      expect(s.feeding.remainingDays, 5);
      s.exitDebug();
      expect(s.snapshot(), baseline);
      s.dispose();
    },
  );

  test('normal play now ends on the fifth missed quota after S03 approval', () {
    final s = session(levels: {'hand': 1})..economy.balance = 99;
    for (var i = 0; i < 5; i++) {
      s.startDay();
      expect(s.running, isTrue);
      s.finishDay();
    }
    expect(s.canPlayRun, isFalse);
    expect(s.economy.balance, 0);
    expect(s.levels, isEmpty);
    expect(s.progress.day, 1);
    expect(s.meta.stars, 0);
    s.dispose();
  });

  test('pause and background cannot feed or consume quota days', () {
    final s = session()..startDay();
    capture(s);
    s.pause();
    final saved = s.snapshot();
    tick(s, 20);
    expect(s.snapshot(), saved);
    s.resume();
    s.setBackgrounded(true);
    final background = s.snapshot();
    tick(s, 20);
    expect(s.snapshot(), background);
    expect(s.feeding.completedDays, 0);
    s.dispose();
  });

  test('finished production cannot add captures or feeding', () {
    final s = session()..startDay();
    final b = s.board!;
    tick(s, 15.1);
    final before = s.feeding.points;
    b.balls.add(Ball(b.nextId++, b.holePosition, Vec.zero, golden: true));
    tick(s, 1);
    expect(s.board, isNull);
    expect(s.feeding.points, before);
    expect(s.feeding.completedDays, 1);
    s.dispose();
  });

  test(
    'multiple restores never replay captures or inflate the period ledger',
    () {
      final s = session(levels: {'hand': 1, 'combo': 1})..startDay();
      for (var i = 0; i < 12; i++) {
        capture(s, golden: i == 4);
      }
      final saved = s.snapshot();
      for (var i = 0; i < 5; i++) {
        s.restore(saved);
        expect(s.feeding.points, 41);
        expect(s.paused, isTrue);
        s.resume();
        s.tick(1 / 60);
        expect(s.feeding.points, 41);
      }
      capture(s);
      expect(s.feeding.points, 44);
      expect(s.board!.captured, 13);
      s.dispose();
    },
  );

  test(
    'night saves and restored fifth-day completion do not grant a second period',
    () async {
      final s = session();
      s.enterDebug();
      s.debugConfigureFeeding(quotas: true, target: 1);
      for (var i = 0; i < 5; i++) {
        s.startDay();
        if (i == 0) capture(s);
        s.finishDay();
      }
      final saved = s.snapshot();
      final restored = session()..restore(saved);
      expect(restored.feeding.period, 1);
      expect(restored.feeding.completedDays, 5);
      expect(restored.feeding.points, 1);
      await restored.save();
      restored.startDay();
      expect(restored.feeding.period, 2);
      expect(restored.feeding.target, 11);
      expect(restored.feeding.points, 0);
      restored.finishDay();
      restored.restore(restored.snapshot());
      expect(restored.feeding.completedDays, 1);
      s.dispose();
      restored.dispose();
    },
  );

  test('a completed day is idempotent and out-of-order credit is rejected', () {
    final feed = FeedingProgress(startDay: 1);
    feed.beginDay(1);
    feed.credit(1, normal: 2, instant: 0);
    expect(feed.finishDay(1), isTrue);
    expect(feed.finishDay(1), isFalse);
    expect(feed.completedDays, 1);
    expect(() => feed.credit(1, normal: 1, instant: 0), throwsStateError);
    expect(() => feed.beginDay(3), throwsStateError);
    expect(() => feed.credit(2, normal: -1, instant: 0), throwsArgumentError);
  });

  test(
    'v7 interrupted days finish unchanged; feeding starts on the next full day',
    () {
      var s = session(levels: {'hand': 1})..economy.balance = 200;
      s.startDay();
      capture(s, golden: true);
      final old = jsonDecode(s.snapshot()) as Map<String, dynamic>;
      old['version'] = 7;
      old.remove('feeding');
      old['run']['remaining'] += 5;
      old['run']['balanceVersion'] = 13;
      old['run']['settings'] = catalog.settings({
        'hand': 1,
      }, balanceVersion: 13).toJson();
      (old['run']['board'] as Map).remove('feeding');
      (old['run']['board'] as Map).remove('automaticCoins');
      old['run']['board']['coins'] = [
        {
          'id': old['run']['board']['nextId']++,
          'p': [120.0, 250.0],
          'value': 10,
          'landing': 0.0,
        },
      ];
      s.dispose();
      s = session()..restore(jsonEncode(old));
      expect(s.board!.settings.balanceVersion, 13);
      expect(s.feeding.startDay, 2);
      expect(s.feeding.points, 0);
      s.resume();
      capture(s);
      expect(s.feeding.points, 0);
      s.finishDay();
      expect(s.feeding.completedDays, 0);
      s.startDay();
      expect(s.board!.settings.balanceVersion, 18);
      capture(s, golden: true);
      expect(s.feeding.points, 10);
      expect(s.economy.balance, 211);
      expect(s.levels, {'hand': 1});
      s.dispose();
    },
  );

  test(
    'v7 night saves keep currency, upgrades and day without inventing historical feeding',
    () {
      final s = session(levels: {'hand': 1})..economy.balance = 200;
      s.enterDebug();
      for (var i = 0; i < 7; i++) {
        s.startDay();
        capture(s);
        s.finishDay();
      }
      final data = jsonDecode(s.snapshot()) as Map<String, dynamic>;
      data['version'] = 7;
      data.remove('feeding');
      s.restore(jsonEncode(data));
      expect(s.progress.day, 8);
      expect(s.feeding.startDay, 8);
      expect(s.feeding.points, 0);
      expect(s.feeding.period, 1);
      expect(s.economy.balance, 207);
      expect(s.levels, {'hand': 1});
      s.dispose();
    },
  );

  test(
    'invalid feeding records and mismatched board totals reject restore atomically',
    () {
      final s = session()..startDay();
      capture(s);
      final saved = s.snapshot();
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (d) => d.remove('feeding'),
        (d) => d['feeding']['normal'] = -1,
        (d) => d['feeding']['completedDays'] = 6,
        (d) => d['feeding']['runNormal'] = 2,
        (d) => d['feeding']['startDay'] = 10,
        (d) => d['feeding']['target'] = 0,
        (d) => d['feeding']['instant'] = -1,
        (d) => d['run']['board']['feeding']['normal'] = 2,
        (d) => d['run']['board']['feeding']['instant'] = -1,
        (d) => d['run']['board'].remove('feeding'),
      ]) {
        final data = jsonDecode(saved) as Map<String, dynamic>;
        mutate(data);
        expect(() => s.restore(jsonEncode(data)), throwsA(isA<Object>()));
        expect(s.snapshot(), saved);
      }
      s.dispose();
    },
  );

  test(
    'trial quota amounts are configurable positive integers, not a production balance plan',
    () {
      final csv = File('docs/balance.csv').readAsStringSync();
      expect(catalog.base['feeding_quota_initial'], 10);
      expect(catalog.base['feeding_quota_step'], 10);
      expect(
        () => UpgradeCatalog.fromCsv(
          csv.replaceFirst(
            'feeding_quota_initial,10',
            'feeding_quota_initial,0',
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => UpgradeCatalog.fromCsv(
          csv.replaceFirst('feeding_quota_step,10', 'feeding_quota_step,1.5'),
        ),
        throwsFormatException,
      );
      expect(
        catalog.settings({}, balanceVersion: 13)['feeding_quota_initial'],
        0,
      );
    },
  );

  testWidgets(
    'between-day summary shows objective, accumulated feeding and remaining days without a day number',
    (tester) async {
      final s = session();
      s.enterDebug();
      s.debugConfigureFeeding(quotas: true, target: 10);
      s.startDay();
      capture(s);
      s.finishDay();
      await tester.pumpWidget(GardenApp(session: s));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('feeding-summary')),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Alimenta al agujero · 1 / 10'), findsOneWidget);
      expect(find.text('4 jornadas restantes'), findsOneWidget);
      expect(find.text('Día 1'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      s.dispose();
    },
  );

  test(
    'circular progress is below the balls and does not change capture geometry or simulation',
    () async {
      final s = session();
      s.enterDebug();
      s.debugConfigureFeeding(quotas: true, target: 10);
      s.startDay();
      capture(s);
      final b = s.board!;
      b.balls.add(Ball(b.nextId++, Board.hole + const Vec(0, -35), Vec.zero));
      final game = GardenGame(s)..onGameResize(Vector2(360, 560));
      Future<List<int>> pixels() async {
        final recorder = ui.PictureRecorder();
        game.render(ui.Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(360, 560);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final data = List<int>.of(bytes.buffer.asUint8List());
        image.dispose();
        picture.dispose();
        return data;
      }

      final before = s.snapshot();
      final partial = await pixels();
      expect(s.snapshot(), before);
      expect(b.settings['hole_capture_radius'], 22);
      s.feeding.credit(s.progress.day, normal: 9, instant: 0);
      final full = await pixels();
      expect(partial, isNot(orderedEquals(full)));
      final index = (15 * 360 + 180) * 4;
      expect(partial.sublist(index, index + 4), full.sublist(index, index + 4));
      s.dispose();
    },
  );

  testWidgets(
    'small-screen summary and trial failure remain usable with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final s = session();
      s.enterDebug();
      s.debugConfigureFeeding(quotas: true, target: 10);
      for (var i = 0; i < 5; i++) {
        s.debugSimulateEmptyDay();
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: FeedingSummary(session: s)),
          ),
        ),
      );
      expect(find.text('Cuota no alcanzada · 0 / 10'), findsOneWidget);
      await tester.ensureVisible(find.text('Reiniciar período de prueba'));
      await tester.tap(find.text('Reiniciar período de prueba'));
      expect(s.debugFeedingFailed, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
  testWidgets(
    'DEBUG exposes quota trials, expiry and restart while preserving the real save',
    (tester) async {
      final s = session();
      final baseline = s.snapshot();
      await tester.pumpWidget(GardenApp(session: s));
      await tester.tap(find.text('Tienda'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tree-debug-tools')));
      await tester.pumpAndSettle();
      final tile = find.byKey(const ValueKey('debug-feeding-tools'));
      await tester.ensureVisible(tile);
      await tester.tap(find.text('Alimentación y cuotas'));
      await tester.pumpAndSettle();
      final enabled = find.byKey(const ValueKey('debug-feeding-enabled'));
      await tester.ensureVisible(enabled);
      await tester.tap(enabled);
      await tester.pumpAndSettle();
      expect(s.debugFeedingQuotas, isTrue);
      final simulate = find.byKey(const ValueKey('debug-feeding-empty-day'));
      for (var i = 0; i < 5; i++) {
        await tester.ensureVisible(simulate);
        await tester.tap(simulate);
        await tester.pumpAndSettle();
      }
      expect(s.debugFeedingFailed, isTrue);
      final restart = find.byKey(const ValueKey('debug-feeding-restart'));
      await tester.ensureVisible(restart);
      await tester.tap(restart);
      await tester.pumpAndSettle();
      expect(s.debugFeedingFailed, isFalse);
      final exit = find.byKey(const ValueKey('debug-exit'));
      await tester.ensureVisible(exit);
      await tester.tap(exit);
      await tester.pumpAndSettle();
      expect(s.snapshot(), baseline);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
}
