import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:incremental_hole_game/persistence/store_web.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/features/prestige/domain/meta_progress.dart';
import 'package:incremental_hole_game/features/upgrades/domain/skill_tree.dart';
import 'package:incremental_hole_game/persistence/store_native.dart';
import '../test_support.dart';

class FaultStore extends MemoryStore {
  bool failMain = false, failMeta = false;
  @override
  Future<void> save(String contents, {String? previous}) async {
    if (failMain) throw const FileSystemException('normal save failed');
    await super.save(contents, previous: previous);
  }

  @override
  Future<void> savePrestige(String contents) async {
    if (failMeta) throw const FileSystemException('prestige save failed');
    await super.savePrestige(contents);
  }
}

class BlockedMetaStore extends MemoryStore {
  final gate = Completer<void>();
  @override
  Future<void> savePrestige(String contents) async {
    await gate.future;
    await super.savePrestige(contents);
  }
}

void main() {
  final catalog = testCatalog();
  GameSession session({MemoryStore? store}) =>
      GameSession(catalog, store ?? MemoryStore(), eventSeed: 42);
  Future<void> lose(GameSession s) async {
    // A terminal state created by the historical S03 rules remains loadable.
    // Current gameplay has no quota defeat trigger.
    final blank = jsonDecode(session().snapshot()) as Map<String, dynamic>;
    blank['meta'] = s.meta.end(voluntary: false).toJson();
    s.restore(jsonEncode(blank));
    await s.save();
    await s.pendingWrites;
  }

  void seedPermanent(GameSession s) {
    final j = jsonDecode(s.snapshot()) as Map<String, dynamic>;
    j['meta']['stars'] = 37;
    j['meta']['upgrades'] = {'future-p02-record': 2};
    j['meta']['discoveries'] = ['future-secret'];
    j['meta']['pendingStarObjects'] = [
      {
        'uninterpreted-p01': {'value': 7, 'damage': 2},
      },
    ];
    j['meta']['extensions'] = {
      'future': {'persistent': true},
    };
    s.restore(jsonEncode(j));
  }

  test(
    'empty days defeat at the fourth close and preserve only permanent progress',
    () async {
      final s = session();
      seedPermanent(s);
      s.economy.balance = 900;
      s.levels['hand'] = 1;
      for (var i = 0; i < 3; i++) {
        s.startDay();
        s.finishDay();
      }
      expect(s.canPlayRun, isTrue);
      expect(s.progress.day, 3);
      s.startDay();
      s.finishDay();
      await s.pendingWrites;
      expect(s.meta.phase, PrestigePhase.defeat);
      expect(s.meta.stars, 37);
      expect(s.meta.upgrades, {'future-p02-record': 2});
      expect(s.economy.balance, 0);
      expect(s.levels, isEmpty);
      expect(s.meta.firstDefeatSeen, isTrue);
      expect(s.feeding.target, BigInt.from(25));
      s.dispose();
    },
  );
  test(
    'defeat to shop to new run is idempotent and preserves permanent state every time',
    () async {
      final s = session();
      seedPermanent(s);
      await lose(s);
      final ended = s.meta.revision;
      s.finishDay();
      expect(s.meta.revision, ended);
      expect(s.beginNewRun(), isFalse);
      expect(s.continueToPrestigeShop(), isTrue);
      expect(s.continueToPrestigeShop(), isFalse);
      await s.pendingWrites;
      expect(s.meta.phase, PrestigePhase.shop);
      expect(s.beginNewRun(), isTrue);
      expect(s.beginNewRun(), isFalse);
      await s.pendingWrites;
      expect(s.meta.runId, 2);
      expect(s.meta.stars, 37);
      expect(s.meta.upgrades.length, 1);
      expect(s.meta.pendingStarObjects, isEmpty);
      expect(s.progress.day, 1);
      expect(s.feeding.points, BigInt.zero);
      s.startDay();
      expect(s.board!.balls, isEmpty);
      expect(s.board!.segments, isEmpty);
      expect(s.board!.launcher.unlocked, isFalse);
      s.finishDay();
      await s.pendingWrites;
      s.dispose();
    },
  );
  test('shop cannot be opened during production or between ordinary days', () {
    final s = session();
    expect(s.continueToPrestigeShop(), isFalse);
    expect(s.beginNewRun(), isFalse);
    s.startDay();
    expect(s.continueToPrestigeShop(), isFalse);
    expect(s.beginNewRun(), isFalse);
    s.dispose();
  });
  test(
    'voluntary node is visible immediately, advanced, configurable and requires confirmation',
    () async {
      final tree = SkillTree(catalog), s = session();
      // Fixture after the mandatory opening jornada (P02).
      prepareNormalShop(s);
      expect(tree.visible({}).any((n) => n.id == 'prestige:1'), isTrue);
      final node = tree.byId('prestige:1');
      expect(node.parents.toSet(), {'generator:5', 'reward:5', 'duration:5'});
      expect(node.upgrade.cost, 10000);
      expect(s.purchase(node.definition, confirmPrestige: true), isFalse);
      s.enterDebug();
      s.debugBuyAll();
      final levels = Map<String, int>.of(s.levels);
      s.exitDebug();
      s.levels.addAll(levels);
      s.economy.balance = 10000;
      final before = s.snapshot();
      expect(s.purchase(node.definition), isFalse);
      expect(s.snapshot(), before);
      expect(s.purchase(node.definition, confirmPrestige: true), isTrue);
      expect(s.meta.phase, PrestigePhase.shop);
      expect(s.meta.firstDefeatSeen, isFalse);
      expect(s.meta.stars, 0);
      expect(s.levels, isEmpty);
      expect(s.purchase(node.definition, confirmPrestige: true), isFalse);
      await s.pendingWrites;
      s.dispose();
    },
  );
  test(
    'new run starts with voluntary prestige unbought and does not retain normal tools or money',
    () async {
      final s = session()..enterDebug();
      s.debugBuyAll();
      expect(s.debugPurchase('prestige', 1), isFalse);
      expect(s.debugPurchase('prestige', 1, confirmPrestige: true), isTrue);
      expect(s.beginNewRun(), isTrue);
      expect(s.levels.containsKey('prestige'), isFalse);
      expect(s.levels, isEmpty);
      expect(s.selectedTool.name, 'hand');
      s.exitDebug();
      await s.pendingWrites;
      s.dispose();
    },
  );
  test(
    'DEBUG death and voluntary prestige never reach normal progress or checkpoint',
    () async {
      final store = MemoryStore();
      final s = session(store: store);
      s.economy.balance = 123;
      final baseline = s.snapshot();
      s.enterDebug();
      await s.pendingWrites;
      await lose(s);
      expect(s.meta.phase, PrestigePhase.defeat);
      expect(s.continueToPrestigeShop(), isTrue);
      expect(s.beginNewRun(), isTrue);
      s.exitDebug();
      expect(s.snapshot(), baseline);
      expect(store.prestigeCandidates, isEmpty);
      s.dispose();
    },
  );
  test(
    'restoring an old same-run or legacy snapshot cannot revive an ended run',
    () async {
      final s = session();
      final old = s.snapshot();
      final legacy = jsonDecode(old)..['version'] = 9;
      await lose(s);
      final after = s.snapshot();
      expect(() => s.restore(old), throwsFormatException);
      expect(() => s.restore(jsonEncode(legacy)), throwsFormatException);
      expect(s.snapshot(), after);
      s.continueToPrestigeShop();
      await s.pendingWrites;
      final shop = s.snapshot();
      s.beginNewRun();
      await s.pendingWrites;
      expect(() => s.restore(shop), throwsFormatException);
      expect(s.meta.runId, 2);
      s.dispose();
    },
  );
  test(
    'fresh process recovers terminal checkpoint instead of an old normal backup',
    () async {
      final store = MemoryStore(), s = session();
      final old = s.snapshot();
      final real = session(store: store);
      await lose(real);
      store.candidates = [old, old];
      final loaded = session(store: store);
      await loaded.load();
      expect(loaded.meta.phase, PrestigePhase.defeat);
      expect(loaded.running, isFalse);
      expect(loaded.recoveryMessage, isNotNull);
      expect(() => loaded.restore(old), throwsFormatException);
      real.dispose();
      loaded.dispose();
      s.dispose();
    },
  );
  test(
    'new-run checkpoint protects stars and epoch even if both normal saves are old',
    () async {
      final store = MemoryStore();
      final s = session(store: store);
      seedPermanent(s);
      final old = s.snapshot();
      final real = session(store: store);
      seedPermanent(real);
      await lose(real);
      real.continueToPrestigeShop();
      await real.pendingWrites;
      real.beginNewRun();
      await real.pendingWrites;
      store.candidates = [old, old];
      final loaded = session(store: store);
      await loaded.load();
      expect(loaded.meta.runId, 2);
      expect(loaded.meta.phase, PrestigePhase.playing);
      expect(loaded.meta.stars, 37);
      expect(() => loaded.restore(old), throwsFormatException);
      real.dispose();
      loaded.dispose();
      s.dispose();
    },
  );
  test(
    'checkpoint failure blocks continuing and retry commits exactly one ending',
    () async {
      final store = FaultStore()..failMeta = true;
      final s = session(store: store);
      await lose(s);
      expect(s.saveError, isNotNull);
      expect(s.prestigeReady, isFalse);
      expect(s.continueToPrestigeShop(), isFalse);
      final revision = s.meta.revision;
      store.failMeta = false;
      await s.save();
      expect(s.meta.revision, revision);
      expect(s.prestigeReady, isTrue);
      expect(s.continueToPrestigeShop(), isTrue);
      await s.pendingWrites;
      s.dispose();
    },
  );
  test(
    'normal save failure after durable ending still recovers from the prestige checkpoint',
    () async {
      final store = FaultStore();
      final s = session(store: store);
      s.startDay();
      await s.pendingWrites;
      s.finishDay();
      await s.pendingWrites;
      store.failMain = true;
      await lose(s);
      await s.pendingWrites;
      expect(s.saveError, isNotNull);
      expect(store.prestigeCandidates, isNotEmpty);
      final loaded = session(store: store);
      await loaded.load();
      expect(loaded.meta.phase, PrestigePhase.defeat);
      expect(loaded.progress.last, isNull);
      s.dispose();
      loaded.dispose();
    },
  );
  test(
    'corrupt prestige copies fail closed even when an old ordinary game is valid',
    () async {
      final store = MemoryStore();
      final old = session().snapshot();
      store.candidates = [old];
      store.prestigeCandidates = ['broken', '{}'];
      final s = session(store: store);
      await expectLater(s.load(), throwsFormatException);
      expect(s.progress.day, 1);
      s.dispose();
    },
  );
  test(
    'native checkpoint has two current copies and survives a corrupt ordinary file',
    () async {
      final dir = await Directory.systemTemp.createTemp('prestige-save-');
      addTearDown(() => dir.delete(recursive: true));
      final store = FileSaveStore(dir.path),
          s = GameSession(catalog, FileSaveStore(dir.path));
      await lose(s);
      final copies = await store.loadPrestigeCandidates();
      expect(copies.length, 2);
      expect(copies.first, copies.last);
      await File('${dir.path}/progress.json').writeAsString('broken');
      await File('${dir.path}/progress.backup.json').writeAsString('old');
      final loaded = GameSession(catalog, store);
      await loaded.load();
      expect(loaded.meta.phase, PrestigePhase.defeat);
      s.dispose();
      loaded.dispose();
    },
  );
  test(
    'legacy quota previews are migrated without retroactive defeat or fake stars',
    () async {
      final s = session();
      final data = jsonDecode(s.snapshot());
      data['version'] = 9;
      data.remove('meta');
      data['day'] = 6;
      data['balance'] = 456;
      data['feeding'] = {
        'startDay': 1,
        'period': 1,
        'completedDays': 5,
        'normal': 0,
        'instant': 0,
        'runNormal': 0,
        'runInstant': 0,
        'target': 10,
        'quotaStep': 10,
      };
      s.restore(jsonEncode(data));
      expect(s.canPlayRun, isTrue);
      expect(s.economy.balance, 456);
      expect(s.meta.stars, 0);
      s.startDay();
      expect(s.feeding.period, 1);
      s.finishDay();
      await s.pendingWrites;
      s.dispose();
    },
  );
  test(
    'invalid permanent data rejects before changing normal or permanent progress',
    () {
      final s = session();
      final before = s.snapshot();
      for (final change in <void Function(dynamic)>[
        (j) => j['meta']['stars'] = -1,
        (j) => j['meta']['runId'] = 0,
        (j) => j['meta']['phase'] = 'unknown',
        (j) => j['meta']['upgrades'] = {'x': -1},
        (j) => j['meta']['pendingStarObjects'] = 'discard',
        (j) => j['meta']['lastEndedRun'] = 5,
        (j) => j['meta']['discoveries'] = ['x', 'x'],
        (j) => j['meta'] = null,
      ]) {
        final j = jsonDecode(before);
        change(j);
        expect(() => s.restore(jsonEncode(j)), throwsFormatException);
        expect(s.snapshot(), before);
      }
      s.dispose();
    },
  );
  testWidgets('defeat is simple and continues into a star shop then day one', (
    tester,
  ) async {
    final s = session();
    seedPermanent(s);
    await lose(s);
    await tester.pumpWidget(GardenApp(session: s));
    await tester.pump();
    expect(find.text('DERROTA'), findsOneWidget);
    expect(find.byKey(const ValueKey('visual-day-results')), findsNothing);
    expect(find.text('Bolas al hoyo'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('prestige-continue')));
    await s.pendingWrites;
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('prestige-shop')), findsOneWidget);
    expect(find.text('37'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('prestige-new-run')));
    await tester.tap(find.byKey(const ValueKey('prestige-new-run')));
    await s.pendingWrites;
    await tester.pump(const Duration(milliseconds: 100));
    expect(s.running, isTrue);
    expect(find.text('Tienda'), findsNothing);
    expect(s.progress.day, 1);
    expect(s.meta.stars, 37);
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  });
  testWidgets(
    'buttons remain disabled until irreversible checkpoint completes',
    (tester) async {
      final store = BlockedMetaStore();
      // Use the same blocked store that the session owns.
      final real = session(store: store);
      final blank = jsonDecode(session().snapshot()) as Map<String, dynamic>;
      blank['meta'] = real.meta.end(voluntary: false).toJson();
      real.restore(jsonEncode(blank));
      real.save();
      await tester.pumpWidget(GardenApp(session: real));
      await tester.pump();
      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('prestige-continue')),
      );
      expect(button.onPressed, isNull);
      expect(find.text('Guardando…'), findsOneWidget);
      store.gate.complete();
      await real.pendingWrites;
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('prestige-continue')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
      real.dispose();
    },
  );
  for (final debug in [false, true]) {
    testWidgets(
      'voluntary diamond confirms, cancels and closes the tree (DEBUG=$debug)',
      (tester) async {
        final s = session();
        // Fixture after the mandatory opening jornada (P02).
        prepareNormalShop(s);
        if (debug) {
          s.enterDebug();
        } else {
          for (final definition in catalog.definitions.where(
            (d) => d.id != 'prestige',
          )) {
            s.levels[definition.id] = definition.levels.length;
          }
          s.economy.balance = 10000;
        }
        s.sound = false;
        await tester.pumpWidget(GardenApp(session: s));
        await tester.pump();
        await tester.tap(find.text('Tienda'));
        await tester.pumpAndSettle();
        final viewer = tester.widget<InteractiveViewer>(
          find.byKey(const ValueKey('skill-tree-viewer')),
        );
        viewer.transformationController!.value = Matrix4.diagonal3Values(
          .5,
          .5,
          1,
        );
        await tester.pumpAndSettle();
        final node = find.byKey(const ValueKey('node-prestige:1'));
        final diamond = tester.widget<Transform>(
          find.byKey(const ValueKey('prestige-diamond')),
        );
        expect(diamond.transform.storage[0], closeTo(.70710678, .00001));
        expect(diamond.transform.storage[1], closeTo(.70710678, .00001));
        expect(tester.getSize(node).width, 80);
        await tester.tap(node);
        await tester.pumpAndSettle();
        final before = s.snapshot();
        Future<void> holdBuy() async {
          final gesture = await tester.startGesture(
            tester.getCenter(find.byKey(const ValueKey('hold-purchase'))),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1100));
          await gesture.up();
          await tester.pumpAndSettle();
        }

        await holdBuy();
        expect(find.text('¿Reiniciar la partida?'), findsOneWidget);
        expect(
          find.textContaining('Conservas tus estrellas cobradas'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Las burbujas sin romper se pierden.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(s.snapshot(), before);
        await holdBuy();
        await tester.tap(find.byKey(const ValueKey('prestige-confirm')));
        await s.pendingWrites;
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('prestige-shop')), findsOneWidget);
        expect(find.byKey(const ValueKey('skill-tree-viewer')), findsNothing);
        expect(s.meta.phase, PrestigePhase.shop);
        expect(s.meta.stars, 0);
        if (debug) s.exitDebug();
        await tester.pumpWidget(const SizedBox());
        await s.pendingWrites;
        s.dispose();
      },
    );
  }
  testWidgets('DEBUG can disable quota trials without triggering defeat', (
    tester,
  ) async {
    final store = MemoryStore();
    final s = session(store: store)..enterDebug();
    s.debugConfigureFeeding(quotas: false);
    await s.pendingWrites;
    await tester.pumpWidget(GardenApp(session: s));
    await tester.pump();
    await tester.tap(find.text('Tienda'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tree-debug-tools')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      s.debugSimulateEmptyDay();
    }
    await tester.pumpAndSettle();
    expect(find.text('DERROTA'), findsNothing);
    expect(find.byKey(const ValueKey('skill-tree-viewer')), findsOneWidget);
    expect(store.prestigeCandidates, isEmpty);
    await tester.ensureVisible(find.byKey(const ValueKey('debug-exit')));
    await tester.tap(find.byKey(const ValueKey('debug-exit')));
    await tester.pumpAndSettle();
    expect(s.canPlayRun, isTrue);
    expect(s.meta.revision, 0);
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  });
  test(
    'shop checkpoint restores between defeat and new run with all permanent data',
    () async {
      final store = MemoryStore();
      final s = session(store: store);
      seedPermanent(s);
      await lose(s);
      s.continueToPrestigeShop();
      await s.pendingWrites;
      final restored = session(store: store);
      await restored.load();
      expect(restored.meta.phase, PrestigePhase.shop);
      expect(restored.meta.stars, 37);
      expect(restored.meta.pendingStarObjects, s.meta.pendingStarObjects);
      expect(restored.continueToPrestigeShop(), isFalse);
      expect(restored.beginNewRun(), isTrue);
      await restored.pendingWrites;
      expect(restored.meta.runId, 2);
      expect(restored.progress.day, 1);
      s.dispose();
      restored.dispose();
    },
  );
  test(
    'web checkpoint uses two current copies and restores a terminated run over old data',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = WebSaveStore(prefs);
      final s = GameSession(catalog, store);
      final old = s.snapshot();
      await lose(s);
      final copies = await store.loadPrestigeCandidates();
      expect(copies.length, 2);
      expect(copies.first, copies.last);
      await prefs.setString('progress', old);
      await prefs.setString('progress.backup', old);
      final restored = GameSession(catalog, store);
      await restored.load();
      expect(restored.meta.phase, PrestigePhase.defeat);
      expect(() => restored.restore(old), throwsFormatException);
      s.dispose();
      restored.dispose();
    },
  );
}
