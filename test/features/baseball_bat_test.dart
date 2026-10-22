import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/tool.dart';
import 'package:incremental_hole_game/features/board/domain/special_abilities.dart';
import 'package:incremental_hole_game/features/board/presentation/bat_feedback.dart';
import 'package:incremental_hole_game/features/board/presentation/garden_game.dart';
import '../test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final catalog = testCatalog();
  Board bat({
    int level = 1,
    double speed = 900,
    Map<String, int> other = const {},
  }) {
    final settings = catalog.settings({'hand': 2, 'bat': level, ...other});
    settings.values['bat_move_speed'] = speed;
    return Board(settings)..batPosition = const Vec(180, 250);
  }

  Ball ball(Board b, Vec p, Vec v, {bool golden = false}) {
    final item = Ball(b.nextId++, p, v, golden: golden);
    b.balls.add(item);
    return item;
  }

  void advance(Board b, double seconds) {
    for (var i = 0; i < (seconds * 240).round(); i++) {
      b.update(1 / 240, producing: false);
    }
  }

  Ball strike(Board b, {bool golden = false}) {
    final item = ball(b, const Vec(180, 262.01), Vec.zero, golden: golden);
    b.touch(b.batPosition);
    b.drag(b.batPosition + const Vec(0, 100));
    b.update(1 / 240, producing: false);
    return item;
  }

  test(
    'single grip translates, two grips rotate and either finger can remain',
    () {
      for (final promote in [false, true]) {
        final b = bat();
        final broomBefore = b.broomPosition;
        b.touch(b.batHandles.first);
        expect(b.holdingBat, isTrue);
        b.drag(b.target! + const Vec(20, 30));
        advance(b, .2);
        expect(b.batPosition.x, closeTo(200, .001));
        expect(b.batAngle, 0);
        final a = b.batHandles.first, c = b.batHandles.last;
        // Re-grip at the translated endpoints, turn by 90 degrees.
        b.releasePointer();
        b.touch(a);
        expect(b.grabSecondBroomPoint(c), isTrue);
        final center = b.batPosition;
        b.drag(center - const Vec(0, 36));
        b.dragSecondBroomPoint(center + const Vec(0, 36));
        advance(b, .8);
        expect(b.batAngle, closeTo(math.pi / 2, .001));
        expect(
          (b.batHandles.first - b.batHandles.last).length,
          closeTo(72, .001),
        );
        if (promote) {
          b.promoteSecondBroomPoint();
        } else {
          b.releaseSecondBroomPoint();
        }
        b.drag(b.target! + const Vec(20, 10));
        advance(b, .2);
        expect(b.batPosition.x, closeTo(center.x + 20, .001));
        expect(b.batAngle, closeTo(math.pi / 2, .001));
        b.releasePointer();
        final position = b.batPosition, angle = b.batAngle;
        advance(b, .4);
        expect(b.batPosition, position);
        expect(b.batAngle, angle);
        expect(b.broomPosition, broomBefore);
        expect(b.holdingBat, isFalse);
      }
    },
  );

  test('fast strikes and each power level add more active normal impulse', () {
    final slow = strike(bat(speed: 20)).velocity.length;
    final fast = strike(bat(speed: 90)).velocity.length;
    expect(slow, greaterThan(0));
    expect(fast, greaterThan(slow * 2));
    var previous = 0.0;
    for (var level = 1; level <= 3; level++) {
      for (final golden in [false, true]) {
        final b = bat(level: level, speed: 40);
        final hit = strike(b, golden: golden);
        expect(hit.velocity.y, greaterThan(previous));
        expect(hit.velocity.x, closeTo(0, .001));
        expect(hit.golden, golden);
        expect(hit.velocity.length, lessThanOrEqualTo(380));
        if (golden) previous = hit.velocity.y;
      }
    }
    expect(strike(bat(level: 3)).velocity.length, lessThanOrEqualTo(380));
  });

  test(
    'stationary bat rebounds moderately and power never changes passive bounce',
    () {
      double? expected;
      for (var level = 1; level <= 3; level++) {
        final b = bat(level: level);
        final item = ball(b, const Vec(180, 262.01), const Vec(15, -100));
        b.update(1 / 240, producing: false);
        expect(item.velocity.y, inInclusiveRange(39, 41));
        expect(item.velocity.x, inInclusiveRange(14, 16));
        if (expected != null) expect(item.velocity.y, closeTo(expected, .001));
        expected = item.velocity.y;
        final speed = item.velocity.length;
        advance(b, .1);
        expect(b.batImpactSerial, 1);
        expect(item.velocity.length, lessThan(speed));
      }
    },
  );

  test('rotation contributes point velocity more strongly near the tips', () {
    double rotateHit(double arm) {
      final b = bat();
      final item = ball(b, Vec(180 + arm, 262.01), Vec.zero);
      b.touch(b.batHandles.first);
      b.grabSecondBroomPoint(b.batHandles.last);
      b.drag(const Vec(180, 214));
      b.dragSecondBroomPoint(const Vec(180, 286));
      b.update(1 / 240, producing: false);
      expect(b.batPosition.x, closeTo(180, .001));
      expect(b.batPosition.y, closeTo(250, .001));
      return item.velocity.length;
    }

    expect(rotateHit(30), greaterThan(rotateHit(10) * 2));
  });

  test(
    'simultaneous balls, wall synergy and all final speeds stay bounded',
    () {
      final b = bat(level: 3, speed: 60, other: {'walls': 3});
      final items = [
        for (final x in [156.0, 180.0, 204.0])
          ball(b, Vec(x, 262.01), Vec.zero, golden: x == 180),
      ];
      b.touch(b.batPosition);
      b.drag(const Vec(180, 400));
      b.update(1 / 240, producing: false);
      expect(b.batImpactSerial, 3);
      expect(items.every((item) => item.velocity.y > 0), isTrue);
      b.releasePointer();
      // Send one of the hit balls into an improved wall with the same velocity.
      final item = items.first;
      item.position = const Vec(100, 553.99);
      final incoming = item.velocity.length;
      b.update(1 / 240, producing: false);
      expect(item.velocity.y, lessThan(0));
      expect(item.velocity.length, greaterThan(incoming));
      advance(b, .5);
      expect(
        b.balls.every((item) => item.velocity.length <= 380 + 1e-9),
        isTrue,
      );
    },
  );

  test('contact is not re-boosted, separation allows a new genuine impact', () {
    final b = bat(speed: 40);
    final item = strike(b);
    expect(b.batImpactSerial, 1);
    // Keep contact while approaching, as could happen when trapped against a tool.
    for (var i = 0; i < 20; i++) {
      item.position = b.batPosition + const Vec(0, 11.99);
      item.velocity = Vec.zero;
      b.update(1 / 240, producing: false);
      expect(item.velocity.length, lessThanOrEqualTo(40.01));
    }
    expect(b.batImpactSerial, 1);
    item.position = const Vec(300, 300);
    b.update(1 / 240, producing: false);
    item.position = b.batPosition + const Vec(0, 12.01);
    item.velocity = Vec.zero;
    b.update(1 / 240, producing: false);
    expect(b.batImpactSerial, 2);
    expect(item.velocity.y, greaterThan(40));
  });

  test('coins and abilities stay independent; hand and broom still work', () {
    final b = bat(
      other: {
        'broom': 1,
        'sweep': 1,
        'collection': 3,
        'magnet': 1,
        'combo': 1,
        'capture_all': 1,
        'boost': 1,
        'generator': 1,
      },
    );
    final coin = Coin(b.nextId++, b.batPosition, 10, landing: 0);
    b.coins.add(coin);
    final hit = strike(b);
    expect(b.coins, contains(coin));
    final coinPosition = coin.position;
    advance(b, .1);
    expect(coin.position, coinPosition);
    expect(b.specials.captureCharge, 0);
    expect(b.specials.boostRemaining, 0);
    expect(b.specials.ready(SpecialAbility.captureAll), isFalse);
    b.releasePointer();
    hit.position = const Vec(300, 350);
    b.touch(hit.position);
    expect(b.heldBall, hit);
    b.releasePointer(cancel: true);
    b.touch(b.broomHandles.first);
    expect(b.holdingBroom, isTrue);
    expect(b.holdingBat, isFalse);
  });

  test('closing freezes the bat and balls and releases both grip points', () {
    final b = bat();
    final item = ball(b, const Vec(180, 270), const Vec(0, -100));
    b.touch(b.batHandles.first);
    b.grabSecondBroomPoint(b.batHandles.last);
    b.drag(const Vec(140, 400));
    b.enterClosing();
    final position = b.batPosition, ballPosition = item.position;
    advance(b, .5);
    expect(b.batPosition, position);
    expect(item.position, ballPosition);
    expect(b.holdingBat, isFalse);
    expect(b.hasSecondBroomPoint, isFalse);
    expect(b.batImpactSerial, 0);
  });

  test(
    'purchases, pose and settings persist; debug never writes bat purchases',
    () async {
      final store = MemoryStore();
      final session = GameSession(catalog, store)..economy.balance = 10000;
      final definition = catalog.definitions.firstWhere((d) => d.id == 'bat');
      expect(session.purchase(definition), isFalse);
      session.purchase(catalog.definitions.firstWhere((d) => d.id == 'hand'));
      for (var i = 1; i <= 3; i++) {
        expect(session.purchase(definition), isTrue);
        final restored = GameSession(catalog, MemoryStore())
          ..restore(session.snapshot());
        expect(restored.levels['bat'], i);
        restored.startDay();
        expect(
          restored.board!.settings['bat_power'],
          definition.levels[i - 1].value,
        );
        restored.dispose();
      }
      session.setHaptics(false);
      session.startDay();
      session.board!
        ..batPosition = const Vec(160, 330)
        ..batAngle = 1.2;
      session.touch(session.board!.batHandles.first);
      session.grabSecondBroomPoint(session.board!.batHandles.last);
      expect(session.purchase(definition), isFalse);
      final restored = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      expect(restored.selectedTool, BallTool.bat);
      expect(restored.board!.batPosition.x, 160);
      expect(restored.board!.batPosition.y, 330);
      expect(restored.board!.batAngle, closeTo(1.2, .001));
      expect(restored.board!.holdingBat, isFalse);
      expect(restored.haptics, isFalse);
      restored.resume();
      restored.finishDay();
      restored.startDay();
      expect(restored.board!.batUnlocked, isTrue);
      final debugStore = MemoryStore();
      final debug = GameSession(catalog, debugStore);
      debug.enterDebug();
      await debug.pendingWrites;
      final writes = List.of(debugStore.writes);
      expect(debug.debugPurchase('bat', 3), isTrue);
      debug.startDay();
      strike(debug.board!);
      debug.tick(.02);
      await debug.pendingWrites;
      expect(debugStore.writes, writes);
      debug.exitDebug();
      expect(debug.levels.containsKey('bat'), isFalse);
      await session.pendingWrites;
      await restored.pendingWrites;
      session.dispose();
      restored.dispose();
      debug.dispose();
    },
  );

  test(
    'legacy v9 journeys keep economics and no bat until the following day',
    () async {
      final session = GameSession(catalog, MemoryStore())..startDay();
      final saved = jsonDecode(session.snapshot()) as Map<String, dynamic>;
      saved['version'] = 7;
      saved.remove('feeding');
      saved['run']['balanceVersion'] = 9;
      saved['run']['settings'] = catalog
          .settings({}, balanceVersion: 9)
          .toJson();
      saved['run']['board'].remove('batPosition');
      saved['run']['board'].remove('batAngle');
      saved.remove('haptics');
      final restored = GameSession(catalog, MemoryStore())
        ..restore(jsonEncode(saved));
      expect(restored.haptics, isTrue);
      expect(restored.board!.settings.balanceVersion, 9);
      expect(restored.board!.batUnlocked, isFalse);
      restored.resume();
      restored.finishDay();
      restored.startDay();
      expect(restored.board!.settings.balanceVersion, 19);
      await session.pendingWrites;
      await restored.pendingWrites;
      session.dispose();
      restored.dispose();
    },
  );

  test(
    'invalid bat pose is rejected without partially replacing the session',
    () {
      final session = GameSession(catalog, MemoryStore())..startDay();
      for (final invalid in [double.nan, -1.0, 10000.0]) {
        final json = jsonDecode(session.snapshot()) as Map<String, dynamic>;
        if (invalid.isNaN) {
          json['run']['board']['batAngle'] = 'NaN';
        } else {
          json['run']['board']['batPosition'] = [invalid, 300];
        }
        expect(() => session.restore(jsonEncode(json)), throwsFormatException);
        expect(session.board!.batPosition.x, 80);
      }
      session.dispose();
    },
  );

  test(
    'impact feedback is synchronized, batched, throttled and respects preferences',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            calls.add(call);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final b = bat(speed: 40);
      final feedback = BatFeedback();
      strike(b);
      feedback.update(.016, b, sound: true, haptics: true);
      await Future<void>.delayed(Duration.zero);
      expect(calls.map((c) => c.method), [
        'SystemSound.play',
        'HapticFeedback.vibrate',
      ]);
      b.batImpactSerial += 20;
      feedback.update(.016, b, sound: true, haptics: true);
      expect(calls, hasLength(2));
      feedback.update(.2, b, sound: true, haptics: true);
      expect(calls, hasLength(2)); // No delayed burst.
      b.batImpactSerial++;
      feedback.update(.2, b, sound: false, haptics: false);
      expect(calls, hasLength(2));
      b.batImpactSerial++;
      b.lastBatImpactStrength = 1;
      feedback.update(.2, b, sound: false, haptics: true);
      await Future<void>.delayed(Duration.zero);
      expect(calls.last.arguments, 'HapticFeedbackType.mediumImpact');
      expect(calls.where((c) => c.method == 'SystemSound.play'), hasLength(1));
      b.batImpactSerial++;
      feedback.suppress(
        b,
      ); // A pause consumes pending contacts without playback.
      feedback.update(.2, b, sound: true, haptics: true);
      expect(calls, hasLength(3));
      b.enterClosing();
      b.batImpactSerial++;
      feedback.update(.2, b, sound: true, haptics: true);
      expect(calls, hasLength(3));
    },
  );

  test(
    'power upgrades change neither geometry, control speed nor passive restitution',
    () {
      final baseline = bat();
      for (var level = 2; level <= 3; level++) {
        final b = bat(level: level);
        for (final key in [
          'bat_half_length',
          'bat_thickness',
          'bat_move_speed',
          'bat_angular_speed',
          'bat_restitution',
          'bat_manual_gain',
        ]) {
          expect(b.settings[key], baseline.settings[key], reason: key);
        }
        expect(
          b.settings['bat_power'],
          greaterThan(baseline.settings['bat_power']),
        );
      }
    },
  );

  test(
    'a separating ball receives no strike; later ball collisions still transfer momentum',
    () {
      final b = bat(speed: 40);
      final item = ball(b, const Vec(180, 261.99), const Vec(0, 200));
      b.touch(b.batPosition);
      b.drag(const Vec(180, 350));
      b.update(1 / 240, producing: false);
      expect(item.velocity.y, lessThan(200));
      expect(b.batImpactSerial, 0);
      final pair = bat(speed: 90);
      final hit = strike(pair);
      pair.releasePointer();
      final other = ball(pair, const Vec(180, 286), Vec.zero);
      advance(pair, .12);
      expect(other.velocity.y, greaterThan(0));
      expect(hit.velocity.length, lessThanOrEqualTo(380));
    },
  );

  test(
    '200 balls under translation and rotation remain finite, bounded and capped',
    () {
      final b = bat(level: 3, other: {'walls': 3, 'broom': 1});
      for (var i = 0; i < 200; i++) {
        ball(
          b,
          Vec(10 + i % 20 * 17, 120 + i ~/ 20 * 30),
          Vec(i.isEven ? 380 : -380, 200),
          golden: i % 5 == 0,
        );
      }
      b.touch(b.batHandles.first);
      b.grabSecondBroomPoint(b.batHandles.last);
      for (var frame = 0; frame < 300; frame++) {
        final center = Vec(
          180 + 120 * math.sin(frame * .1),
          300 + 140 * math.cos(frame * .1),
        );
        final axis = Vec(math.cos(frame * .13), math.sin(frame * .13)) * 36;
        b.drag(center - axis);
        b.dragSecondBroomPoint(center + axis);
        b.update(1 / 60, producing: false);
        expect(b.batImpacts.length, lessThanOrEqualTo(24));
        for (final item in b.balls) {
          expect(item.position.x, inInclusiveRange(6, 354));
          expect(item.position.y, inInclusiveRange(6, 554));
          expect(item.velocity.length, lessThanOrEqualTo(380 + 1e-9));
        }
      }
      b.releasePointer();
      b.balls.clear();
      advance(b, .2);
      expect(b.batImpacts, isEmpty);
    },
  );

  test(
    'impact drawing respects visual feedback without modifying the board',
    () async {
      final session = GameSession(catalog, MemoryStore())
        ..levels.addAll({'hand': 1, 'bat': 1})
        ..startDay();
      strike(session.board!);
      final before = jsonEncode(session.board!.toJson());
      final game = GardenGame(session)..onGameResize(Vector2(360, 560));
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

      final off = await pixels();
      session.visualFeedback = true;
      expect(await pixels(), isNot(orderedEquals(off)));
      session.visualFeedback = false;
      expect(await pixels(), orderedEquals(off));
      expect(jsonEncode(session.board!.toJson()), before);
      await session.pendingWrites;
      session.dispose();
    },
  );

  test(
    'a resting contact arms one real strike when the player starts moving',
    () {
      final b = bat(speed: 40);
      final item = ball(b, const Vec(180, 261.99), Vec.zero);
      b.update(1 / 240, producing: false);
      expect(b.batImpactSerial, 0);
      b.touch(b.batPosition);
      b.drag(const Vec(180, 350));
      b.update(1 / 240, producing: false);
      expect(b.batImpactSerial, 1);
      expect(item.velocity.y, greaterThan(40));
    },
  );

  test(
    'bat reaches each edge according to its orientation and restores there',
    () {
      for (final angle in [0.0, math.pi / 2]) {
        final b = bat()..batAngle = angle;
        b.touch(b.batPosition);
        b.drag(const Vec(0, 0));
        advance(b, 1);
        expect(b.batPosition.x, closeTo(angle == 0 ? 42 : 6, .001));
        expect(b.batPosition.y, closeTo(angle == 0 ? 6 : 42, .001));
        final loaded = Board.fromJson(b.settings, b.toJson());
        expect(loaded.batPosition.x, closeTo(b.batPosition.x, .001));
        expect(loaded.batPosition.y, closeTo(b.batPosition.y, .001));
        b.releasePointer();
        b.touch(b.batPosition);
        b.drag(const Vec(360, 560));
        advance(b, 1);
        for (final point in b.batHandles) {
          expect(point.x, inInclusiveRange(6 - 1e-9, 354 + 1e-9));
          expect(point.y, inInclusiveRange(6 - 1e-9, 554 + 1e-9));
        }
        expect(b.batPosition.x, closeTo(angle == 0 ? 318 : 354, .001));
        expect(b.batPosition.y, closeTo(angle == 0 ? 554 : 518, .001));
      }
    },
  );

  testWidgets(
    'actual bat gestures share two-finger handoff and pause releases',
    (tester) async {
      final session = GameSession(catalog, MemoryStore())
        ..levels.addAll({'hand': 1, 'bat': 1})
        ..startDay();
      session.board!.batPosition = const Vec(180, 250);
      await tester.pumpWidget(GardenApp(session: session));
      await tester.pump(const Duration(milliseconds: 50));
      final finder = find.byWidgetPredicate((widget) => widget is GameWidget);
      final game = tester.widget<GameWidget>(finder).game as GardenGame;
      final topLeft = tester.getTopLeft(finder);
      Offset point(Vec value) =>
          topLeft + game.origin + Offset(value.x, value.y) * game.scale;
      final b = session.board!;
      final first = await tester.startGesture(
        point(b.batHandles.first),
        pointer: 1,
      );
      final second = await tester.startGesture(
        point(b.batHandles.last),
        pointer: 2,
      );
      expect(b.holdingBat, isTrue);
      expect(b.hasSecondBroomPoint, isTrue);
      await first.moveTo(point(const Vec(180, 214)));
      await second.moveTo(point(const Vec(180, 286)));
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 17));
      }
      expect(b.batAngle, closeTo(math.pi / 2, .01));
      await first.up();
      expect(b.holdingBat, isTrue);
      expect(b.hasSecondBroomPoint, isFalse);
      await second.moveBy(Offset(20 * game.scale, 0));
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 17));
      }
      expect(b.batPosition.x, closeTo(200, .1));
      session.pause();
      expect(b.holdingBat, isFalse);
      await second.up();
      await tester.pump();
      expect(find.byKey(const ValueKey('haptics-setting')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await session.pendingWrites;
      session.dispose();
    },
  );
}
