import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/black_hole_event.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/presentation/black_hole_feedback.dart';
import 'package:incremental_hole_game/features/board/presentation/garden_game.dart';
import 'package:incremental_hole_game/features/upgrades/domain/catalog.dart';
import '../test_support.dart';

void main() {
  final catalog = testCatalog();
  BlackHoleEvent event({int seed = 42, double chance = 0, int forced = 0}) {
    final settings = catalog.settings({})
      ..values['black_hole_probability'] = chance;
    return BlackHoleEvent(settings, seed: seed, forcedObjects: forced);
  }

  Board board({bool active = true, Map<String, int> levels = const {}}) {
    final settings = catalog.settings(levels)
      ..values['black_hole_probability'] = 0;
    final b = Board(settings, forcedBlackHoles: active ? 1 : 0);
    if (active) activate(b.blackHole, b.blackHole.objects.single);
    return b;
  }

  void tick(GameSession s, double seconds) {
    for (var i = 0; i < (seconds * 60).round(); i++) {
      s.tick(1 / 60);
    }
  }

  Ball ball(
    Board b,
    Vec position, {
    Vec velocity = Vec.zero,
    bool golden = false,
  }) {
    final item = Ball(b.nextId++, position, velocity, golden: golden);
    b.balls.add(item);
    return item;
  }

  test('periodic independent five percent checks start after the interval', () {
    expect(catalog.base['black_hole_probability'], .05);
    final e = event(chance: 1);
    expect(e.interval, 3);
    e.advance(2.999, producing: true);
    expect(e.checks, 0);
    e.advance(.001, producing: true);
    expect(e.checks, 1);
    expect(e.objects, hasLength(1));
    e.advance(12, producing: true);
    expect(e.checks, 4); // No appearance on the production/closing boundary.
    expect(e.objects, isEmpty);
    expect(e.ended, isTrue);
    final never = event(chance: 0)..advance(15, producing: true);
    expect(never.checks, 4);
    expect(never.objects, isEmpty);
    var appeared = 0;
    final random = math.Random(30);
    for (var i = 0; i < 10000; i++) {
      final e = BlackHoleEvent(
        catalog.settings({}),
        seed: random.nextInt(0x100000000),
      )..advance(3, producing: true);
      appeared += e.objects.length;
    }
    expect(appeared, inInclusiveRange(430, 570));
  });

  test(
    'coarse and fine frames preserve checks, RNG and drifting positions',
    () {
      final coarse = event(chance: 1), fine = event(chance: 1);
      coarse.advance(12.5, producing: true);
      for (var i = 0; i < 3000; i++) {
        fine.advance(1 / 240, producing: true);
      }
      expect(fine.checks, coarse.checks);
      expect(fine.randomState, coarse.randomState);
      for (var i = 0; i < coarse.objects.length; i++) {
        expect(
          (fine.objects[i].position - coarse.objects[i].position).length,
          lessThan(1e-7),
        );
        expect(fine.objects[i].hitsRequired, coarse.objects[i].hitsRequired);
      }
    },
  );

  test(
    'several objects coexist with independent damage and three to six taps',
    () {
      final resistance = <int>{};
      for (var seed = 0; seed < 100; seed++) {
        final e = event(
          seed: math.Random(seed).nextInt(0x100000000),
          forced: 3,
        );
        final first = e.objects.first, second = e.objects[1];
        resistance.add(first.hitsRequired);
        for (var tap = 1; tap < first.hitsRequired; tap++) {
          expect(e.hit(first.id), isTrue);
          expect(first.hits, tap);
          expect(first.damageFlash, greaterThan(0));
          expect(e.active, isFalse);
          expect(second.hits, 0);
        }
        expect(e.hit(first.id), isTrue);
        expect(e.objects, hasLength(2));
        expect(e.activations, 1);
        expect(e.hit(first.id), isFalse);
        expect(e.remaining, 10);
      }
      expect(resistance, {3, 4, 5, 6});
    },
  );

  test(
    'another activation resets ten seconds without stacking reach or power',
    () {
      final e = event(forced: 3);
      final radius = e.reach, force = e.accelerationAt(60);
      activate(e, e.objects.first);
      e.advance(4, producing: true);
      expect(e.remaining, 6);
      activate(e, e.objects.first);
      expect(e.remaining, 10);
      expect(e.reach, radius);
      expect(e.accelerationAt(60), force);
      expect(e.activations, 2);
      e.advance(9, producing: true);
      expect(e.remaining, 1);
      activate(e, e.objects.first); // Only two production seconds remain.
      expect(e.remaining, 10);
      e.advance(2, producing: true);
      expect(e.active, isFalse);
      expect(e.remaining, 0);
    },
  );

  test(
    'expanded suction is stronger near the centre and preserves capture size',
    () {
      double speedAt(double distance) {
        final b = board();
        final item = ball(b, Board.hole + Vec(0, distance));
        b.update(1 / 240, producing: true);
        expect(b.settings['hole_capture_radius'], 22);
        expect(b.balls, contains(item));
        return item.velocity.length;
      }

      expect(speedAt(60), greaterThan(speedAt(120)));
      expect(speedAt(120), greaterThan(0));
      expect(speedAt(190), 0);
      final inactive = board(active: false);
      final item = ball(inactive, Board.hole + const Vec(0, 100));
      inactive.update(1 / 60, producing: true);
      expect(item.velocity.length, 0);
      final active = board();
      ball(active, Board.hole + const Vec(30, 0));
      active.update(1 / 240, producing: true);
      expect(active.balls, hasLength(1)); // Within attraction, outside capture.
    },
  );

  test(
    'normal and golden balls keep inertia, speed cap and normal capture rewards',
    () {
      for (final golden in [false, true]) {
        final b = board();
        final item = ball(
          b,
          const Vec(230, 100),
          velocity: const Vec(900, 0),
          golden: golden,
        );
        b.update(1 / 240, producing: true);
        expect(item.velocity.x, greaterThan(0));
        expect(item.velocity.y, lessThan(0));
        expect(item.velocity.length, lessThanOrEqualTo(380));
        item.position = Board.hole;
        item.velocity = Vec.zero;
        final events = b.update(1 / 240, producing: true);
        expect(events.captured, 1);
        expect(events.rewards, [golden ? 10 : 1]);
      }
    },
  );

  test(
    'coins and both free tools are unaffected; grabbed balls remain controlled',
    () {
      final b = board(levels: {'hand': 1, 'broom': 1, 'bat': 1});
      final broom = b.broomPosition, bat = b.batPosition;
      final coin = Coin(b.nextId++, const Vec(200, 90), 1, landing: 0);
      b.coins.add(coin);
      final held = ball(b, const Vec(180, 150));
      b.touch(held.position);
      final original = held.position;
      b.update(.2, producing: true);
      expect((held.position - original).length, 0);
      expect(held.velocity.length, 0);
      expect((coin.position - const Vec(200, 90)).length, 0);
      expect((b.broomPosition - broom).length, 0);
      expect((b.batPosition - bat).length, 0);
      b.releasePointer(cancel: true);
      b.update(.1, producing: true);
      expect(held.velocity.y, lessThan(0));
    },
  );

  test(
    'tap release damages once; drag, cancel, second finger and coins cannot duplicate it',
    () {
      final b = board(active: false);
      final object = b.blackHole.forceSpawn(position: const Vec(130, 250))!;
      final coin = Coin(b.nextId++, object.position, 10, landing: 0);
      b.coins.add(coin);
      b.touch(object.position);
      b.touch(object.position);
      expect(object.hits, 0);
      expect(b.canCollectCoins, isFalse);
      b.releasePointer();
      expect(object.hits, 1);
      expect(b.coins, contains(coin));
      b.releasePointer();
      expect(object.hits, 1);
      b.touch(object.position);
      b.drag(object.position + const Vec(30, 0));
      b.releasePointer();
      b.touch(object.position);
      b.releasePointer(cancel: true);
      expect(object.hits, 1);
      while (b.blackHole.objects.isNotEmpty) {
        b.touch(object.position);
        b.releasePointer();
      }
      expect(b.blackHole.activations, 1);
    },
  );

  test('overlapping objects are independently accessible in visual order', () {
    final b = board(active: false);
    final a = b.blackHole.forceSpawn(position: const Vec(140, 260))!;
    final z = b.blackHole.forceSpawn(position: a.position)!;
    for (var i = 0; i < z.hitsRequired; i++) {
      b.touch(a.position);
      b.releasePointer();
    }
    expect(b.blackHole.objects, [a]);
    expect(a.hits, 0);
    b.touch(a.position);
    b.releasePointer();
    expect(a.hits, 1);
  });

  test('pausing and background freeze both checks and active time', () {
    final s = GameSession(catalog, MemoryStore(), eventSeed: 42)..startDay();
    activate(s.board!.blackHole, s.board!.blackHole.forceSpawn()!);
    tick(s, 3.5);
    s.pause();
    final paused = s.snapshot();
    tick(s, 4);
    expect(s.snapshot(), paused);
    s.resume();
    tick(s, 1);
    expect(s.board!.blackHole.remaining, closeTo(5.5, .00001));
    s.setBackgrounded(true);
    final background = s.snapshot();
    tick(s, 8);
    expect(s.snapshot(), background);
    s.setBackgrounded(false);
    expect(s.paused, isTrue);
    s.dispose();
  });

  test(
    'restore preserves damaged objects, active time and future independent rolls',
    () {
      final s = GameSession(catalog, MemoryStore(), eventSeed: 42)..startDay();
      final e = s.board!.blackHole;
      e.forceSpawn();
      e.forceSpawn();
      activate(e, e.objects.first);
      s.touch(e.objects.first.position);
      s.release();
      tick(s, 4.5);
      final saved = s.snapshot();
      final restored = GameSession(catalog, MemoryStore())..restore(saved);
      final other = restored.board!.blackHole;
      expect(other.toJson(), e.toJson());
      expect(restored.paused, isTrue);
      restored.resume();
      tick(s, 4);
      tick(restored, 4);
      expect(other.toJson(), e.toJson());
      expect(other.activations, 1);
      s.dispose();
      restored.dispose();
    },
  );

  test(
    'closing removes unbroken objects, ends suction and persists without activation',
    () {
      final s = GameSession(catalog, MemoryStore())..startDay();
      final e = s.board!.blackHole;
      e.forceSpawn();
      e.forceSpawn();
      tick(s, 14);
      activate(e, e.objects.first);
      tick(s, 1.1);
      expect(e.ended, isTrue);
      expect(e.active, isFalse);
      expect(e.objects, isEmpty);
      final positions = e.objects.map((o) => o.position.toJson()).toList();
      final restored = GameSession(catalog, MemoryStore())
        ..restore(s.snapshot());
      expect(restored.board, isNull);
      expect(restored.running, isFalse);
      final count = e.activations;
      expect(e.hit(2), isFalse);
      tick(s, 1);
      expect(e.objects.map((o) => o.position.toJson()).toList(), positions);
      expect(e.activations, count);
      s.finishDay();
      expect(e.objects, isEmpty);
      s.startDay();
      expect(s.board!.blackHole.activations, 0);
      expect(s.board!.blackHole.objects, isEmpty);
      s.dispose();
      restored.dispose();
    },
  );

  test(
    'invalid event snapshots fail atomically without overwriting progress',
    () {
      final s = GameSession(catalog, MemoryStore())..startDay();
      s.board!.blackHole.forceSpawn();
      final saved = s.snapshot();
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (e) => e['remaining'] = 11,
        (e) => e['checks'] = 1,
        (e) => e['elapsed'] = double.infinity,
        (e) => e['activations'] = 1,
        (e) => e['objects'][0]['hitsRequired'] = 7,
        (e) => e['objects'][0]['hits'] = 6,
        (e) => e['objects'].add(Map<String, dynamic>.from(e['objects'][0])),
        (e) => e['objects'][0]['position'] = [800, 100],
        (e) => e['objects'][0]['velocity'] = [200, 100],
      ]) {
        final data = jsonDecode(saved) as Map<String, dynamic>;
        mutate(data['run']['board']['blackHole'] as Map<String, dynamic>);
        // Non-finite JSON is rejected by encoding before restoration as well.
        expect(() => s.restore(jsonEncode(data)), throwsA(isA<Object>()));
        expect(s.snapshot(), saved);
      }
      s.dispose();
    },
  );

  test(
    'legacy v11 in-progress days retain exact settings until the following day',
    () {
      final s = GameSession(catalog, MemoryStore())..startDay();
      final data = jsonDecode(s.snapshot()) as Map<String, dynamic>;
      data['version'] = 7;
      data.remove('feeding');
      data['run']['remaining'] += 5;
      data['run']['balanceVersion'] = 11;
      data['run']['settings'] = catalog
          .settings({}, balanceVersion: 11)
          .toJson();
      (data['run']['board'] as Map).remove('blackHole');
      s.restore(jsonEncode(data));
      expect(s.board!.settings.balanceVersion, 11);
      expect(s.board!.blackHole.enabled, isFalse);
      s.resume();
      tick(s, 4);
      expect(s.board!.blackHole.objects, isEmpty);
      s.finishDay();
      s.startDay();
      expect(s.board!.blackHole.enabled, isTrue);
      expect(s.board!.settings.balanceVersion, 15);
      s.dispose();
    },
  );

  test(
    'DEBUG forced objects are temporary and never overwrite the normal save',
    () async {
      final store = MemoryStore();
      final s = GameSession(catalog, store)..economy.balance = 123;
      await s.save();
      final baseline = s.snapshot();
      s.debugSetBlackHoleObjects(3);
      expect(s.debugBlackHoleObjects, 0);
      s.enterDebug();
      await Future<void>.delayed(Duration.zero);
      final writes = store.writes.length;
      s.debugSetBlackHoleObjects(3);
      s.startDay();
      expect(s.board!.blackHole.objects, hasLength(3));
      expect(s.debugBlackHoleObjects, 0);
      activate(s.board!.blackHole, s.board!.blackHole.objects.first);
      tick(s, 3);
      await s.save();
      expect(store.writes, hasLength(writes));
      s.exitDebug();
      expect(s.snapshot(), baseline);
      s.dispose();
    },
  );

  test(
    'maximum configured appearances remain bounded and never violate speed limits',
    () {
      final settings = catalog.settings({'duration': 5, 'walls': 3})
        ..values['black_hole_probability'] = 1
        ..values['black_hole_interval'] = .25;
      final b = Board(settings);
      b.blackHole.forceSpawn();
      activate(b.blackHole, b.blackHole.objects.first);
      for (var i = 0; i < 200; i++) {
        ball(
          b,
          Vec(10 + (i % 20) * 17, 160 + (i ~/ 20) * 25),
          velocity: const Vec(380, -300),
        );
      }
      for (var i = 0; i < 2400; i++) {
        b.update(1 / 240, producing: true);
      }
      for (final item in b.balls) {
        expect(item.velocity.length.isFinite, isTrue);
        expect(item.velocity.length, lessThanOrEqualTo(380.00001));
        expect(item.position.x, inInclusiveRange(b.radius, 360 - b.radius));
        expect(item.position.y, inInclusiveRange(b.radius, 560 - b.radius));
      }
      expect(b.blackHole.objects.length, 40);
      for (final object in b.blackHole.objects.toList()) {
        b.blackHole.hit(object.id);
      }
      expect(b.blackHole.impacts, hasLength(24));
      b.blackHole.advance(.2, producing: true);
      expect(b.blackHole.impacts, isEmpty);
    },
  );

  test(
    'event configuration rejects per-frame intervals and impossible probabilities',
    () {
      final csv = File('docs/balance.csv').readAsStringSync();
      for (final pair in [
        ('black_hole_interval,3', 'black_hole_interval,0.001'),
        ('black_hole_probability,0.05', 'black_hole_probability,1.1'),
        ('black_hole_duration,10', 'black_hole_duration,11'),
        ('black_hole_radius,180', 'black_hole_radius,30'),
      ]) {
        final invalid = csv.replaceFirst(pair.$1, pair.$2);
        expect(invalid, isNot(csv));
        expect(() => UpgradeCatalog.fromCsv(invalid), throwsFormatException);
      }
    },
  );

  test(
    'E01 and E02 use separate random streams and neither changes ball generation',
    () {
      final plain = board(active: false);
      final both = Board(
        plain.settings,
        gravitySupported: true,
        forceGravity: true,
      );
      both.blackHole.forceSpawn();
      final gravityState = both.gravity.randomState;
      activate(both.blackHole, both.blackHole.objects.first);
      expect(both.gravity.randomState, gravityState);
      for (var i = 0; i < 120; i++) {
        plain.update(1 / 60, producing: true);
        both.update(1 / 60, producing: true);
      }
      expect(both.randomState, plain.randomState);
      expect(both.spawned, plain.spawned);
      expect(both.balls.map((b) => b.golden), plain.balls.map((b) => b.golden));
    },
  );

  test(
    'suction renders beneath balls and tools and never advances simulation',
    () async {
      final s = GameSession(catalog, MemoryStore())..startDay();
      final b = s.board!;
      activate(b.blackHole, b.blackHole.forceSpawn()!);
      b.blackHole.announcement = 0;
      b.blackHole.elapsed = .6;
      // Put an opaque ball directly on one of the suction rings.
      final phase = (b.blackHole.elapsed * .7 + 1 / 3) % 1;
      final radius = 30 + (b.blackHole.reach - 30) * (1 - phase);
      final item = ball(b, Board.hole + Vec(0, radius));
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

      final before = jsonEncode(b.toJson());
      final active = await pixels();
      expect(jsonEncode(b.toJson()), before);
      b.blackHole.remaining = 0;
      final inactive = await pixels();
      expect(active, isNot(orderedEquals(inactive)));
      final offset =
          ((item.position.y.floor() * 360) + item.position.x.floor()) * 4;
      expect(
        active.sublist(offset, offset + 4),
        inactive.sublist(offset, offset + 4),
      );
      s.dispose();
    },
  );

  testWidgets(
    'sound consumes only new activations and respects silence and restoration',
    (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final feedback = BlackHoleFeedback();
      final b = board(active: false);
      b.blackHole.forceSpawn();
      b.blackHole.forceSpawn();
      b.blackHole.forceSpawn();
      feedback.sync(b, sound: true, playing: true);
      activate(b.blackHole, b.blackHole.objects.first);
      feedback.sync(b, sound: true, playing: true);
      feedback.sync(b, sound: true, playing: true);
      await tester.pump();
      expect(calls.where((c) => c.method == 'SystemSound.play'), hasLength(1));
      activate(b.blackHole, b.blackHole.objects.first);
      feedback.sync(b, sound: false, playing: true);
      feedback.sync(b, sound: true, playing: true);
      final restored = Board.fromJson(
        b.settings,
        jsonDecode(jsonEncode(b.toJson())) as Map<String, dynamic>,
      );
      feedback.sync(restored, sound: true, playing: true);
      await tester.pump();
      expect(calls.where((c) => c.method == 'SystemSound.play'), hasLength(1));
      activate(restored.blackHole, restored.blackHole.objects.first);
      feedback.sync(restored, sound: true, playing: false);
      feedback.sync(restored, sound: true, playing: true);
      await tester.pump();
      expect(calls.where((c) => c.method == 'SystemSound.play'), hasLength(1));
    },
  );

  testWidgets('small-screen DEBUG can select three objects without sensors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final s = GameSession(catalog, MemoryStore());
    await tester.pumpWidget(GardenApp(session: s));
    await tester.scrollUntilVisible(find.text('Tienda'), 150);
    await tester.tap(find.text('Tienda'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tree-debug-tools')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('debug-black-hole-tools')),
    );
    await tester.tap(find.text('Agujero negro'));
    await tester.pumpAndSettle();
    final dropdown = find.byKey(const ValueKey('debug-black-hole-count'));
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 objetos de prueba').last);
    await tester.pumpAndSettle();
    expect(s.debugBlackHoleObjects, 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  });
}

void activate(BlackHoleEvent event, BlackHoleObject object) {
  final taps = object.hitsRequired - object.hits;
  for (var i = 0; i < taps; i++) {
    expect(event.hit(object.id), isTrue);
  }
}
