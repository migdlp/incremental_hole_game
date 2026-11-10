import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/balance/domain/balance_metrics.dart';
import 'package:incremental_hole_game/features/balance/presentation/balance_export_panel.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import '../test_support.dart';

void main() {
  test('observer on/off preserves board physics, RNG and reward events', () {
    final settings = testCatalog().settings({
      'generator': 3,
      'double_spawn': 1,
      'launcher': 1,
      'walls': 3,
      'robot': 1,
    });
    final on = Board(settings, randomState: 83);
    final off = Board(settings, randomState: 83, metricsEnabled: false);
    for (var i = 0; i < 1200; i++) {
      final a = on.update(1 / 60, producing: i < 900);
      final b = off.update(1 / 60, producing: i < 900);
      expect(a.rewards, b.rewards);
      expect(a.captured, b.captured);
    }
    final a = on.toJson()..remove('balanceMetrics');
    final b = off.toJson()..remove('balanceMetrics');
    expect(a, b);
    expect(on.metrics.emitted, on.spawned);
    expect(on.metrics.count('captured'), on.captured);
    expect(on.metrics.report(on.balls.length)['validation'], isEmpty);
    for (final source in ['main', 'launcher']) {
      final blocked = on.metrics.counts.entries
          .where((e) => e.key.startsWith('blocked.$source.'))
          .fold(0, (int n, e) => n + e.value);
      expect(
        on.metrics.count('attempts.$source'),
        on.metrics.count('successful.$source') + blocked,
      );
    }
  });
  test('restored birth cohort and counts continue without double counting', () {
    final settings = testCatalog().settings({});
    final b = Board(settings);
    for (var i = 0; i < 120; i++) {
      b.update(1 / 60, producing: true);
    }
    final raw = jsonDecode(jsonEncode(b.toJson())) as Map<String, dynamic>;
    final restored = Board.fromJson(settings, raw);
    expect(restored.metrics.toJson(), b.metrics.toJson());
    for (var i = 0; i < 120; i++) {
      b.update(1 / 60, producing: true);
      restored.update(1 / 60, producing: true);
    }
    expect(restored.metrics.toJson(), b.metrics.toJson());
    raw['balanceMetrics'] = {'broken': true};
    final legacy = Board.fromJson(settings, raw);
    expect(legacy.metrics.partial, isTrue);
    expect(legacy.metrics.capturedBaseline, raw['captured']);
  });
  test(
    'normal records survive shop, pause, restore and DEBUG export access',
    () async {
      final session = GameSession(testCatalog(), MemoryStore(), eventSeed: 4);
      session.startDay();
      for (var i = 0; i < 90; i++) {
        session.tick(1 / 60);
      }
      session.pause();
      final before = session.board!.metrics.toJson();
      for (var i = 0; i < 120; i++) {
        session.tick(1 / 60);
      }
      expect(session.board!.metrics.toJson(), before);
      final restored = GameSession(testCatalog(), MemoryStore());
      restored.restore(session.snapshot());
      expect(restored.board!.metrics.toJson(), before);
      restored.finishDay();
      final day = restored.balanceLab.days.single;
      expect(day['test_kind'], 'human_normal');
      expect(day['board']['validation'], isEmpty);
      restored.enterDebug();
      expect(restored.balanceLab.days.single['test_kind'], 'human_normal');
      expect(restored.balanceExportFiles['days.csv'], contains('human_normal'));
      restored.startDay();
      restored.finishDay();
      expect(restored.balanceLab.days.last['test_kind'], 'human_debug');
      restored.exitDebug();
      expect(restored.balanceLab.days.length, 1);
      final again = GameSession(testCatalog(), MemoryStore())
        ..restore(restored.snapshot());
      expect(again.balanceLab.days, restored.balanceLab.days);
      await Future.wait([
        session.pendingWrites,
        restored.pendingWrites,
        again.pendingWrites,
      ]);
      session.dispose();
      restored.dispose();
      again.dispose();
    },
  );
  test(
    'quota defeat keeps final day and end cause before clearing run',
    () async {
      final session = GameSession(testCatalog(), MemoryStore(), eventSeed: 4);
      for (var i = 0; i < 4; i++) {
        session.startDay();
        session.finishDay();
        await session.pendingWrites;
      }
      expect(session.canPlayRun, isFalse);
      expect(session.balanceLab.days.length, 4);
      expect(session.balanceLab.days.last['end_reason'], 'quota_defeat');
      expect(
        session.balanceLab.events.where((e) => e['type'] == 'run_end').length,
        1,
      );
      final before = session.balanceLab.toJson();
      session.finishDay();
      expect(session.balanceLab.toJson(), before);
      session.dispose();
    },
  );
  test('currency, golden and instant captures are observed independently', () {
    final settings = testCatalog(automaticSpawns: false).settings({});
    final b = Board(settings);
    b.balls.add(Ball(1, b.holePosition, Vec.zero, golden: true));
    b.nextId = 2;
    b.metrics.birth(1, 'p02_golden', 1);
    final result = b.update(1 / 60, producing: true);
    expect(result.captured, 1);
    expect(b.metrics.count('captured.p02_golden'), 1);
    expect(b.metrics.count('golden_captured'), 1);
    expect(b.metrics.count('coins_combo_golden'), result.rewards.single);
    expect(b.metrics.report(0)['validation'], isEmpty);
  });
  test(
    'canonical hash, schema recovery, bounded retention and exact exports',
    () {
      expect(
        configurationHash({
          'b': 2,
          'a': [1],
        }),
        configurationHash({
          'a': [1],
          'b': 2,
        }),
      );
      expect(
        BalanceLab.restore({'schema_version': 'future'}).recovered,
        isTrue,
      );
      final lab = BalanceLab();
      final huge = BigInt.from(10).pow(100).toString();
      for (var i = 0; i < 505; i++) {
        lab.finish({
          'id': '$i',
          'test_kind': 'human_normal',
          'coins_earned': huge,
          'coins_collected': huge,
          'board': BoardMetrics().report(0),
        });
      }
      expect(lab.days.length, BalanceLab.maxDays);
      expect(lab.droppedDays, 5);
      expect(lab.csv, contains(huge));
      expect(lab.json(), contains(huge));
      final parsed = BalanceLab.restore(jsonDecode(lab.json()));
      expect(parsed.days.length, lab.days.length);
      for (var i = 0; i < 2010; i++) {
        lab.event('test', {});
      }
      expect(lab.events.length, BalanceLab.maxEvents);
      expect(lab.droppedEvents, 10);
    },
  );
  test('historical metrics freeze nested mutable gameplay snapshots', () {
    final lab = BalanceLab();
    final captures = [1.0];
    lab.active = {'captures': captures};
    final start = lab.active;
    lab.event('observed', {'captures': captures});
    lab.finish({
      'id': 'day',
      'captures': captures,
      'test_kind': 'human_normal',
      'coins_earned': '0',
      'board': BoardMetrics().report(0),
    });
    final checkpoint = lab.checkpoint();
    captures.clear();
    expect(start!['captures'], [1.0]);
    expect(lab.events.single['captures'], [1.0]);
    expect(lab.days.single['captures'], [1.0]);
    expect(lab.checkpoint(), checkpoint);
  });
  test(
    'corrupt optional active metrics cannot invalidate playable save',
    () async {
      final source = GameSession(testCatalog(), MemoryStore())..startDay();
      final raw = jsonDecode(source.snapshot()) as Map<String, dynamic>;
      raw['balanceLab']['active'] = {'quota_start': 'broken'};
      final restored = GameSession(testCatalog(), MemoryStore());
      restored.restore(jsonEncode(raw));
      expect(restored.running, isTrue);
      expect(restored.balanceLab.recovered, isTrue);
      restored.finishDay();
      expect(restored.balanceLab.days.single['partial_start'], isTrue);
      await Future.wait([source.pendingWrites, restored.pendingWrites]);
      source.dispose();
      restored.dispose();
    },
  );
  testWidgets('DEBUG export panel offers local files and copy fallback', (
    tester,
  ) async {
    final session = GameSession(testCatalog(), MemoryStore());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BalanceExportPanel(session: session)),
      ),
    );
    expect(find.text('Exportar session.json'), findsOneWidget);
    expect(find.text('Exportar days.csv'), findsOneWidget);
    expect(find.byKey(const ValueKey('balance-copy-json')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
}
