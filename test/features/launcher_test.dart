import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/presentation/garden_game.dart';
import 'package:incremental_hole_game/features/board/presentation/launcher_feedback.dart';
import 'package:incremental_hole_game/features/upgrades/domain/catalog.dart';
import 'package:incremental_hole_game/features/upgrades/domain/skill_tree.dart';
import '../test_support.dart';

void main() {
  final catalog = testCatalog();
  const owned = {'hand': 1, 'generator': 2, 'launcher': 1};
  Board board({int rate = 0, bool unlocked = true}) {
    final settings = catalog.settings(
      unlocked ? {...owned, if (rate > 0) 'launcher_rate': rate} : {},
    )..values['black_hole_probability'] = 0;
    return Board(settings);
  }

  void advance(Board b, double seconds, {bool producing = true}) {
    for (var i = 0; i < (seconds * 240).round(); i++) {
      b.update(1 / 240, producing: producing);
    }
  }

  void tick(GameSession s, double seconds) {
    for (var i = 0; i < (seconds * 60).round(); i++) {
      s.tick(1 / 60);
    }
  }

  Ball ball(Board b, Vec point, {Vec velocity = Vec.zero}) {
    final item = Ball(b.nextId++, point, velocity);
    b.balls.add(item);
    return item;
  }

  test(
    'launcher is an independent generation branch with its own rate and fixed power',
    () {
      final tree = SkillTree(catalog);
      expect(tree.nodes, hasLength(55));
      expect(tree.byId('launcher:1').parents, ['generator:2']);
      expect(tree.byId('launcher_rate:1').parents, ['launcher:1']);
      final normalInterval = catalog.settings(owned)['spawn_interval'];
      for (var level = 0; level <= 3; level++) {
        final settings = catalog.settings({
          ...owned,
          if (level > 0) 'launcher_rate': level,
        });
        expect(settings['launcher_interval'], [2.4, 1.8, 1.2, .8][level]);
        expect(settings['launcher_speed'], 280);
        expect(settings['spawn_interval'], normalInterval);
      }
      expect(board(unlocked: false).launcher.unlocked, isFalse);
    },
  );

  test(
    'both generators fire together; each rate yields progressively more shots',
    () {
      var previous = 0;
      for (var level = 0; level <= 3; level++) {
        final b = board(rate: level);
        advance(b, 8);
        expect(b.launcher.shots, greaterThan(previous));
        expect(b.spawned, greaterThan(b.launcher.shots));
        previous = b.launcher.shots;
      }
    },
  );

  test(
    'initial shot is fast, has no recoil and cannot trivially reach the hole at rest',
    () {
      final b = board();
      b.settings.values['spawn_interval'] = 1000;
      final initial = b.launcher.position, angle = b.launcher.angle;
      advance(b, 2.4);
      expect(b.launcher.shots, 1);
      expect(b.launcher.flash, greaterThan(0));
      expect(b.balls.single.velocity.length, greaterThan(270));
      expect((b.launcher.position - initial).length, 0);
      expect(b.launcher.angle, angle);
      advance(b, 2);
      expect(b.captured, 0);
      expect((b.launcher.position - initial).length, 0);
    },
  );

  test(
    'one finger translates without turning and release leaves the exact pose',
    () {
      final b = board();
      final angle = b.launcher.angle;
      b.touch(b.launcher.position);
      expect(b.holdingLauncher, isTrue);
      b.drag(const Vec(100, 490));
      advance(b, .5, producing: false);
      expect(b.launcher.position.x, closeTo(100, .001));
      expect(b.launcher.angle, angle);
      final point = b.launcher.position;
      b.releasePointer();
      advance(b, .5, producing: false);
      expect((b.launcher.position - point).length, 0);
      expect(b.launcher.angle, angle);
    },
  );

  test(
    'two fingers rotate through full orientation and either remaining finger can translate',
    () {
      final b = board();
      b.launcher.move(const Vec(180, 490), 0);
      b.touch(b.launcher.handles.first);
      expect(b.grabSecondBroomPoint(b.launcher.handles.last), isTrue);
      final point = b.target!;
      b.dragSecondBroomPoint(point + const Vec(0, -48));
      advance(b, 1, producing: false);
      expect(b.launcher.angle, closeTo(math.pi * 1.5, .001));
      b.promoteSecondBroomPoint();
      final angle = b.launcher.angle;
      b.drag(b.target! + const Vec(20, 0));
      advance(b, .2, producing: false);
      expect(b.launcher.angle, angle);
      b.releasePointer();
      b.launcher.move(const Vec(180, 490), math.pi);
      expect(
        b.launcher.angle,
        math.pi,
      ); // No artificial direction restrictions.
    },
  );

  test(
    'overlapping broom and bat keep their visible grip priority above the launcher',
    () {
      final b = board();
      b.settings.values['broom_unlocked'] = 1;
      b.broomPosition = b.launcher.position;
      b.touch(b.launcher.position);
      expect(b.holdingBroom, isTrue);
      expect(b.holdingLauncher, isFalse);
      b.releasePointer();
      b.broomPosition = const Vec(290, 100);
      b.settings.values['bat_power'] = 1;
      b.batPosition = b.launcher.position;
      b.touch(b.launcher.position);
      expect(b.holdingBat, isTrue);
      expect(b.holdingLauncher, isFalse);
      b.releasePointer();
      b.batPosition = const Vec(80, 300);
      b.touch(b.launcher.position);
      expect(b.holdingLauncher, isTrue);
    },
  );

  test(
    'the complete body and barrel stay within the bottom quarter at every orientation',
    () {
      final b = board();
      for (var i = 0; i < 360; i += 5) {
        for (final requested in [
          const Vec(-100, 0),
          const Vec(500, 0),
          const Vec(-100, 900),
          const Vec(500, 900),
        ]) {
          b.launcher.move(requested, i * math.pi / 180);
          expect(
            b.launcher.position.x - b.launcher.bodyRadius,
            greaterThanOrEqualTo(0),
          );
          expect(
            b.launcher.position.x + b.launcher.bodyRadius,
            lessThanOrEqualTo(360),
          );
          expect(
            b.launcher.position.y - b.launcher.bodyRadius,
            greaterThanOrEqualTo(420),
          );
          expect(
            b.launcher.position.y + b.launcher.bodyRadius,
            lessThanOrEqualTo(560),
          );
          expect(
            b.launcher.muzzle.x - b.launcher.barrelRadius,
            greaterThanOrEqualTo(-1e-9),
          );
          expect(
            b.launcher.muzzle.x + b.launcher.barrelRadius,
            lessThanOrEqualTo(360.0000001),
          );
          expect(
            b.launcher.muzzle.y - b.launcher.barrelRadius,
            greaterThanOrEqualTo(419.9999999),
          );
          expect(
            b.launcher.muzzle.y + b.launcher.barrelRadius,
            lessThanOrEqualTo(560.0000001),
          );
          expect(b.launcher.boundaryFlash, greaterThan(0));
        }
      }
    },
  );

  test(
    'it continues firing while held; shots never push or rotate the body',
    () {
      final b = board();
      b.touch(b.launcher.position);
      final point = b.launcher.position, angle = b.launcher.angle;
      advance(b, 5);
      expect(b.launcher.shots, 2);
      expect(b.holdingLauncher, isTrue);
      expect((b.launcher.position - point).length, 0);
      expect(b.launcher.angle, angle);
    },
  );

  test(
    'one, two or three extreme impacts cannot move or turn the generator',
    () {
      for (var count = 1; count <= 3; count++) {
        final b = board();
        b.launcher.move(const Vec(230, 490), 0);
        final point = b.launcher.position, angle = b.launcher.angle;
        final incoming = <Ball>[];
        for (var i = 0; i < count; i++) {
          incoming.add(
            ball(
              b,
              point + Vec(-21, (i - 1) * 12),
              velocity: const Vec(10000, 0),
            ),
          );
        }
        for (var step = 0; step < 60; step++) {
          for (var i = 0; i < incoming.length; i++) {
            incoming[i].position = point + Vec(-23, (i - 1) * 12);
            incoming[i].velocity = const Vec(380, 0);
          }
          b.update(1 / 240, producing: false);
        }
        expect((b.launcher.position - point).length, 0);
        expect(b.launcher.angle, angle);
      }
    },
  );

  test(
    'sustained contact pressure moves the heavy body slowly without rotation and stops on release',
    () {
      final b = board();
      b.launcher.move(const Vec(230, 490), 0);
      final point = b.launcher.position;
      final contacts = [for (var i = 0; i < 5; i++) ball(b, Vec.zero)];
      for (var step = 0; step < 720; step++) {
        for (var i = 0; i < contacts.length; i++) {
          final a = (120 + i * 30) * math.pi / 180;
          contacts[i].position =
              b.launcher.position + Vec(math.cos(a), math.sin(a)) * 23.8;
          contacts[i].velocity = Vec.zero;
        }
        b.update(1 / 240, producing: false);
      }
      expect(b.launcher.position.x, greaterThan(point.x));
      expect((b.launcher.position - point).length, lessThan(10));
      expect(b.launcher.angle, 0);
      expect(b.launcher.velocity.length, lessThanOrEqualTo(12));
      b.balls.clear();
      final released = b.launcher.position;
      advance(b, .5, producing: false);
      expect((b.launcher.position - released).length, 0);
      expect(b.launcher.velocity.length, 0);
    },
  );

  test(
    'nearby balls exert no pressure without contact and opposed pressure cancels',
    () {
      final b = board();
      final point = b.launcher.position;
      for (var i = 0; i < 15; i++) {
        final a = i * math.pi * 2 / 15;
        ball(b, point + Vec(math.cos(a), math.sin(a)) * 65);
      }
      advance(b, .1, producing: false);
      expect((b.launcher.position - point).length, 0);
      expect(b.launcher.pressure.length, 0);
      b.launcher.applyPressure(const Vec(1000, 0), 1, held: false);
      expect(b.launcher.velocity.length, greaterThan(0));
      b.launcher.applyPressure(const Vec(360, 0), 1 / 240, held: false);
      expect(b.launcher.velocity.length, 0);
    },
  );

  test(
    'pressure cannot move beyond the zone and manual control bypasses static resistance',
    () {
      final b = board();
      b.launcher.move(const Vec(180, 420), math.pi);
      for (var i = 0; i < 600; i++) {
        b.launcher.applyPressure(const Vec(0, -10000), 1 / 240, held: false);
      }
      expect(b.launcher.position.y - b.launcher.bodyRadius, 420);
      b.touch(b.launcher.position);
      b.drag(const Vec(80, 530));
      advance(b, .5, producing: false);
      expect(b.launcher.position.x, closeTo(80, .001));
      expect(b.launcher.angle, math.pi);
    },
  );

  test(
    'a partially blocked outlet gives physical impulse without overlapping emission or stored shots',
    () {
      final b = board();
      b.settings.values['spawn_interval'] = 1000;
      b.launcher.move(const Vec(180, 490), math.pi * 1.5);
      final exit =
          b.launcher.muzzle +
          b.launcher.axis * (b.launcher.barrelRadius + b.radius + .5);
      final blocker = ball(b, exit + const Vec(9, 0));
      b.launcher.clock = b.launcher.interval - 1 / 240;
      b.update(1 / 240, producing: true);
      expect(b.launcher.attempts, 1);
      expect(b.launcher.shots, 0);
      expect(b.balls, hasLength(1));
      expect(blocker.velocity.y, lessThan(0));
      b.balls.clear();
      advance(b, .2);
      expect(b.launcher.shots, 0);
      advance(b, 2.2);
      expect(b.launcher.attempts, 2);
      expect(b.launcher.shots, 1);
    },
  );

  test(
    'held balls and solid tools block the muzzle; walls prevent firing out of bounds',
    () {
      for (final type in ['held', 'bat', 'broom', 'wall']) {
        final b = board();
        b.settings.values['spawn_interval'] = 1000;
        b.launcher.move(const Vec(100, 490), math.pi * 1.5);
        final exit =
            b.launcher.muzzle +
            b.launcher.axis * (b.launcher.barrelRadius + b.radius + .5);
        if (type == 'held') {
          ball(b, exit);
          b.touch(exit);
        } else if (type == 'bat') {
          b.settings.values['bat_power'] = 1;
          b.batPosition = exit;
        } else if (type == 'broom') {
          b.settings.values['broom_unlocked'] = 1;
          b.broomPosition = exit;
          b.toolAngle = 0;
        } else {
          b.launcher.move(const Vec(-100, 490), math.pi);
        }
        b.launcher.clock = b.launcher.interval - 1 / 240;
        b.update(1 / 240, producing: true);
        expect(b.launcher.shots, 0, reason: type);
        expect(b.launcher.clock, closeTo(0, 1e-9));
      }
    },
  );

  test(
    'global population cap prevents launch shots without saving a backlog',
    () {
      final b = board();
      b.settings.values['ball_limit'] = 3;
      b.settings.values['spawn_interval'] = 1000;
      for (var i = 0; i < 3; i++) {
        ball(b, Vec(40 + i * 25, 250));
      }
      advance(b, 5);
      expect(b.launcher.shots, 0);
      expect(b.balls.length, 3);
      b.balls.clear();
      advance(b, .1);
      expect(b.launcher.shots, 0);
    },
  );

  test(
    'launcher emits golden balls at the applicable one percent probability',
    () {
      final b = board();
      b.settings.values['spawn_interval'] = 100000;
      var golden = 0;
      for (var i = 0; i < 10000; i++) {
        b.balls.clear();
        b.launcher.clock = b.launcher.interval - 1 / 240;
        b.update(1 / 240, producing: true);
        expect(b.balls, hasLength(1));
        if (b.balls.single.golden) golden++;
      }
      expect(golden, inInclusiveRange(70, 130));
    },
  );

  test('launched balls obey upgraded walls and speed limits', () {
    final b = board();
    b.settings.values['wall_restitution'] = 1.6;
    b.settings.values['spawn_interval'] = 1000;
    b.launcher.move(const Vec(230, 490), 0);
    advance(b, 2.4);
    final shot = b.balls.single;
    expect(shot.velocity.x, greaterThan(0));
    advance(b, .4);
    expect(shot.velocity.x, lessThan(0));
    expect(b.wallImpacts, isNotEmpty);
    expect(shot.velocity.length, lessThanOrEqualTo(380));
  });

  test(
    'dense production with 200 balls stays finite, bounded and within the global cap',
    () {
      final b = board(rate: 3);
      b.settings.values['wall_restitution'] = 1.6;
      for (var i = 0; i < 200; i++) {
        ball(
          b,
          Vec(10 + (i % 20) * 17, 150 + (i ~/ 20) * 25),
          velocity: Vec(i.isEven ? 380 : -380, 200),
        );
      }
      for (var frame = 0; frame < 720; frame++) {
        b.update(1 / 240, producing: true);
        expect(b.balls.length, lessThanOrEqualTo(200));
        for (final item in b.balls) {
          expect(item.velocity.length.isFinite, isTrue);
          expect(item.velocity.length, lessThanOrEqualTo(380.000001));
          expect(item.position.x, inInclusiveRange(6, 354));
          expect(item.position.y, inInclusiveRange(6, 554));
        }
        expect(
          (b.launcher.constrain(b.launcher.position, b.launcher.angle) -
                  b.launcher.position)
              .length,
          0,
        );
      }
    },
  );

  test('coins remain unaffected by shots, contacts and generator handling', () {
    final b = board();
    final coin = Coin(b.nextId++, b.launcher.position, 50, landing: 0);
    b.coins.add(coin);
    final original = coin.position;
    b.touch(b.launcher.muzzle);
    advance(b, .1, producing: false);
    b.releasePointer();
    expect(b.coins, contains(coin));
    expect((coin.position - original).length, 0);
    expect(b.pending, 50);
  });

  test(
    'pause, background and closing freeze production, pose and physical simulation',
    () {
      final s = GameSession(catalog, MemoryStore())..levels.addAll(owned);
      s.startDay();
      tick(s, 2);
      s.pause();
      final saved = s.snapshot();
      tick(s, 3);
      expect(s.snapshot(), saved);
      s.resume();
      tick(s, .5);
      expect(s.board!.launcher.shots, 1);
      s.setBackgrounded(true);
      final background = s.snapshot();
      tick(s, 3);
      expect(s.snapshot(), background);
      s.setBackgrounded(false);
      s.resume();
      tick(s, 12.6);
      expect(s.running, isFalse);
      final pose = s.snapshot();
      tick(s, 1);
      expect(s.snapshot(), pose);
      s.dispose();
    },
  );

  test(
    'interrupted days restore pose, clock and RNG without duplicate shots',
    () {
      final s = GameSession(catalog, MemoryStore())..levels.addAll(owned);
      s.startDay();
      s.board!.launcher.move(const Vec(90, 490), math.pi * 1.5);
      tick(s, 3);
      final restored = GameSession(catalog, MemoryStore())
        ..restore(s.snapshot());
      expect(restored.paused, isTrue);
      expect(restored.board!.launcher.toJson(), s.board!.launcher.toJson());
      restored.resume();
      tick(s, 2);
      tick(restored, 2);
      expect(restored.board!.launcher.toJson(), s.board!.launcher.toJson());
      expect(restored.board!.toJson(), s.board!.toJson());
      s.dispose();
      restored.dispose();
    },
  );

  test(
    'pose and purchases persist across days and app restarts; earlier saves use default pose',
    () {
      final s = GameSession(catalog, MemoryStore())..levels.addAll(owned);
      s.startDay();
      s.board!.launcher.move(const Vec(100, 490), math.pi * 1.5);
      s.finishDay();
      final restored = GameSession(catalog, MemoryStore())
        ..restore(s.snapshot());
      expect(restored.levels, owned);
      restored.startDay();
      expect(restored.board!.launcher.position.toJson(), [100, 490]);
      expect(restored.board!.launcher.angle, math.pi * 1.5);
      restored.finishDay();
      final old = jsonDecode(restored.snapshot()) as Map<String, dynamic>;
      old.remove('launcherPose');
      restored.restore(jsonEncode(old));
      restored.startDay();
      expect(restored.board!.launcher.position.toJson(), [285, 510]);
      s.dispose();
      restored.dispose();
    },
  );

  test(
    'releasing the launcher checkpoints its final pose without waiting for the next autosave',
    () async {
      final store = MemoryStore();
      final s = GameSession(catalog, store)..levels.addAll(owned);
      s.startDay();
      s.touch(s.board!.launcher.position);
      s.drag(const Vec(100, 490));
      tick(s, .3);
      final finalPose = s.board!.launcher.position.toJson();
      s.release();
      await s.pendingWrites;
      final restored = GameSession(catalog, MemoryStore())
        ..restore(store.writes.last);
      expect(restored.board!.launcher.position.toJson(), finalPose);
      s.dispose();
      restored.dispose();
    },
  );

  test('v12 in-progress saves retain old settings until the next day', () {
    final s = GameSession(catalog, MemoryStore())..startDay();
    final data = jsonDecode(s.snapshot()) as Map<String, dynamic>;
    data['version'] = 7;
    data.remove('feeding');
    data['run']['remaining'] += 5;
    data['run']['balanceVersion'] = 12;
    data['run']['settings'] = catalog.settings({}, balanceVersion: 12).toJson();
    (data['run']['board'] as Map).remove('launcher');
    data.remove('launcherPose');
    s.restore(jsonEncode(data));
    expect(s.board!.settings.balanceVersion, 12);
    expect(s.board!.launcher.unlocked, isFalse);
    s.finishDay();
    s.startDay();
    expect(s.board!.settings.balanceVersion, 18);
    s.dispose();
  });

  test(
    'invalid launcher and persistent poses reject restoration atomically',
    () {
      final s = GameSession(catalog, MemoryStore())..levels.addAll(owned);
      s.startDay();
      final saved = s.snapshot();
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (data) => data['launcherPose']['position'] = [10, 10],
        (data) => data['launcherPose']['angle'] = -1,
        (data) => data['run']['board']['launcher']['position'] = [200, 400],
        (data) => data['run']['board']['launcher']['clock'] = -1,
        (data) => data['run']['board']['launcher']['velocity'] = [100, 0],
        (data) => data['run']['board']['launcher']['shots'] = 1,
        (data) => data['run']['board']['launcher']['pressure'] = [100000, 0],
      ]) {
        final data = jsonDecode(saved) as Map<String, dynamic>;
        mutate(data);
        expect(() => s.restore(jsonEncode(data)), throwsA(isA<Object>()));
        expect(s.snapshot(), saved);
      }
      s.dispose();
    },
  );

  test(
    'DEBUG launcher and pose experiments never overwrite normal progress',
    () async {
      final store = MemoryStore();
      final s = GameSession(catalog, store)..economy.balance = 80;
      final baseline = s.snapshot();
      s.enterDebug();
      await s.pendingWrites;
      final writes = store.writes.length;
      expect(s.debugPurchase('launcher_rate', 3), isTrue);
      expect(s.levels['generator'], greaterThanOrEqualTo(2));
      s.startDay();
      s.board!.launcher.move(const Vec(90, 500), math.pi);
      tick(s, 3);
      await s.save();
      expect(store.writes.length, writes);
      s.exitDebug();
      expect(s.snapshot(), baseline);
      s.dispose();
    },
  );

  test(
    'configuration prevents a threshold weak enough for three contacts or invalid geometry',
    () {
      final csv = File('docs/balance.csv').readAsStringSync();
      for (final pair in [
        ('launcher_pressure_threshold,400', 'launcher_pressure_threshold,360'),
        ('launcher_speed,280', 'launcher_speed,400'),
        ('launcher_body_radius,18', 'launcher_body_radius,80'),
        ('launcher_interval,2.4', 'launcher_interval,0.001'),
      ]) {
        final invalid = csv.replaceFirst(pair.$1, pair.$2);
        expect(() => UpgradeCatalog.fromCsv(invalid), throwsFormatException);
      }
    },
  );

  testWidgets(
    'shot feedback respects silence and never replays restored shots',
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
      final b = board();
      final feedback = LauncherFeedback();
      feedback.sync(b, sound: true, playing: true);
      advance(b, 2.4);
      feedback.sync(b, sound: true, playing: true);
      feedback.sync(b, sound: true, playing: true);
      await tester.pump();
      expect(calls.where((c) => c.method == 'SystemSound.play'), hasLength(1));
      advance(b, 2.4);
      feedback.sync(b, sound: false, playing: true);
      feedback.sync(b, sound: true, playing: true);
      final restored = Board.fromJson(
        b.settings,
        jsonDecode(jsonEncode(b.toJson())) as Map<String, dynamic>,
      );
      feedback.sync(restored, sound: true, playing: true);
      await tester.pump();
      expect(calls.where((c) => c.method == 'SystemSound.play'), hasLength(1));
    },
  );

  test(
    'launcher boundary and shot rendering do not advance the physical state',
    () async {
      final s = GameSession(catalog, MemoryStore())..levels.addAll(owned);
      s.startDay();
      final b = s.board!;
      b.launcher.move(const Vec(0, 0), math.pi * 1.5);
      final game = GardenGame(s)..onGameResize(Vector2(360, 560));
      final before = s.snapshot();
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      final picture = recorder.endRecording();
      final image = await picture.toImage(360, 560);
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final pixel = (420 * 360 + 180) * 4;
      expect(bytes.getUint8(pixel), greaterThan(150));
      expect(bytes.getUint8(pixel + 1), lessThan(100));
      expect(s.snapshot(), before);
      image.dispose();
      picture.dispose();
      s.dispose();
    },
  );

  testWidgets(
    'launcher can be bought in small-screen DEBUG and used through real two-finger input',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = GameSession(catalog, MemoryStore());
      s.enterDebug();
      s.debugPurchase('launcher', 1);
      s.startDay();
      await tester.pumpWidget(GardenApp(session: s));
      await tester.pump();
      expect(s.board!.launcher.unlocked, isTrue);
      final finder = find.byWidgetPredicate((w) => w is GameWidget);
      final game = tester.widget<GameWidget>(finder).game as GardenGame;
      Offset point(Vec value) =>
          tester.getTopLeft(finder) +
          game.origin +
          Offset(value.x, value.y) * game.scale;
      final b = s.board!;
      b.launcher.move(const Vec(180, 490), 0);
      final first = await tester.startGesture(
        point(b.launcher.handles.first),
        pointer: 1,
      );
      final second = await tester.startGesture(
        point(b.launcher.handles.last),
        pointer: 2,
      );
      expect(b.holdingLauncher, isTrue);
      expect(b.hasSecondBroomPoint, isTrue);
      await second.moveTo(point(b.target! + const Vec(0, -48)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(b.launcher.angle, greaterThan(math.pi));
      final angle = b.launcher.angle;
      await first.up();
      expect(b.holdingLauncher, isTrue);
      expect(b.hasSecondBroomPoint, isFalse);
      await second.moveBy(const Offset(15, 0));
      await tester.pump(const Duration(milliseconds: 100));
      expect(b.launcher.angle, angle);
      await second.up();
      expect(b.holdingLauncher, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
}
