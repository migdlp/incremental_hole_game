import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/special_abilities.dart';
import 'package:incremental_hole_game/features/feeding/domain/feeding_progress.dart';
import 'package:incremental_hole_game/features/feeding/presentation/feeding_summary.dart';
import '../test_support.dart';

void main() {
  final catalog = testCatalog(automaticSpawns: false);
  GameSession session() => GameSession(catalog, MemoryStore());
  void capture(GameSession s, int count, {bool golden = false}) {
    final b = s.board!;
    for (var i = 0; i < count; i++) {
      b.balls.add(Ball(b.nextId++, b.holePosition, Vec.zero, golden: golden));
    }
    s.tick(1 / 60);
  }

  Map<String, dynamic> historical(
    GameSession s, {
    int period = 1,
    int normal = 0,
    int instant = 0,
    int growths = 0,
    bool met = false,
  }) {
    final j = jsonDecode(s.snapshot()) as Map<String, dynamic>;
    j['version'] = 13;
    j['feeding'] = {
      'startDay': 1,
      'period': period,
      'completedDays': 0,
      'normal': normal,
      'instant': instant,
      'runNormal': normal,
      'runInstant': instant,
      'target': met ? normal + instant : normal + instant + 10,
      'quotaStep': 10,
      'growths': growths,
      'growthPeriod': met ? period : period - 1,
    };
    return j;
  }

  test('90 plus 30 rolls 20 into the next target immediately', () {
    final f = FeedingProgress(startDay: 1);
    expect(f.credit(1, normal: 90, instant: 0), isEmpty);
    expect(f.credit(1, normal: 30, instant: 0), [1]);
    expect(f.period, 2);
    expect(f.target, BigInt.from(1000));
    expect(f.points, BigInt.from(20));
    expect(f.remaining, BigInt.from(980));
  });
  test('1200 emits two ordered events and retains all excess', () {
    final f = FeedingProgress(startDay: 1);
    expect(f.credit(1, normal: 1200, instant: 0), [1, 2]);
    expect(f.target, BigInt.from(10000));
    expect(f.points, BigInt.from(100));
    expect(f.growths, 2);
    expect(f.credit(1, normal: 0, instant: 0), isEmpty);
  });
  test('quotas beyond double and 64-bit limits serialize exactly', () {
    final f = FeedingProgress(startDay: 1);
    final amount = BigInt.parse('123456789012345678901234567890123456789');
    final events = f.creditBalls(1, normal: amount, instant: BigInt.zero);
    var consumed = BigInt.zero;
    for (final n in events) {
      consumed += BigInt.from(100) * BigInt.from(10).pow(n - 1);
    }
    expect(f.points + consumed, amount);
    final j = jsonDecode(jsonEncode(f.toJson())) as Map<String, dynamic>;
    final restored = FeedingProgress.fromJson(j, day: 1, running: true);
    expect(restored.toJson(), f.toJson());
    expect(restored.fraction!.isFinite, isTrue);
    final astronomical = BigInt.from(10).pow(500);
    restored.creditBalls(1, normal: astronomical, instant: BigInt.one);
    expect(restored.target! >= astronomical, isTrue);
    expect(restored.fraction!.isFinite, isTrue);
  });
  test(
    'golden and combo captures count once while money keeps its multipliers',
    () {
      final s = session()..levels['reward'] = 2;
      s.economy.balance = 500;
      s.startDay();
      capture(s, 10, golden: true);
      expect(s.feeding.points, BigInt.from(10));
      expect(s.economy.generated, greaterThan(10));
      expect(s.economy.balance, 500);
      final before = s.feeding.points;
      s.tick(.1);
      expect(s.feeding.points, before); // Visual money never feeds.
      s.dispose();
    },
  );
  test(
    'mass capture creates each P01 reward and applies each AJ-005A growth',
    () async {
      final s = session()..startDay();
      final base = s.board!.captureRadius;
      capture(s, 1200);
      expect(s.feeding.period, 3);
      expect(s.feeding.points, BigInt.from(100));
      expect(s.board!.captureRadius / base, closeTo(math.pow(1.16, 1), 1e-12));
      expect(s.meta.starLedger.quota, 2);
      expect(s.meta.starLedger.pending.map((p) => p.id).toSet().length, 2);
      await s.pendingWrites;
      final raw = s.snapshot();
      final restored = session()
        ..restore(raw)
        ..resume();
      restored.tick(.1);
      expect(restored.feeding.growths, 2);
      expect(restored.meta.starLedger.pending.length, 2);
      expect(restored.board!.captureRadius, s.board!.captureRadius);
      s.dispose();
      restored.dispose();
    },
  );
  test(
    'capture-all counts each valid ball once regardless of golden value',
    () {
      final s = session()..enterDebug();
      s.debugBuyAll();
      s.startDay();
      final b = s.board!;
      b.specials.captureCharge = b.specials.cooldown(SpecialAbility.captureAll);
      for (var i = 0; i < 50; i++) {
        b.balls.add(
          Ball(b.nextId++, const Vec(80, 300), Vec.zero, golden: i.isEven),
        );
      }
      expect(s.activateSpecial(SpecialAbility.captureAll), isTrue);
      s.tick(1 / 60);
      expect(s.feeding.points, BigInt.from(50));
      expect(b.captured, 50);
      s.tick(.1);
      expect(s.feeding.points, BigInt.from(50));
      s.dispose();
    },
  );
  test(
    'empty days, pause, store and restart preserve partial feeding',
    () async {
      final s = session()..startDay();
      capture(s, 90);
      s.pause();
      capture(s, 1);
      expect(s.feeding.points, BigInt.from(90));
      s.resume();
      s.finishDay();
      for (var i = 0; i < 30; i++) {
        s.startDay();
        s.finishDay();
      }
      expect(s.canPlayRun, isTrue);
      expect(s.feeding.points, BigInt.from(90));
      s.economy.balance = 1000;
      expect(
        s.purchase(catalog.definitions.firstWhere((d) => d.id == 'hand')),
        isTrue,
      );
      await s.save();
      final restored = session()
        ..restore(s.snapshot())
        ..startDay();
      capture(restored, 10);
      expect(restored.feeding.period, 2);
      expect(restored.feeding.points, BigInt.zero);
      s.dispose();
      restored.dispose();
    },
  );
  test(
    'migration never converts historical money or regrants growth/rewards',
    () {
      final s = session();
      final old = historical(s, period: 3, normal: 1234, growths: 2);
      old['balance'] = 789;
      final r = session()..restore(jsonEncode(old));
      expect(r.feeding.period, 3);
      expect(r.feeding.points, BigInt.zero);
      expect(r.feeding.target, BigInt.from(10000));
      expect(r.feeding.growths, 2);
      expect(r.economy.balance, 789);
      r.startDay();
      r.tick(.1);
      expect(r.meta.starLedger.pending, isEmpty);
      expect(r.feeding.growths, 2);
      s.dispose();
      r.dispose();
    },
  );
  test('already met legacy quota is advanced without another growth', () {
    final s = session();
    final old = historical(s, normal: 10, met: true, growths: 1);
    final r = session()
      ..restore(jsonEncode(old))
      ..startDay();
    expect(r.feeding.period, 2);
    expect(r.feeding.target, BigInt.from(1000));
    r.tick(.1);
    expect(r.feeding.growths, 1);
    expect(r.meta.starLedger.pending, isEmpty);
    s.dispose();
    r.dispose();
  });
  test(
    'active monetary legacy run starts safe partial baseline then counts only new balls',
    () {
      final s = session()..startDay();
      capture(s, 3, golden: true);
      final old = historical(
        s,
        normal: s.board!.normalFood,
        instant: s.board!.instantFood,
      );
      final r = session()
        ..restore(jsonEncode(old))
        ..resume();
      expect(r.feeding.points, BigInt.zero);
      capture(r, 1);
      expect(r.feeding.points, BigInt.one);
      final twice = session()
        ..restore(r.snapshot())
        ..resume();
      twice.tick(.1);
      expect(twice.feeding.points, BigInt.one);
      s.dispose();
      r.dispose();
      twice.dispose();
    },
  );
  test('malformed huge counters and growth records reject atomically', () {
    final s = session()..startDay();
    capture(s, 100);
    final raw = s.snapshot();
    for (final change in <void Function(dynamic)>[
      (j) => j['feeding']['normal'] = 1,
      (j) => j['feeding']['normal'] = '-1',
      (j) => j['feeding']['target'] = '1001',
      (j) => j['feeding']['growths'] = 2,
      (j) => j['feeding']['growthPeriod'] = 0,
      (j) => j['feeding']['runBalls'] = '99',
    ]) {
      final j = jsonDecode(raw);
      change(j);
      expect(() => s.restore(jsonEncode(j)), throwsFormatException);
      expect(s.snapshot(), raw);
    }
    s.dispose();
  });
  testWidgets(
    'summary shows exact balls, current quota and remaining without deadlines',
    (tester) async {
      final s = session();
      s.feeding.credit(1, normal: 3550, instant: 0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FeedingSummary(session: s)),
        ),
      );
      expect(find.text('CUOTA 3'), findsOneWidget);
      expect(find.text('2.450 / 10.000 bolas'), findsOneWidget);
      expect(find.text('Faltan 7.550.'), findsOneWidget);
      expect(find.textContaining('jornada'), findsNothing);
      s.dispose();
    },
  );
}
