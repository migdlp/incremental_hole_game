import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/gravity_event.dart';
import 'package:incremental_hole_game/features/board/presentation/garden_game.dart';
import 'package:incremental_hole_game/features/motion/motion_input.dart';
import '../test_support.dart';

class TestMotion implements MotionInput {
  @override
  bool available = true;
  @override
  Vec tilt = const Vec(.7, 0);
  bool active = false, disposed = false;
  @override
  void setActive(bool value) {
    active = value;
  }

  @override
  void dispose() {
    active = false;
    disposed = true;
  }
}

void main() {
  final catalog = testCatalog();
  Board board({
    int seed = 42,
    bool force = true,
    bool available = true,
    Map<String, int> levels = const {},
  }) => Board(
    catalog.settings(levels),
    gravitySupported: available,
    gravitySeed: seed,
    forceGravity: force,
  );
  void activate(Board b) {
    expect(b.gravity.hasObject, isTrue);
    while (b.gravity.hasObject) {
      expect(b.gravity.hit(available: b.gravitySupported), isTrue);
    }
  }

  void advance(Board b, double seconds, {bool producing = true}) {
    for (var i = 0; i < (seconds * 240).round(); i++) {
      b.update(1 / 240, producing: producing);
    }
  }

  Ball ball(Board b, Vec p, {Vec v = Vec.zero, bool golden = false}) {
    final item = Ball(b.nextId++, p, v, golden: golden);
    b.balls.add(item);
    return item;
  }

  GameSession session(
    TestMotion motion, {
    bool force = true,
    MemoryStore? store,
  }) {
    final s = GameSession(
      catalog,
      store ?? MemoryStore(),
      motion: motion,
      eventSeed: 42,
    );
    if (force) {
      s.enterDebug();
      s.debugSetForceGravity(true);
    }
    s.startDay();
    return s;
  }

  void tick(GameSession s, double seconds) {
    for (var i = 0; i < (seconds * 60).round(); i++) {
      s.tick(1 / 60);
    }
  }

  void tap(GameSession s) {
    final p = s.board!.gravity.position;
    s.touch(p);
    s.release();
  }

  test(
    'configurable five percent roll is independent and available from the first day',
    () {
      expect(catalog.base['gravity_probability'], .05);
      var appeared = 0;
      final random = math.Random(12);
      for (var i = 0; i < 10000; i++) {
        final event = GravityEvent(
          catalog.settings({}),
          seed: random.nextInt(0x100000000),
          available: true,
        );
        if (event.stage == GravityStage.waiting) appeared++;
      }
      expect(appeared, inInclusiveRange(430, 570));
      final settings = catalog.settings({})..values['gravity_probability'] = 1;
      final event = GravityEvent(settings, seed: 5, available: true);
      expect(event.stage, GravityStage.waiting);
      expect(event.spawnAt, inInclusiveRange(0, 15));
      settings.values['gravity_probability'] = 0;
      expect(
        GravityEvent(settings, seed: 5, available: true).stage,
        GravityStage.none,
      );
      final live = GameSession(
        catalog,
        MemoryStore(),
        motion: TestMotion(),
        eventSeed: 0,
      );
      final data = jsonDecode(live.snapshot()) as Map<String, dynamic>;
      // Find a deterministic first-day seed with a successful natural roll.
      for (var seed = 0; seed < 1000; seed++) {
        final next = (1664525 * seed + 1013904223) & 0xffffffff;
        if (GravityEvent(
              catalog.settings({}),
              seed: next,
              available: true,
            ).stage ==
            GravityStage.waiting) {
          data['eventRandom'] = seed;
          break;
        }
      }
      live.restore(jsonEncode(data));
      live.startDay();
      expect(live.progress.day, 1);
      expect(live.board!.gravity.stage, GravityStage.waiting);
      live.dispose();
    },
  );

  test(
    'unsupported devices never generate objects even with forced random success',
    () {
      final b = board(available: false);
      advance(b, 15);
      expect(b.gravity.hasObject, isFalse);
      expect(b.gravity.active, isFalse);
      expect(b.gravity.hit(available: false), isFalse);
      final settings = catalog.settings({})..values['gravity_probability'] = 1;
      final event = GravityEvent(
        settings,
        seed: 1,
        available: false,
        force: true,
      );
      expect(event.stage, GravityStage.none);
    },
  );

  test('one slowly drifting object per production phase with no rerolls', () {
    final b = board();
    final event = b.gravity;
    final before = event.position;
    advance(b, .5);
    expect((event.position - before).length, closeTo(4, .02));
    expect(event.hasObject, isTrue);
    activate(b);
    advance(b, 10.5);
    expect(event.stage, GravityStage.spent);
    expect(event.hit(available: true), isFalse);
    advance(b, 2);
    expect(event.stage, GravityStage.spent);
    b.enterClosing();
    expect(event.hasObject, isFalse);
    expect(event.remaining, 0);
  });

  test(
    '3 to 6 distinct taps damage and activate once; drag or cancellation does not',
    () {
      final resistances = <int>{};
      for (var seed = 0; seed < 100; seed++) {
        final b = board(seed: (seed * 2654435761) & 0xffffffff);
        final count = b.gravity.hitsRequired;
        resistances.add(count);
        final p = b.gravity.position;
        b.touch(p);
        b.drag(p + const Vec(30, 0));
        b.releasePointer();
        expect(b.gravity.hits, 0);
        b.touch(p);
        b.releasePointer(cancel: true);
        expect(b.gravity.hits, 0);
        for (var i = 0; i < count; i++) {
          b.touch(p);
          expect(b.heldBall, isNull);
          b.releasePointer();
          expect(b.gravity.hits, i + 1);
          expect(b.gravity.damageFlash, greaterThan(0));
          expect(b.gravity.active, i == count - 1);
        }
        expect(b.gravity.announcement, 1);
        expect(b.gravity.remaining, 10);
        expect(b.gravity.hit(available: true), isFalse);
        expect(b.gravity.hits, count);
      }
      expect(resistances, {3, 4, 5, 6});
    },
  );

  test(
    'gravity starts gradually and moves free normal and golden balls in each direction',
    () {
      for (final direction in [
        const Vec(.7, 0),
        const Vec(-.7, 0),
        const Vec(0, .7),
        const Vec(0, -.7),
      ]) {
        for (final golden in [false, true]) {
          final b = board()..gravityTilt = direction;
          final item = ball(b, const Vec(180, 290), golden: golden);
          activate(b);
          expect(item.velocity.length, 0);
          b.update(1 / 240, producing: true);
          expect(item.velocity.length, inInclusiveRange(0.001, 1));
          advance(b, .8);
          final delta = item.position - const Vec(180, 290);
          expect(delta.x * direction.x + delta.y * direction.y, greaterThan(8));
          expect(item.golden, golden);
          expect(item.velocity.length, lessThanOrEqualTo(380));
        }
      }
    },
  );

  test(
    'held balls and tools stay under manual control; release restores gravity',
    () {
      final b = board(levels: {'hand': 2, 'broom': 1, 'bat': 1})
        ..gravityTilt = const Vec(.8, 0);
      final item = ball(b, const Vec(160, 300));
      activate(b);
      b.touch(item.position);
      advance(b, .7);
      expect((item.position - const Vec(160, 300)).length, lessThan(.001));
      b.releasePointer(cancel: true);
      advance(b, .5);
      expect(item.position.x, greaterThan(164));
      for (final bat in [true, false]) {
        if (bat) {
          b.batPosition = const Vec(180, 350);
        } else {
          b.broomPosition = const Vec(180, 180);
        }
        b.touch(bat ? b.batPosition : b.broomPosition);
        expect(bat ? b.holdingBat : b.holdingBroom, isTrue);
        final before = bat ? b.batPosition : b.broomPosition;
        advance(b, .4);
        expect(
          ((bat ? b.batPosition : b.broomPosition) - before).length,
          lessThan(.001),
        );
        b.releasePointer(cancel: true);
        advance(b, .4);
        expect(
          (bat ? b.batPosition : b.broomPosition).x,
          greaterThan(before.x + 2),
        );
      }
    },
  );

  test(
    'free broom and bat accelerate, collide with boundaries and do not collect coins',
    () {
      final b = board(levels: {'hand': 2, 'broom': 1, 'bat': 1})
        ..gravityTilt = const Vec(1, 0);
      b.broomPosition = const Vec(180, 180);
      b.batPosition = const Vec(180, 350);
      final coin = Coin(b.nextId++, const Vec(180, 250), 10, landing: 0);
      b.coins.add(coin);
      activate(b);
      advance(b, 1);
      expect(b.broomPosition.x, greaterThan(200));
      expect(b.batPosition.x, greaterThan(200));
      expect(coin.position.x, 180);
      expect(coin.position.y, 250);
      expect(b.coins, contains(coin));
      advance(b, 8);
      expect(
        b.broomPosition.x,
        lessThanOrEqualTo(360 - b.broomHalfWidth - Board.broomThickness),
      );
      expect(b.batHandles.every((p) => p.x <= 354), isTrue);
      expect(b.broomGravityVelocity.length, lessThanOrEqualTo(380));
      expect(b.batGravityVelocity.length, lessThanOrEqualTo(380));
    },
  );

  test(
    'expiration preserves inertia and never extends the maximum ten seconds',
    () {
      final b = board()..gravityTilt = const Vec(.7, 0);
      activate(b);
      advance(b, 9.9);
      expect(b.gravity.remaining, closeTo(.1, 1e-6));
      final item = ball(b, const Vec(100, 300), v: const Vec(100, 0));
      advance(b, .1);
      expect(b.gravity.remaining, 0);
      expect(b.gravity.active, isFalse);
      expect(item.velocity.length, greaterThan(0));
      expect(b.gravity.announcement, 0);
      final after = item.velocity.length;
      b.update(1 / 240, producing: true);
      expect(item.velocity.length, lessThan(after));
    },
  );

  test(
    'late activation ends at production boundary; closing is frozen and clears visuals',
    () {
      final b = board(levels: {'hand': 2, 'broom': 1, 'bat': 1})
        ..gravityTilt = const Vec(.7, 0);
      advance(b, 14);
      activate(b);
      expect(b.gravity.remaining, closeTo(1, 1e-6));
      final item = ball(b, const Vec(160, 300));
      advance(b, 1);
      b.enterClosing();
      final p = item.position, broom = b.broomPosition, bat = b.batPosition;
      advance(b, 4, producing: false);
      expect(item.position, p);
      expect(b.broomPosition, broom);
      expect(b.batPosition, bat);
      expect(b.gravity.remaining, 0);
      expect(b.gravity.announcement, 0);
      expect(b.gravityObjectVisible, isFalse);
    },
  );

  test(
    'sensor loss suppresses appearance and force without inventing a second event',
    () {
      final b = board()..gravityTilt = const Vec(.7, 0);
      b.gravitySupported = false;
      expect(b.gravityObjectVisible, isFalse);
      expect(b.gravity.hit(available: false), isFalse);
      b.gravitySupported = true;
      activate(b);
      advance(b, .5);
      final item = ball(b, const Vec(100, 350));
      b.gravitySupported = false;
      advance(b, .5);
      expect(item.velocity.length, 0);
      expect(b.gravity.remaining, closeTo(9, 1e-6));
      b.gravitySupported = true;
      advance(b, .5);
      expect(item.velocity.x, greaterThan(0));
      expect(b.gravity.hits, b.gravity.hitsRequired);
    },
  );

  test(
    'random event scheduling never changes ball generation or golden selection',
    () {
      final a = board(force: false, available: false), b = board();
      for (var i = 0; i < 240; i++) {
        a.update(1 / 240, producing: true);
        b.update(1 / 240, producing: true);
      }
      expect(a.randomState, b.randomState);
      expect(a.balls.map((b) => b.toJson()), b.balls.map((b) => b.toJson()));
    },
  );

  test(
    'pause and background freeze time and suspend live sensor subscription',
    () async {
      final motion = TestMotion();
      final s = session(motion);
      final b = s.board!;
      activate(b);
      tick(s, 1);
      final left = b.gravity.remaining, p = b.gravity.position;
      s.pause();
      expect(motion.active, isFalse);
      tick(s, 2);
      expect(b.gravity.remaining, left);
      expect(b.gravity.position, p);
      s.resume();
      expect(motion.active, isTrue);
      tick(s, .5);
      expect(b.gravity.remaining, closeTo(left - .5, 1e-6));
      s.setBackgrounded(true);
      final frozen = b.gravity.remaining;
      s.resume();
      tick(s, 2);
      expect(b.gravity.remaining, frozen);
      expect(motion.active, isFalse);
      s.setBackgrounded(false);
      expect(s.paused, isTrue);
      s.resume();
      tick(s, .5);
      expect(b.gravity.remaining, closeTo(frozen - .5, 1e-6));
      await s.pendingWrites;
      s.dispose();
      expect(motion.disposed, isTrue);
    },
  );

  test(
    'waiting, damaged and active states restore without reroll, new hits or announcement reset',
    () async {
      final motion = TestMotion();
      final s = GameSession(
        catalog,
        MemoryStore(),
        motion: motion,
        eventSeed: 9,
      );
      s.startDay();
      final b = s.board!;
      b.gravity = GravityEvent(
        b.settings,
        seed: 9,
        available: true,
        force: true,
      );
      tap(s);
      final r = GameSession(catalog, MemoryStore(), motion: TestMotion())
        ..restore(s.snapshot());
      expect(r.paused, isTrue);
      expect(r.board!.gravity.hits, 1);
      expect(r.board!.gravity.position.x, b.gravity.position.x);
      r.resume();
      while (r.board!.gravity.hasObject) {
        tap(r);
      }
      tick(r, .4);
      final remaining = r.board!.gravity.remaining,
          banner = r.board!.gravity.announcement;
      final active = GameSession(catalog, MemoryStore(), motion: TestMotion())
        ..restore(r.snapshot());
      expect(active.board!.gravity.remaining, remaining);
      expect(active.board!.gravity.announcement, banner);
      active.resume();
      tick(active, .5);
      expect(active.board!.gravity.remaining, closeTo(remaining - .5, 1e-6));
      expect(active.board!.gravity.hits, active.board!.gravity.hitsRequired);
      final saved = jsonDecode(s.snapshot()) as Map<String, dynamic>;
      // Pick a naturally scheduled event and save before it appears.
      for (var seed = 0; seed < 10000; seed++) {
        final candidate = GravityEvent(b.settings, seed: seed, available: true);
        if (candidate.stage == GravityStage.waiting && candidate.spawnAt > 1) {
          saved['run']['board']['gravity'] = candidate.toJson();
          break;
        }
      }
      final waiting = GameSession(catalog, MemoryStore(), motion: TestMotion())
        ..restore(jsonEncode(saved));
      expect(waiting.board!.gravity.stage, GravityStage.waiting);
      final when = waiting.board!.gravity.spawnAt;
      waiting.resume();
      tick(waiting, 1);
      expect(waiting.board!.gravity.stage, GravityStage.waiting);
      expect(waiting.board!.gravity.spawnAt, when);
      for (final item in [s, r, active, waiting]) {
        await item.pendingWrites;
        item.dispose();
      }
    },
  );

  test(
    'free tool velocities persist and new days discard the previous event state',
    () async {
      final s = session(TestMotion());
      s.levels.addAll({'hand': 2, 'broom': 1, 'bat': 1});
      // Start another test day with the newly bought tool settings.
      s.finishDay();
      s.debugSetForceGravity(true);
      s.startDay();
      activate(s.board!);
      tick(s, .8);
      final snap = s.snapshot();
      final before = s.board!;
      final restored = GameSession(catalog, MemoryStore(), motion: TestMotion())
        ..restore(snap);
      expect(restored.board!.batGravityVelocity.x, before.batGravityVelocity.x);
      expect(
        restored.board!.broomGravityVelocity.x,
        before.broomGravityVelocity.x,
      );
      restored.resume();
      restored.finishDay();
      restored.startDay();
      expect(restored.board!.gravity.hits, 0);
      expect(restored.board!.gravity.active, isFalse);
      expect(restored.board!.gravity.announcement, 0);
      await s.pendingWrites;
      await restored.pendingWrites;
      s.dispose();
      restored.dispose();
    },
  );

  test(
    'legacy v10 keeps settings and has no event until the next day',
    () async {
      final s = GameSession(catalog, MemoryStore())..startDay();
      final data = jsonDecode(s.snapshot()) as Map<String, dynamic>;
      data['version'] = 7;
      data.remove('feeding');
      data['run']['balanceVersion'] = 10;
      data['run']['settings'] = catalog
          .settings({}, balanceVersion: 10)
          .toJson();
      for (final key in [
        'gravity',
        'broomGravityVelocity',
        'batGravityVelocity',
      ]) {
        data['run']['board'].remove(key);
      }
      data.remove('eventRandom');
      final restored = GameSession(catalog, MemoryStore(), motion: TestMotion())
        ..restore(jsonEncode(data));
      expect(restored.board!.settings.balanceVersion, 10);
      expect(restored.board!.gravity.stage, GravityStage.none);
      restored.resume();
      tick(restored, .5);
      expect(restored.board!.gravity.hasObject, isFalse);
      restored.finishDay();
      restored.startDay();
      expect(restored.board!.settings.balanceVersion, 20);
      await s.pendingWrites;
      await restored.pendingWrites;
      s.dispose();
      restored.dispose();
    },
  );

  test(
    'invalid event counters, timers, pose and random state reject restore atomically',
    () {
      final s = session(TestMotion());
      final original = s.snapshot();
      for (final change in <void Function(Map<String, dynamic>)>[
        (j) => j['run']['board']['gravity']['stage'] = 'again',
        (j) => j['run']['board']['gravity']['hitsRequired'] = 2,
        (j) => j['run']['board']['gravity']['hits'] = 8,
        (j) => j['run']['board']['gravity']['remaining'] = 11,
        (j) => j['run']['board']['gravity']['position'] = [-10, 200],
        (j) => j['run']['board']['gravity']['elapsed'] = 2,
        (j) => j['eventRandom'] = -1,
      ]) {
        final data = jsonDecode(original) as Map<String, dynamic>;
        change(data);
        expect(() => s.restore(jsonEncode(data)), throwsFormatException);
        expect(s.snapshot(), original);
      }
      s.dispose();
    },
  );

  test(
    'debug forced/simulated motion remains isolated and cannot bypass normal hardware rules',
    () async {
      final store = MemoryStore();
      final s = GameSession(catalog, store, eventSeed: 3);
      s.debugSetGravityTilt('right');
      s.debugSetForceGravity(true);
      expect(s.gravityAvailable, isFalse);
      s.enterDebug();
      await s.pendingWrites;
      final baseline = store.writes.last;
      s.debugSetForceGravity(true);
      expect(s.debugForceGravity, isFalse);
      s.debugSetGravityTilt('right');
      s.debugSetForceGravity(true);
      s.startDay();
      expect(s.board!.gravityObjectVisible, isTrue);
      expect(s.debugForceGravity, isFalse);
      final b = s.board!;
      while (b.gravity.hasObject) {
        tap(s);
      }
      final item = ball(b, const Vec(100, 300));
      tick(s, 1);
      expect(item.position.x, greaterThan(105));
      await s.pendingWrites;
      expect(store.writes.last, baseline);
      s.exitDebug();
      expect(s.snapshot(), baseline);
      expect(s.debugGravityTilt, 'sensor');
      expect(s.gravityAvailable, isFalse);
      s.dispose();
    },
  );

  test('multiple balls under gravity preserve bounds and speed caps', () {
    final b = board(levels: {'hand': 2, 'broom': 1, 'bat': 3, 'walls': 3})
      ..gravityTilt = const Vec(.8, -.6);
    for (var i = 0; i < 200; i++) {
      ball(
        b,
        Vec(10 + i % 20 * 17, 140 + i ~/ 20 * 30),
        v: Vec(i.isEven ? 380 : -380, 0),
        golden: i % 4 == 0,
      );
    }
    activate(b);
    for (var i = 0; i < 300; i++) {
      b.update(1 / 60, producing: true);
      for (final item in b.balls) {
        expect(item.velocity.length, lessThanOrEqualTo(380 + 1e-6));
        expect(item.position.x, inInclusiveRange(6, 354));
        expect(item.position.y, inInclusiveRange(6, 554));
      }
      expect(b.balls.length, lessThanOrEqualTo(200));
    }
  });

  test(
    'activation flash and damage render without persistent direction indicators',
    () async {
      final s = session(TestMotion());
      final b = s.board!;
      final game = GardenGame(s)..onGameResize(Vector2(360, 560));
      Future<List<int>> pixels() async {
        final recorder = ui.PictureRecorder();
        game.render(ui.Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(360, 560);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final result = List<int>.of(bytes.buffer.asUint8List());
        image.dispose();
        picture.dispose();
        return result;
      }

      final intact = await pixels();
      tap(s);
      expect(await pixels(), isNot(orderedEquals(intact)));
      while (b.gravity.hasObject) {
        tap(s);
      }
      expect(b.gravity.announcement, 1);
      final flash = await pixels();
      tick(s, 1.1);
      expect(b.gravity.announcement, 0);
      expect(await pixels(), isNot(orderedEquals(flash)));
      await s.pendingWrites;
      s.dispose();
    },
  );

  test(
    'object taps never collect overlapped coins and gravity does not multiply rewards',
    () {
      final b = board(
        levels: {'hand': 1, 'sweep': 1, 'collection': 3, 'magnet': 1},
      );
      final p = b.gravity.position;
      final coin = Coin(b.nextId++, p, 10, landing: 0);
      b.coins.add(coin);
      b.touch(p);
      b.update(1 / 60, producing: true);
      b.releasePointer();
      expect(b.coins, contains(coin));
      expect(coin.position.x, p.x);
      expect(coin.position.y, p.y);
      activate(b);
      ball(b, Board.hole);
      ball(b, Board.hole, golden: true);
      final rewards = b.update(1 / 60, producing: true);
      expect(rewards.captured, 2);
      expect(rewards.goldenCaptured, 1);
      expect(rewards.rewards, [1, 10]);
      expect(rewards.collected, 0);
    },
  );

  testWidgets(
    'real object taps ignore a simultaneous second finger and activate once',
    (tester) async {
      final s = session(TestMotion());
      s.board!.gravity.position = const Vec(180, 280);
      await tester.pumpWidget(GardenApp(session: s));
      await tester.pump(const Duration(milliseconds: 50));
      final finder = find.byWidgetPredicate((w) => w is GameWidget);
      final game = tester.widget<GameWidget>(finder).game as GardenGame;
      Offset point() =>
          tester.getTopLeft(finder) +
          game.origin +
          Offset(s.board!.gravity.position.x, s.board!.gravity.position.y) *
              game.scale;
      final b = s.board!;
      while (b.gravity.hits < b.gravity.hitsRequired - 1) {
        await tester.tapAt(point());
        await tester.pump();
      }
      final first = await tester.startGesture(point(), pointer: 1);
      final second = await tester.startGesture(point(), pointer: 2);
      await first.up();
      await second.up();
      await tester.pump();
      expect(b.gravity.active, isTrue);
      expect(b.gravity.hits, b.gravity.hitsRequired);
      final remaining = b.gravity.remaining;
      await tester.tapAt(point());
      await tester.pump();
      expect(b.gravity.remaining, lessThanOrEqualTo(remaining));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await s.pendingWrites;
      s.dispose();
    },
  );

  testWidgets(
    'debug menu can force a simulated event without sensors on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final s = GameSession(catalog, MemoryStore());
      prepareNormalShop(s);
      await tester.pumpWidget(GardenApp(session: s));
      await tester.scrollUntilVisible(find.text('Tienda'), 150);
      await tester.tap(find.text('Tienda'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tree-debug-tools')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('debug-gravity-tools')),
      );
      await tester.tap(find.text('Gravedad'));
      await tester.pumpAndSettle();
      final dropdown = find.byKey(const ValueKey('debug-gravity-tilt'));
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simular: derecha').last);
      await tester.pumpAndSettle();
      final toggle = find.byKey(const ValueKey('debug-force-gravity'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(s.debugForceGravity, isTrue);
      expect(s.gravityAvailable, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await s.pendingWrites;
      s.dispose();
    },
  );
}
