import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/upgrades/presentation/skill_tree_screen.dart';
import '../test_support.dart';

void main() {
  test(
    'trial reports retain combo peaks and exact collected/lost money',
    () async {
      final store = MemoryStore();
      final session = GameSession(testCatalog(), store)..enterDebug();
      await session.pendingWrites;
      final writes = store.writes.length;
      session.debugPurchase('combo', 1);
      session.startDay();
      final board = session.board!;
      for (var i = 0; i < 10; i++) {
        board.balls.add(
          Ball(board.nextId++, Board.hole, Vec.zero, golden: i == 9),
        );
        session.tick(1 / 60);
      }
      for (var i = 0; i < 61; i++) {
        session.tick(1 / 60);
      }
      expect(board.combo.multiplier, 1);
      final coin = board.coins.first;
      session.touch(coin.position);
      session.release();
      final collected = session.economy.collected;
      expect(collected, greaterThan(0));
      final emitted = board.spawned;
      expect(emitted, greaterThan(0));
      session.finishDay();
      session.finishDay();
      final report = session.debugReports.single;
      expect(report.spawned, emitted);
      expect(report.captured, 10);
      expect(report.goldenCaptured, 1);
      expect(report.maxCombo, 3);
      expect(report.generated, 44);
      expect(report.collected, collected);
      expect(report.lost, 44 - collected);
      expect(session.progress.last!.lost, report.lost);
      await session.save();
      expect(store.writes.length, writes);
      session.debugReset();
      expect(session.debugReports, isEmpty);
      session.exitDebug();
      session.dispose();
    },
  );

  test('reports are bounded, read only and discarded on debug exit', () {
    final session = GameSession(testCatalog(), MemoryStore())..enterDebug();
    for (var i = 0; i < 25; i++) {
      session.startDay();
      session.finishDay();
    }
    expect(session.debugReports.length, 20);
    expect(session.debugReports.first.day, 6);
    expect(() => session.debugReports.clear(), throwsUnsupportedError);
    session.exitDebug();
    expect(session.debugReports, isEmpty);
    session.startDay();
    session.finishDay();
    expect(session.debugReports, isEmpty);
    session.dispose();
  });

  testWidgets('the debug panel shows a selectable report on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final session = GameSession(testCatalog(), MemoryStore())..enterDebug();
    session.startDay();
    session.finishDay();
    await tester.pumpWidget(
      MaterialApp(home: SkillTreeScreen(session: session)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tree-debug-tools')));
    await tester.pumpAndSettle();
    final report = find.byKey(const ValueKey('debug-day-report'));
    await tester.ensureVisible(report);
    expect(
      tester.widget<SelectableText>(report).data,
      session.debugReports.last.summary,
    );
    expect(find.byKey(const ValueKey('debug-copy-reports')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await session.pendingWrites;
    session.dispose();
  });
}
