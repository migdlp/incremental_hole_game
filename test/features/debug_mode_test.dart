import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/features/board/domain/tool.dart';
import 'package:incremental_hole_game/features/upgrades/domain/skill_tree.dart';
import 'package:incremental_hole_game/features/upgrades/presentation/skill_tree_screen.dart';
import '../test_support.dart';

void main() {
  final catalog = testCatalog();

  test(
    'debug actions are gated and arbitrary purchases add valid prerequisites',
    () {
      final session = GameSession(catalog, MemoryStore());
      expect(session.debugPurchase('robot_speed', 5), isFalse);
      expect(session.debugBuyAll(), isFalse);
      session.debugAddCoins();
      expect(session.economy.balance, 0);
      expect(session.debugEnabled, isFalse);
      expect(session.debugFullTree, isFalse);
      expect(session.enterDebug(), isTrue);
      expect(session.debugFullTree, isTrue);
      expect(session.debugPurchase('missing', 1), isFalse);
      expect(session.debugPurchase('hand', 6), isFalse);
      expect(session.debugPurchase('hand', 0), isFalse);
      expect(session.debugPurchase('robot_speed', 5), isTrue);
      expect(session.levels, containsPair('robot_speed', 5));
      expect(session.levels, containsPair('robot', 1));
      expect(session.levels, containsPair('paddle', 2));
      expect(session.levels, containsPair('broom', 1));
      expect(session.levels, containsPair('sweep', 1));
      expect(session.levels, containsPair('hand', 2));
      expect(session.economy.balance, 0);
      expect(session.debugPurchase('robot_speed', 5), isFalse);
      catalog.validateLevels(session.levels);
      session.exitDebug();
      expect(session.levels, isEmpty);
    },
  );

  test(
    'all upgrades are playable without overwriting real progress or saves',
    () async {
      final store = MemoryStore();
      final session = GameSession(catalog, store)..economy.balance = 100;
      session.purchase(catalog.definitions.firstWhere((d) => d.id == 'hand'));
      final baseline = session.snapshot();
      session.enterDebug();
      await session.pendingWrites;
      final writes = store.writes.length;
      session.debugAddCoins();
      expect(session.debugBuyAll(), isTrue);
      expect(
        SkillTree(catalog).nodes.every((n) => n.owned(session.levels)),
        isTrue,
      );
      catalog.validateLevels(session.levels);
      expect(session.selectedTool, BallTool.vee);
      session.startDay();
      expect(session.board!.handCapacity, 6);
      expect(session.board!.settings['robot_count'], 1);
      expect(session.board!.settings['ball_value'], 13);
      expect(session.debugBuyAll(), isFalse);
      expect(session.debugPurchase('hand', 5), isFalse);
      session.debugReset();
      expect(session.running, isTrue);
      session.pause();
      await session.save();
      expect(store.writes.length, writes);
      expect(store.candidates.first, baseline);
      // Leaving during a test day restores the original night and purchases.
      session.exitDebug();
      expect(session.running, isFalse);
      expect(session.debugEnabled, isFalse);
      expect(session.snapshot(), baseline);
      final reloaded = GameSession(catalog, store);
      await reloaded.load();
      expect(reloaded.snapshot(), baseline);
      expect(reloaded.debugEnabled, isFalse);
      // Ordinary saving works again after exiting.
      session.economy.balance++;
      await session.save();
      expect(store.writes.length, writes + 1);
      session.dispose();
      reloaded.dispose();
    },
  );

  test(
    'player preview uses test purchases; resetting returns to the initial tree',
    () {
      final session = GameSession(catalog, MemoryStore())..enterDebug();
      final tree = SkillTree(catalog);
      session.debugBuyAll();
      session.setDebugFullTree(false);
      expect(session.debugEnabled, isTrue);
      expect(session.debugFullTree, isFalse);
      expect(tree.visible(session.levels).length, 49);
      session.debugReset();
      expect(tree.visible(session.levels).map((n) => n.id), ['hand:1']);
      expect(session.economy.balance, 0);
      expect(session.progress.day, 1);
      session.debugAddCoins();
      expect(session.economy.balance, 1000);
      session.purchase(catalog.definitions.firstWhere((d) => d.id == 'hand'));
      expect(session.economy.balance, 987);
      expect(tree.visible(session.levels).length, 7);
      session.setDebugFullTree(true);
      expect(session.levels, {'hand': 1});
      session.exitDebug();
      expect(session.levels, isEmpty);
      expect(session.economy.balance, 0);
    },
  );

  test('normal running day cannot enter debug or enable free purchases', () {
    final session = GameSession(catalog, MemoryStore())..startDay();
    final before = session.snapshot();
    expect(session.enterDebug(), isFalse);
    session.debugAddCoins();
    session.debugReset();
    session.setDebugFullTree(true);
    expect(session.debugBuyAll(), isFalse);
    expect(session.debugEnabled, isFalse);
    expect(session.snapshot(), before);
  });

  Future<GameSession> open(WidgetTester tester) async {
    final session = GameSession(catalog, MemoryStore());
    await tester.pumpWidget(GardenApp(session: session));
    await tester.scrollUntilVisible(find.text('Ir al árbol de mejoras'), 200);
    await tester.tap(find.text('Ir al árbol de mejoras'));
    await tester.pumpAndSettle();
    return session;
  }

  Future<void> activate(WidgetTester tester) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('tree-debug-entry'))),
    );
    await tester.pump(const Duration(milliseconds: 3100));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester, GameSession session) async {
    await tester.pumpWidget(const SizedBox());
    await session.pendingWrites;
    session.dispose();
  }

  testWidgets('hidden access needs a long hold and exposes the complete tree', (
    tester,
  ) async {
    final session = await open(tester);
    expect(find.text('DEBUG'), findsNothing);
    expect(find.byKey(const ValueKey('node-robot_speed:5')), findsNothing);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('tree-debug-entry'))),
    );
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(session.debugEnabled, isFalse);
    await activate(tester);
    expect(session.debugEnabled, isTrue);
    expect(find.text('Depuración'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('debug-close-tools')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('node-robot_speed:5')), findsOneWidget);
    final tree = SkillTree(catalog);
    expect(tree.nodes, hasLength(49));
    for (final node in tree.nodes) {
      final position = find.byKey(ValueKey('position-${node.id}'));
      expect(position, findsOneWidget, reason: 'Falta el nodo ${node.id}');
    }
    final viewer = tester.widget<InteractiveViewer>(
      find.byKey(const ValueKey('skill-tree-viewer')),
    );
    final scale = viewer.transformationController!.value.getMaxScaleOnAxis();
    expect(scale, lessThan(.85));
    final viewport = tester.getRect(
      find.byKey(const ValueKey('skill-tree-viewer')),
    );
    for (final node in tree.nodes) {
      final center = tester.getCenter(
        find.byKey(ValueKey('position-${node.id}')),
      );
      expect(
        viewport.contains(center),
        isTrue,
        reason: 'El nodo ${node.id} queda fuera del mapa visible',
      );
    }
    // A deep node can be bought directly, including all its prerequisites.
    await tester.tap(find.byKey(const ValueKey('node-robot_speed:5')));
    await tester.pumpAndSettle();
    expect(find.text('Comprar gratis · 1 s'), findsOneWidget);
    final hold = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('hold-purchase'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    await hold.up();
    await tester.pumpAndSettle();
    expect(session.levels['robot_speed'], 5);
    expect(session.economy.balance, 0);
    await close(tester, session);
  });

  testWidgets(
    'debug controls alternate real discovery, reset, buy all and exit',
    (tester) async {
      final session = await open(tester);
      final baseline = session.snapshot();
      await activate(tester);
      await tester.tap(find.byKey(const ValueKey('debug-player-view')));
      await tester.pumpAndSettle();
      expect(session.debugFullTree, isFalse);
      await tester.tap(find.byKey(const ValueKey('debug-close-tools')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('node-hand:1')), findsOneWidget);
      expect(find.byKey(const ValueKey('node-hand:2')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('node-hand:1')));
      await tester.pumpAndSettle();
      expect(find.text('No disponible'), findsOneWidget);
      expect(find.text('Gratis · DEBUG'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('tree-debug-tools')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('debug-buy-all')));
      await tester.pumpAndSettle();
      expect(
        SkillTree(catalog).nodes.every((n) => n.owned(session.levels)),
        isTrue,
      );
      await tester.tap(find.byKey(const ValueKey('debug-reset')));
      await tester.tap(find.byKey(const ValueKey('debug-add-coins')));
      await tester.pumpAndSettle();
      expect(session.levels, isEmpty);
      expect(session.economy.balance, 1000);
      await tester.tap(find.byKey(const ValueKey('debug-exit')));
      await tester.pumpAndSettle();
      expect(session.snapshot(), baseline);
      expect(find.text('DEBUG'), findsNothing);
      expect(find.byKey(const ValueKey('node-hand:2')), findsNothing);
      await close(tester, session);
    },
  );

  testWidgets(
    'changing view cancels a pending free purchase and hides its details',
    (tester) async {
      final session = await open(tester);
      session.enterDebug();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('node-robot_speed:5')));
      await tester.pumpAndSettle();
      final hold = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('hold-purchase'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      session.setDebugFullTree(false);
      await tester.pumpAndSettle();
      await hold.up();
      expect(session.levels, isEmpty);
      expect(find.byKey(const ValueKey('upgrade-summary')), findsNothing);
      expect(find.byKey(const ValueKey('node-robot_speed:5')), findsNothing);
      await close(tester, session);
    },
  );

  testWidgets('test day has an exit that restores the normal game', (
    tester,
  ) async {
    final session = await open(tester);
    final baseline = session.snapshot();
    session.enterDebug();
    session.debugBuyAll();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tree-start-day')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(session.running, isTrue);
    expect(find.text('DEBUG · prueba temporal'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('session-debug-exit')));
    await tester.pumpAndSettle();
    expect(session.running, isFalse);
    expect(session.snapshot(), baseline);
    expect(find.byType(SkillTreeScreen), findsNothing);
    await close(tester, session);
  });

  testWidgets('debug tools fit a small phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final session = await open(tester);
    await activate(tester);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('debug-exit')));
    await tester.tap(find.byKey(const ValueKey('debug-exit')));
    await tester.pumpAndSettle();
    expect(session.debugEnabled, isFalse);
    expect(tester.takeException(), isNull);
    await close(tester, session);
  });
}
