import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/features/results/domain/results_data.dart';
import 'package:incremental_hole_game/features/results/domain/results_sequence.dart';
import 'package:incremental_hole_game/features/feeding/domain/feeding_progress.dart';
import 'package:incremental_hole_game/features/progression/domain/progress.dart';
import '../test_support.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'dart:convert';
import 'package:incremental_hole_game/features/results/presentation/results_transfer.dart';
import 'package:incremental_hole_game/features/board/presentation/coin_icon.dart';
import 'package:incremental_hole_game/features/results/presentation/results_overlay.dart';

ResultsData data({
  int income = 661,
  int food = 60,
  int before = 10,
  int target = 50,
}) {
  final f = FeedingProgress(startDay: 1, target: target);
  f.credit(1, normal: before, instant: 0);
  f.finishDay(1);
  f.beginDay(2);
  f.credit(2, normal: food - before, instant: 0);
  f.finishDay(2);
  return ResultsData(
    result: DayResult(
      day: 2,
      income: income,
      generated: income,
      captured: 155,
      previousIncome: null,
    ),
    feeding: f,
    balance: 1000 + income,
  );
}

void main() {
  test(
    'exact existing denominations in ascending order, bounded visuals, no zero rows',
    () {
      final d = data();
      expect(d.stacks.map((s) => s.denomination.amount), [1, 10, 50, 100, 500]);
      expect(d.stacks.fold<int>(0, (sum, s) => sum + s.amount), 661);
      final huge = data(income: 9007199254740000);
      expect(huge.stacks.every((s) => s.visualCount <= 6), isTrue);
      expect(huge.stacks.fold<int>(0, (sum, s) => sum + s.amount), huge.income);
      expect(data(income: 0).stacks, isEmpty);
    },
  );
  test('automatic microbatch counts survive restore and never add money', () {
    final s = GameSession(testCatalog(automaticSpawns: false), MemoryStore())
      ..startDay();
    void capture(GameSession game) {
      final b = game.board!;
      b.balls.add(Ball(b.nextId++, b.holePosition, Vec.zero));
      game.tick(1 / 60);
    }

    for (var i = 0; i < 10; i++) {
      capture(s);
    }
    final raw = s.snapshot();
    final r = GameSession(s.catalog, MemoryStore())
      ..restore(raw)
      ..resume();
    capture(r);
    r.finishDay();
    expect(r.progress.last!.collectedCoins, {10: 1, 1: 1});
    expect(r.economy.balance, 11);
    final broken = jsonDecode(raw) as Map<String, dynamic>;
    broken['run']['rewardCounts'] = {'10': 2};
    expect(
      () => GameSession(s.catalog, MemoryStore()).restore(jsonEncode(broken)),
      throwsFormatException,
    );
    s.dispose();
    r.dispose();
  });
  test(
    'historical recorded counts take precedence over presentation splitting',
    () {
      final d = ResultsData(
        result: const DayResult(
          day: 1,
          income: 100,
          generated: 100,
          captured: 1,
          previousIncome: null,
          collectedCoins: {1: 100},
        ),
        feeding: FeedingProgress(startDay: 1),
        balance: 100,
      );
      expect(d.stacks.length, 1);
      expect(d.stacks.single.denomination.amount, 1);
      expect(d.stacks.single.count, 100);
    },
  );
  test(
    'reopening a result after shopping never shows a negative or invented balance',
    () {
      final d = ResultsData(
        result: const DayResult(
          day: 1,
          income: 100,
          generated: 100,
          captured: 100,
          previousIncome: null,
        ),
        feeding: FeedingProgress(startDay: 1),
        balance: 20,
      );
      final s = ResultsSequence(d);
      expect(s.wallet, 20);
      s.advance(10);
      expect(s.wallet, 20);
      expect(s.total, 100);
      s.dispose();
    },
  );
  test(
    'rows finish in order, wallet transfers wait for arrivals and final amounts are exact',
    () {
      final d = data(), s = ResultsSequence(data());
      expect(s.wallet, 1000);
      s.advance(.22);
      expect(s.phase, ResultsPhase.coins);
      s.advance(.5);
      expect(s.total, 0); // one unit completes when its counter reaches one
      expect(s.wallet, 1000);
      s.advance(.7);
      expect(s.row, 1);
      expect(s.wallet, 1001);
      s.advance(4.8);
      expect(s.phase, ResultsPhase.hole);
      expect(s.total, d.income);
      expect(s.wallet, d.balance);
      s.advance(1.4);
      expect(s.done, isTrue);
      expect(s.holeProgress, 1);
      s.dispose();
    },
  );
  test(
    'skip completes exactly one block and rejects stale or rapid duplicate taps',
    () {
      final s = ResultsSequence(data());
      final first = s.generation;
      s.skip(first);
      expect(s.phase, ResultsPhase.hole);
      expect(s.wallet, s.data.balance);
      s.skip(first);
      s.skip(s.generation);
      expect(s.phase, ResultsPhase.hole);
      s.advance(.26);
      s.skip(s.generation);
      expect(s.done, isTrue);
      expect(s.total, s.data.income);
      s.dispose();
    },
  );
  test(
    'zero income goes to feeding, and reduced motion reaches identical final state',
    () {
      final a = ResultsSequence(data(income: 0))..advance(.22);
      expect(a.phase, ResultsPhase.hole);
      expect(a.wallet, 1000);
      final b = ResultsSequence(data())..completeAll();
      expect(b.done, isTrue);
      expect(b.wallet, b.data.balance);
      expect(b.total, b.data.income);
      a.dispose();
      b.dispose();
    },
  );

  testWidgets(
    'progressive reveal, two skips, exact unchanged economy and one shop action',
    (tester) async {
      final s = GameSession(testCatalog(automaticSpawns: false), MemoryStore())
        ..economy.balance = 1000;
      s.startDay();
      s.economy.generated = s.economy.collected = 661;
      s.board!.captured = 155;
      s.feeding.credit(1, normal: 60, instant: 0);
      s.finishDay();
      final saved = s.snapshot();
      await tester.pumpWidget(GardenApp(session: s));
      await tester.pump();
      expect(find.text('Resultados del día'), findsOneWidget);
      expect(find.text('Progreso del hoyo'), findsNothing);
      expect(find.text('Tienda'), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const ValueKey('results-row-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('results-row-10')), findsNothing);
      await tester.tap(find.text('Resultados del día'));
      await tester.pump();
      expect(find.text('Progreso del hoyo'), findsOneWidget);
      expect(find.text('Tienda'), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Resultados del día'));
      await tester.pump();
      expect(find.byKey(const ValueKey('results-shop')), findsOneWidget);
      expect(find.text('CUOTA 1'), findsOneWidget);
      expect(s.economy.balance, 1661);
      expect(s.snapshot(), saved);
      await tester.tap(find.text('Tienda'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('node-hand:1')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await s.pendingWrites;
      s.dispose();
    },
  );
  testWidgets('each flight uses its real row icon and the real global wallet', (
    tester,
  ) async {
    final d = data();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResultsOverlay(
            data: d,
            walletAnchor: GlobalKey(),
            onShop: () async {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<ResultsTransferPainter>()
        .single;
    final root = tester.getTopLeft(find.byType(ResultsOverlay));
    for (final i in [0, 1]) {
      final icon = find.descendant(
        of: find.byKey(
          ValueKey('results-row-${d.stacks[i].denomination.amount}'),
        ),
        matching: find.byType(CoinIcon),
      );
      expect(painter.source(i)!.topLeft, tester.getTopLeft(icon) - root);
    }
    expect(painter.source(0)!.top, lessThan(painter.source(1)!.top));
    final wallet = find
        .ancestor(
          of: find.byKey(const ValueKey('results-wallet')),
          matching: find.byType(Row),
        )
        .first;
    final target = find.descendant(of: wallet, matching: find.byType(CoinIcon));
    expect(painter.target()!.topLeft, tester.getTopLeft(target) - root);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  test(
    'feeding result always shows the immediately active quota after carryover',
    () {
      final d = data(food: 11063, before: 10);
      expect(d.foodBefore, BigInt.zero);
      expect(d.foodAfter, BigInt.from(5513));
      expect(d.target, BigInt.from(50000));
      expect(d.quotaLevel, 4);
    },
  );

  testWidgets(
    'small phone, huge figures and large text stay usable; reduced motion skips both blocks',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = GameSession(testCatalog(automaticSpawns: false), MemoryStore());
      s.startDay();
      s.economy.generated = s.economy.collected = 9007199254740000;
      s.finishDay();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: SafeArea(
                child: ResultsOverlay(
                  data: ResultsData(
                    result: s.progress.last!,
                    feeding: s.feeding,
                    balance: s.economy.balance,
                  ),
                  walletAnchor: GlobalKey(),
                  onShop: () async {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Tienda'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await s.pendingWrites;
      s.dispose();
    },
  );
}
