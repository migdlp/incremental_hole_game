import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/features/upgrades/domain/skill_tree.dart';
import 'package:incremental_hole_game/features/upgrades/presentation/skill_tree_screen.dart';
import '../test_support.dart';

void main() {
  test(
    'compact layout keeps touch targets separated and stays within its canvas',
    () {
      final nodes = SkillTree(testCatalog()).nodes;
      for (var i = 0; i < nodes.length; i++) {
        final node = nodes[i];
        expect(node.x, inInclusiveRange(40, 840));
        expect(node.y, inInclusiveRange(32, 1056));
        for (final other in nodes.skip(i + 1)) {
          expect(
            (Offset(node.x, node.y) - Offset(other.x, other.y)).distance,
            greaterThanOrEqualTo(64),
            reason: '${node.id} overlaps ${other.id}',
          );
        }
      }
    },
  );
  test(
    'discovery exposes only the root and purchased immediate successors',
    () {
      final tree = SkillTree(testCatalog());
      expect(tree.visible({}).map((n) => n.id), ['hand:1']);
      expect(
        tree.visible({'hand': 1}).map((n) => n.id),
        containsAll(['hand:2', 'generator:1']),
      );
      final first = tree.visible({'hand': 1}).map((n) => n.id);
      expect(
        first,
        containsAll(['generator:1', 'reward:1', 'sweep:1', 'hand:2']),
      );
      expect(first, isNot(contains('broom:1')));
      expect(first, isNot(contains('collection:1')));
      expect(first, isNot(contains('duration:1')));
      expect(tree.visible({'hand': 2}).map((n) => n.id), contains('broom:1'));
      expect(
        tree.visible({'generator': 2}).map((n) => n.id),
        contains('duration:1'),
      );
    },
  );

  test(
    'all levels are reachable without cycles and legacy purchases remain visible',
    () {
      final catalog = testCatalog();
      final tree = SkillTree(catalog);
      final levels = <String, int>{};
      var previous = -1;
      while (previous != levels.values.fold(0, (a, b) => a + b)) {
        previous = levels.values.fold(0, (a, b) => a + b);
        for (final node in tree.visible(levels)) {
          if (tree.unlocked(node, levels) && !node.owned(levels)) {
            levels[node.definition.id] = node.level;
          }
        }
      }
      expect(tree.nodes.every((n) => n.owned(levels)), isTrue);
      expect(
        tree.nodes.length,
        catalog.definitions.fold<int>(0, (a, b) => a + b.levels.length),
      );
      final legacy = {'paddle': 2, 'broom': 1, 'magnet': 1, 'collection': 1};
      final visible = tree.visible(legacy);
      expect(
        visible.map((n) => n.id),
        containsAll([
          'paddle:1',
          'paddle:2',
          'broom:1',
          'magnet:1',
          'collection:1',
          'hand:1',
        ]),
      );
      expect(legacy.containsKey('generator'), isFalse);
    },
  );

  Future<GameSession> open(
    WidgetTester tester, {
    int balance = 500,
    bool inspect = true,
  }) async {
    final session = GameSession(testCatalog(), MemoryStore())
      ..economy.balance = balance;
    await tester.pumpWidget(GardenApp(session: session));
    await tester.scrollUntilVisible(find.text('Ir al árbol de mejoras'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ir al árbol de mejoras'));
    await tester.pumpAndSettle();
    expect(find.byType(SkillTreeScreen), findsOneWidget);
    if (inspect) {
      await tester.tap(find.byKey(const ValueKey('node-hand:1')));
      await tester.pumpAndSettle();
    }
    return session;
  }

  Future<void> close(WidgetTester tester, GameSession session) async {
    await tester.pumpWidget(const SizedBox());
    await session.pendingWrites;
    session.dispose();
  }

  testWidgets('tap inspects; a full one-second hold buys once and persists', (
    tester,
  ) async {
    final session = await open(tester);
    final root = find.byKey(const ValueKey('node-hand:1'));
    await tester.tap(root);
    await tester.pump();
    expect(session.levels, isEmpty);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('hold-purchase'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(session.levels, isEmpty);
    await tester.pump(const Duration(milliseconds: 101));
    expect(session.levels['hand'], 1);
    expect(session.economy.balance, 480);
    expect(find.byKey(const ValueKey('node-hand:2')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-generator:3')), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    expect(session.economy.balance, 480);
    await gesture.up();
    await session.pendingWrites;
    final restored = GameSession(testCatalog(), MemoryStore())
      ..restore(session.snapshot());
    expect(restored.levels['hand'], 1);
    expect(restored.economy.balance, 480);
    restored.dispose();
    await close(tester, session);
  });

  testWidgets(
    'early release, dragging, pinch and backgrounding cancel purchase',
    (tester) async {
      final session = await open(tester);
      var center = tester.getCenter(
        find.byKey(const ValueKey('hold-purchase')),
      );
      var gesture = await tester.startGesture(center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.up();
      await tester.pump(const Duration(seconds: 2));
      expect(session.levels, isEmpty);
      gesture = await tester.startGesture(center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump(const Duration(seconds: 4));
      await gesture.up();
      expect(session.levels, isEmpty);
      center = tester.getCenter(find.byKey(const ValueKey('node-hand:1')));
      gesture = await tester.startGesture(center);
      await tester.pump();
      final second = await tester.startGesture(
        center + const Offset(70, 0),
        pointer: 2,
      );
      final viewer = tester.widget<InteractiveViewer>(
        find.byKey(const ValueKey('skill-tree-viewer')),
      );
      final scale = viewer.transformationController!.value.getMaxScaleOnAxis();
      await gesture.moveBy(const Offset(-35, 0));
      await second.moveBy(const Offset(35, 0));
      await tester.pump(const Duration(seconds: 4));
      expect(
        viewer.transformationController!.value.getMaxScaleOnAxis(),
        greaterThan(scale),
      );
      await second.up();
      await gesture.up();
      expect(session.levels, isEmpty);
      gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('hold-purchase'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 4));
      await gesture.up();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(session.levels, isEmpty);
      expect(session.economy.balance, 500);
      // A platform interruption may drop the original pointer-up event.
      gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('hold-purchase'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      await gesture.up();
      expect(session.levels['hand'], 1);
      await close(tester, session);
    },
  );

  testWidgets(
    'detail purchase cancels with a second finger and then buys on a fresh hold',
    (tester) async {
      final session = await open(tester);
      final center = tester.getCenter(
        find.byKey(const ValueKey('hold-purchase')),
      );
      var gesture = await tester.startGesture(center);
      await tester.pump();
      final second = await tester.startGesture(
        center + const Offset(30, 0),
        pointer: 2,
      );
      await tester.pump(const Duration(seconds: 4));
      expect(session.levels, isEmpty);
      await second.up();
      await gesture.up();
      gesture = await tester.startGesture(center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      await gesture.up();
      expect(session.levels['hand'], 1);
      expect(session.economy.balance, 480);
      await close(tester, session);
    },
  );

  testWidgets('unaffordable node can be inspected but cannot be purchased', (
    tester,
  ) async {
    final session = await open(tester, balance: 0);
    expect(find.text('Faltan \$20'), findsOneWidget);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('hold-purchase'))),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await gesture.up();
    expect(session.levels, isEmpty);
    expect(session.economy.balance, 0);
    expect(tester.takeException(), isNull);
    await close(tester, session);
  });

  testWidgets(
    'compact tree fits mobile and keeps gesture zoom without controls',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final session = await open(tester, inspect: false);
      expect(find.text('Árbol de mejoras'), findsNothing);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      expect(find.byKey(const ValueKey('upgrade-summary')), findsNothing);
      expect(find.byKey(const ValueKey('hold-purchase')), findsNothing);
      expect(find.text('\$500'), findsOneWidget);
      final viewerFinder = find.byKey(const ValueKey('skill-tree-viewer'));
      final viewer = tester.widget<InteractiveViewer>(viewerFinder);
      final before = viewer.transformationController!.value.getMaxScaleOnAxis();
      final center = tester.getCenter(viewerFinder);
      final first = await tester.startGesture(center - const Offset(50, 0));
      final second = await tester.startGesture(
        center + const Offset(50, 0),
        pointer: 2,
      );
      await first.moveBy(const Offset(-25, 0));
      await second.moveBy(const Offset(25, 0));
      await tester.pump();
      expect(
        viewer.transformationController!.value.getMaxScaleOnAxis(),
        greaterThan(before),
      );
      await first.up();
      await second.up();
      await tester.tap(find.byKey(const ValueKey('node-hand:1')));
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(
        find.byKey(const ValueKey('upgrade-summary')),
      );
      expect(text.textSpan!.toPlainText(), 'La mano agarra 2 bolas.');
      final spans = (text.textSpan! as TextSpan).children!;
      expect(spans[1].toPlainText(), '2');
      expect(spans[1].style!.color, const Color(0xff22c55e));
      expect(find.byKey(const ValueKey('tree-start-day')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await close(tester, session);
    },
  );

  testWidgets('holding a map node inspects without buying', (tester) async {
    final session = await open(tester, inspect: false);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('node-hand:1'))),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(session.levels, isEmpty);
    expect(find.byKey(const ValueKey('upgrade-summary')), findsOneWidget);
    await close(tester, session);
  });
}
