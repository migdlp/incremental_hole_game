import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/special_abilities.dart';
import 'package:incremental_hole_game/features/board/presentation/special_ability_bar.dart';
import 'package:incremental_hole_game/features/day_cycle/domain/day_cycle.dart';
import '../test_support.dart';

void advance(GameSession session, double seconds) {
  for (var i = 0; i < (seconds * 60).round(); i++) {
    session.tick(1 / 60);
  }
}

void capture(GameSession session) {
  final board = session.board!;
  board.balls.add(Ball(board.nextId++, Board.hole, Vec.zero));
  session.tick(1 / 60);
}

void main() {
  final catalog = testCatalog();
  GameSession withAbilities() => GameSession(catalog, MemoryStore())
    ..levels.addAll({
      'hand': 1,
      'combo': 1,
      'generator': 1,
      'capture_all': 1,
      'boost': 1,
    })
    ..startDay();

  test(
    'streak must be purchased; owned streak and money survive reopening',
    () async {
      final session = GameSession(catalog, MemoryStore())..startDay();
      for (var i = 0; i < 10; i++) {
        capture(session);
      }
      expect(session.board!.combo.enabled, isFalse);
      expect(session.economy.generated, 10);
      session.finishDay();
      await session.pendingWrites;
      final combo = catalog.definitions.firstWhere((d) => d.id == 'combo');
      session.economy.balance = 1000;
      expect(session.purchase(combo), isFalse);
      expect(
        session.purchase(catalog.definitions.firstWhere((d) => d.id == 'hand')),
        isTrue,
      );
      expect(session.purchase(combo), isTrue);
      expect(session.economy.balance, 947);
      session.startDay();
      for (var i = 0; i < 5; i++) {
        capture(session);
      }
      final reopened = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      expect(reopened.board!.combo.enabled, isTrue);
      expect(reopened.board!.combo.streak, 5);
      expect(reopened.economy.generated, 6);
      expect(reopened.economy.balance, 947);
    },
  );

  test(
    'an active v6 balance-7 day keeps its free streak only until day end',
    () {
      final original = GameSession(catalog, MemoryStore())..startDay();
      original.board = Board(catalog.settings({}, balanceVersion: 7));
      for (var i = 0; i < 5; i++) {
        capture(original);
      }
      original.board!.releaseCoin(original.economy.generated);
      final old = jsonDecode(original.snapshot()) as Map<String, dynamic>;
      old['version'] = 6;
      final session = GameSession(catalog, MemoryStore())
        ..restore(jsonEncode(old));
      expect(session.economy.generated, 6);
      expect(session.board!.combo.enabled, isTrue);
      session.finishDay();
      session.startDay();
      expect(session.board!.settings.balanceVersion, 17);
      expect(session.board!.combo.enabled, isFalse);
      expect(session.levels, isEmpty);
    },
  );

  test('charges require production time and pause/reload never grant time', () {
    final session = withAbilities();
    expect(session.activateSpecial(SpecialAbility.boost), isFalse);
    advance(session, 5);
    final state = session.board!.specials;
    expect(state.boostCharge, closeTo(5, 1e-8));
    session.pause();
    advance(session, 5);
    expect(state.boostCharge, closeTo(5, 1e-8));
    final reopened = GameSession(catalog, MemoryStore())
      ..restore(session.snapshot());
    expect(reopened.paused, isTrue);
    expect(reopened.board!.specials.boostCharge, state.boostCharge);
    expect(reopened.activateSpecial(SpecialAbility.boost), isFalse);
    reopened.resume();
    advance(reopened, 5);
    expect(reopened.board!.specials.ready(SpecialAbility.boost), isTrue);
    expect(reopened.board!.specials.ready(SpecialAbility.captureAll), isFalse);
    expect(reopened.activateSpecial(SpecialAbility.boost), isTrue);
    expect(reopened.activateSpecial(SpecialAbility.boost), isFalse);
    advance(reopened, 1);
    expect(reopened.board!.specials.boostCharge, 0);
    final active = GameSession(catalog, MemoryStore())
      ..restore(reopened.snapshot());
    expect(active.board!.specials.boostRemaining, closeTo(3, 1e-8));
    active.resume();
    advance(active, 4);
    expect(active.phase, DayPhase.night);
    final frozen = active.snapshot();
    advance(active, 1);
    expect(active.snapshot(), frozen);
    expect(active.activateSpecial(SpecialAbility.captureAll), isFalse);
    active.finishDay();
    active.startDay();
    expect(active.board!.specials.captureCharge, 0);
    expect(active.board!.specials.boostRemaining, 0);
  });

  test(
    'boost changes cadence by x2/x3, respects cap and duration upgrades',
    () {
      for (final power in [0, 1]) {
        final settings = catalog.settings({
          'boost': 1,
          'boost_power': power,
          'boost_duration': 2,
          'boost_recharge': 2,
        });
        final board = Board(settings);
        board.specials.advance(6);
        expect(board.activateSpecial(SpecialAbility.boost), isTrue);
        for (var i = 0; i < 360; i++) {
          board.update(1 / 60, producing: true);
          board.balls.clear(); // Isolate cadence from blocked spawn positions.
        }
        expect(board.spawned, power == 0 ? 18 : 27);
        expect(board.specials.boostRemaining, closeTo(0, 1e-8));
        expect(board.specials.boostCharge, closeTo(0, 1e-8));
        for (var i = 0; i < 200; i++) {
          board.balls.add(
            Ball(
              board.nextId++,
              Vec(10 + i % 20 * 16, 200 + i ~/ 20 * 16),
              Vec.zero,
            ),
          );
        }
        board.update(1 / 60, producing: true);
        expect(board.balls.length, 200);
      }
    },
  );

  test(
    'capture total persists once, releases held balls and still requires coins',
    () {
      final session = withAbilities();
      advance(session, 12);
      final board = session.board!;
      board.balls.clear();
      board.spawnClock = 0;
      for (var i = 0; i < 10; i++) {
        board.balls.add(
          Ball(board.nextId++, Vec(35 + i * 28, 200), Vec.zero, golden: i == 9),
        );
      }
      session.touch(board.balls.first.position);
      expect(board.heldBall, isNotNull);
      expect(session.activateSpecial(SpecialAbility.captureAll), isTrue);
      expect(session.economy.generated, 0);
      expect(session.activateSpecial(SpecialAbility.captureAll), isFalse);
      final reopened = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      reopened.resume();
      reopened.tick(1 / 60);
      expect(reopened.board!.balls, isEmpty);
      expect(reopened.board!.captured, 10);
      expect(reopened.economy.generated, 44);
      expect(reopened.rewards.outstanding, 44);
      expect(reopened.economy.collected, 0);
      final twice = GameSession(catalog, MemoryStore())
        ..restore(reopened.snapshot());
      twice.resume();
      twice.tick(1 / 60);
      expect(twice.board!.captured, 10);
      expect(twice.economy.generated, 44);
      for (final coin in List.of(twice.board!.coins)) {
        coin.landing = 0;
        twice.touch(coin.position);
        twice.release();
      }
      expect(twice.economy.collected, 44);
      twice.finishDay();
      twice.finishDay();
      expect(twice.economy.balance, 44);
      // The un-restored path must also release an actual active hand grip.
      session.tick(1 / 60);
      expect(board.heldBalls, isEmpty);
    },
  );

  test(
    'empty capture keeps charge, cooldown upgrades apply and debug stays isolated',
    () async {
      final store = MemoryStore();
      final session = GameSession(catalog, store);
      final baseline = session.snapshot();
      session.enterDebug();
      await session.pendingWrites;
      final writes = store.writes.length;
      expect(session.debugPurchase('capture_recharge', 2), isTrue);
      expect(session.debugPurchase('boost_power', 1), isTrue);
      expect(session.debugPurchase('boost_recharge', 2), isTrue);
      session.startDay();
      advance(session, 8);
      final board = session.board!;
      board.balls.clear();
      expect(board.specials.ready(SpecialAbility.captureAll), isTrue);
      expect(session.activateSpecial(SpecialAbility.captureAll), isFalse);
      expect(board.specials.captureCharge, closeTo(8, 1e-8));
      expect(session.activateSpecial(SpecialAbility.boost), isTrue);
      expect(board.specials.generationMultiplier, 3);
      await session.save();
      expect(store.writes.length, writes);
      session.exitDebug();
      expect(session.snapshot(), baseline);
    },
  );

  test('invalid ability state rejects restore atomically', () {
    final session = withAbilities();
    advance(session, 2);
    final pristine = session.snapshot();
    for (final change in <void Function(Map<String, dynamic>)>[
      (b) => b['specials']['captureCharge'] = -1,
      (b) => b['specials']['boostCharge'] = 11,
      (b) => b['specials']['boostRemaining'] = 5,
      (b) => b['specials']['boostRemaining'] = 1,
      (b) => b['captureAllIds'] = [999999],
      (b) => b.remove('specials'),
    ]) {
      final data = jsonDecode(pristine) as Map<String, dynamic>;
      change(data['run']['board'] as Map<String, dynamic>);
      expect(() => session.restore(jsonEncode(data)), throwsFormatException);
      expect(session.snapshot(), pristine);
    }
  });

  testWidgets('special buttons show charge, activate and fit a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final session = withAbilities();
    await tester.pumpWidget(GardenApp(session: session));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(SpecialAbilityBar), findsOneWidget);
    expect(find.byKey(const ValueKey('special-captureAll')), findsOneWidget);
    advance(session, 10);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('special-boost')));
    await tester.pump();
    expect(session.board!.specials.boostRemaining, greaterThan(0));
    expect(find.textContaining('×2 ·'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Pausar'));
    await tester.pump();
    expect(session.paused, isTrue);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    expect(session.paused, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await session.pendingWrites;
    session.dispose();
  });
}
