import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/special_abilities.dart';
import 'package:incremental_hole_game/features/prestige/domain/meta_progress.dart';
import 'package:incremental_hole_game/features/prestige/domain/star_rewards.dart';
import 'package:incremental_hole_game/features/prestige/domain/star_bubbles.dart';
import '../test_support.dart';

void main() {
  final catalog = testCatalog();
  final config = StarConfig(catalog.base);
  GameSession session([MemoryStore? store]) =>
      GameSession(catalog, store ?? MemoryStore(), eventSeed: 42);
  StarBubbles system({StarConfig? settings, int quotas = 1}) {
    final c = settings ?? config;
    var ledger = const StarLedger();
    for (var i = 1; i <= quotas; i++) {
      ledger = ledger.award(i, c);
    }
    return StarBubbles(c, ballRadius: 6)
      ..sync(ledger)
      ..populate(0);
  }

  Future<void> complete(GameSession s) async {
    s.startDay();
    s.board!.balls.add(
      Ball(s.board!.nextId++, Board.hole, Vec.zero, golden: true),
    );
    s.tick(1 / 60);
    await s.pendingWrites;
  }

  void smash(GameSession s) {
    final b = s.board!.starBubbles!.bodies.first;
    b.position = const Vec(13, 230);
    b.velocity = const Vec(-300, 0);
    s.tick(1 / 60);
  }

  test(
    'quota produces an immediate identifiable pending reward once, not paid stars',
    () async {
      final s = session();
      await complete(s);
      expect(s.meta.starLedger.pending.length, 1);
      expect(s.board!.starBubbles!.bodies.length, 1);
      expect(
        s.board!.starBubbles!.bodies.single.position.y,
        greaterThanOrEqualTo(50),
      );
      final revision = s.meta.revision;
      s.tick(.1);
      expect(s.meta.revision, revision);
      expect(s.meta.stars, 0);
      expect(s.feeding.points, 10);
      expect(s.economy.generated, 10);
      s.dispose();
    },
  );
  test('sizes are physical 2x ball diameter with moderate category growth', () {
    final p = system();
    expect(p.radius(p.bodies.single), 12);
    expect(config.radius(6, 1) / config.radius(6, 0), closeTo(1.12, 1e-9));
    expect(config.category(1), 0);
    expect(config.category(3), 1);
    expect(config.category(100), 2);
    expect(config.value(2), 25);
  });
  test('successive expulsions spread directions instead of sharing a path', () {
    final p = system(quotas: 2);
    final first = p.bodies.single;
    first.position = const Vec(80, 250);
    p.populate(1);
    expect(first.velocity.x, lessThan(0));
    expect(p.bodies.last.velocity.x, greaterThan(0));
    expect(first.velocity.y, greaterThan(0));
    expect(p.bodies.last.velocity.y, greaterThan(0));
  });
  test(
    'ledger quota and payment are idempotent with multiple bubble values',
    () {
      final c = config.changed('star_count', 3);
      final a = const StarLedger().award(3, c);
      expect(identical(a.award(3, c), a), isTrue);
      expect(a.pending.length, 3);
      final paid = a.redeem([1, 1, 2, 999]);
      expect(paid.paid, 10);
      expect(paid.ledger.redeem([1, 2]).paid, 0);
      expect(paid.ledger.pending.single.value, 5);
    },
  );
  test(
    'soft wall impacts bounce and strong corner impact breaks only once',
    () {
      final p = system();
      final b = p.bodies.single;
      b.position = const Vec(11, 220);
      b.velocity = const Vec(-30, 0);
      p.integrate(b, 1 / 240, Vec.zero);
      expect(p.bodies, hasLength(1));
      expect(b.velocity.x, greaterThan(0));
      b.position = const Vec(11, 11);
      b.velocity = const Vec(-300, -200);
      p.integrate(b, 1 / 240, Vec.zero);
      expect(p.bodies, isEmpty);
      expect(p.broken, [1]);
      expect(p.impact(b, Vec.zero, 300, b.position), isFalse);
      expect(p.breakSerial, 1);
    },
  );
  test('resting contact does not break or manufacture impulses', () {
    final p = system();
    final b = p.bodies.single
      ..position = const Vec(12, 220)
      ..velocity = Vec.zero;
    for (var i = 0; i < 1000; i++) {
      p.integrate(b, 1 / 240, Vec.zero);
    }
    expect(p.broken, isEmpty);
    expect(b.velocity.length, lessThan(50));
    expect(b.position.x, 12);
  });
  test(
    'hole ejects original identity/value with a reentry cooldown and no ball events',
    () {
      final p = system();
      final b = p.bodies.single;
      b.position = Board.hole;
      b.velocity = Vec.zero;
      b.holeCooldown = 0;
      p.integrate(b, 1 / 240, Vec.zero);
      expect(b.reward.id, 1);
      expect(b.reward.value, 1);
      expect(b.holeCooldown, .8);
      p.integrate(b, 1 / 240, Vec.zero);
      expect(b.holeCooldown, lessThan(.8));
      final board = Board(catalog.settings({}))..starBubbles = p;
      final events = board.update(1 / 60, producing: true);
      expect(events.captured, 0);
      expect(events.normalFood, 0);
      expect(events.rewards, isEmpty);
      expect(board.spawned, 0);
      expect(board.combo.streak, 0);
    },
  );
  test(
    'grab takes precedence over overlapping ordinary ball, throws with gesture speed',
    () {
      final board = Board(catalog.settings({}))..starBubbles = system();
      final b = board.starBubbles!.bodies.single
        ..position = const Vec(150, 230);
      board.balls.add(Ball(board.nextId++, b.position, Vec.zero));
      board.touch(b.position, time: 0);
      expect(board.starBubbles!.held, b);
      expect(board.heldBalls, isEmpty);
      expect(board.grabSecondBroomPoint(const Vec(180, 230)), isFalse);
      board.drag(const Vec(180, 230), time: .05);
      board.update(.05, producing: true);
      board.releasePointer(time: .06);
      expect(board.starBubbles!.held, isNull);
      expect(b.velocity.x, greaterThan(200));
      expect(b.velocity.length, lessThanOrEqualTo(380));
      expect(board.starBubbles!.broken, isEmpty);
    },
  );
  test(
    'dragging held bubble into wall can break it, grabbing alone cannot',
    () {
      final board = Board(catalog.settings({}))..starBubbles = system();
      final b = board.starBubbles!.bodies.single..position = const Vec(25, 230);
      board.touch(b.position, time: 0);
      expect(board.starBubbles!.broken, isEmpty);
      board.drag(const Vec(0, 230), time: .03);
      board.update(.06, producing: true);
      expect(board.starBubbles!.broken, [1]);
      expect(board.heldBalls, isEmpty);
      board.releasePointer();
    },
  );
  test(
    'ball pushes bubble without directly breaking or activating normal rewards',
    () {
      final board = Board(catalog.settings({}))..starBubbles = system();
      final b = board.starBubbles!.bodies.single
        ..position = const Vec(170, 250)
        ..velocity = Vec.zero;
      board.balls.add(
        Ball(board.nextId++, const Vec(153, 250), const Vec(250, 0)),
      );
      final events = board.update(1 / 240, producing: true);
      expect(b.velocity.x, greaterThan(150));
      expect(board.starBubbles!.broken, isEmpty);
      expect(events.rewards, isEmpty);
      expect(board.spawned, 0);
    },
  );
  for (final kind in ['bat', 'broom']) {
    test(
      'strong relative impact against stationary $kind breaks bubble, soft impact bounces',
      () {
        final board = Board(
          catalog.settings(
            kind == 'bat' ? {'bat': 1, 'hand': 1} : {'broom': 1, 'hand': 1},
          ),
        )..starBubbles = system();
        if (kind == 'broom') {
          board.broomPosition = const Vec(180, 300);
          board.toolAngle = 0;
        } else {
          board.batPosition = const Vec(180, 300);
          board.batAngle = 0;
        }
        final b = board.starBubbles!.bodies.single;
        b.position = const Vec(180, 279);
        b.velocity = const Vec(0, 25);
        for (var i = 0; i < 30; i++) {
          board.update(1 / 240, producing: true);
        }
        expect(board.starBubbles!.broken, isEmpty);
        b.position = const Vec(180, 279);
        b.velocity = const Vec(0, 300);
        for (var i = 0; i < 15; i++) {
          board.update(1 / 240, producing: true);
        }
        expect(board.starBubbles!.broken, [1]);
      },
    );
  }
  test(
    'payment is permanent before flight ends and reload cannot respawn or repay it',
    () async {
      final store = MemoryStore(), s = session();
      await complete(s);
      smash(s);
      expect(s.meta.stars, 1);
      expect(s.meta.starLedger.pending, isEmpty);
      expect(
        s.board!.starBubbles!.flights.where((f) => f.active),
        hasLength(1),
      );
      final raw = s.snapshot();
      store.candidates = [raw];
      final r = session(store);
      await r.load();
      expect(r.meta.stars, 1);
      expect(r.board!.starBubbles!.bodies, isEmpty);
      r.resume();
      r.tick(.1);
      expect(r.meta.stars, 1);
      expect(r.meta.starLedger.pending, isEmpty);
      await s.pendingWrites;
      await r.pendingWrites;
      s.dispose();
      r.dispose();
    },
  );
  test(
    'pending body position/velocity and ledger survive interruption and pause',
    () async {
      final s = session();
      await complete(s);
      final b = s.board!.starBubbles!.bodies.single;
      b.position = const Vec(130, 250);
      b.velocity = const Vec(30, 10);
      final r = session()..restore(s.snapshot());
      expect(r.paused, isTrue);
      final before = r.snapshot();
      r.tick(.1);
      expect(r.snapshot(), before);
      expect(r.board!.starBubbles!.bodies.single.position.toJson(), [
        130.0,
        250.0,
      ]);
      expect(r.board!.starBubbles!.bodies.single.velocity.toJson(), [
        30.0,
        10.0,
      ]);
      r.resume();
      r.tick(1 / 60);
      expect(r.meta.starLedger.pending, hasLength(1));
      expect(r.meta.stars, 0);
      s.dispose();
      r.dispose();
    },
  );
  test(
    'pending reward reexpels next day; broken reward never returns',
    () async {
      final s = session();
      await complete(s);
      final reward = s.meta.starLedger.pending.single;
      s.finishDay();
      await s.pendingWrites;
      expect(s.meta.starLedger.pending.single.id, reward.id);
      s.startDay();
      expect(
        s.board!.starBubbles!.bodies.single.position.toJson(),
        Board.hole.toJson(),
      );
      smash(s);
      s.finishDay();
      await s.pendingWrites;
      s.startDay();
      expect(s.meta.stars, 1);
      expect(s.board!.starBubbles!.bodies, isEmpty);
      s.dispose();
    },
  );
  test(
    'defeat discards pending bubbles but preserves stars already earned',
    () async {
      final c = testCatalog();
      c.base['star_count'] = 2;
      final s = GameSession(c, MemoryStore(), eventSeed: 42);
      await complete(s);
      smash(s);
      await s.pendingWrites;
      expect(s.meta.starLedger.pending, hasLength(1));
      // First quota satisfied; second period deliberately fails.
      s.finishDay();
      await s.pendingWrites;
      for (var i = 0; i < 4; i++) {
        s.startDay();
        s.finishDay();
        await s.pendingWrites;
      }
      s.startDay();
      s.board!.balls.add(Ball(s.board!.nextId++, Board.hole, Vec.zero));
      s.tick(1 / 60);
      s.finishDay();
      await s.pendingWrites;
      // A pending reward can also be present when voluntary prestige ends the run.
      for (var i = 0; i < 4; i++) {
        s.startDay();
        s.finishDay();
        await s.pendingWrites;
      }
      expect(s.meta.phase, PrestigePhase.defeat);
      expect(s.meta.stars, 1);
      expect(s.meta.starLedger.pending, isEmpty);
      s.continueToPrestigeShop();
      await s.pendingWrites;
      s.beginNewRun();
      await s.pendingWrites;
      expect(s.meta.stars, 1);
      expect(s.meta.starLedger.quota, 0);
      s.dispose();
    },
  );
  test(
    'voluntary prestige loses genuine pending reward without auto-crediting',
    () async {
      final s = session();
      await complete(s);
      s.finishDay();
      await s.pendingWrites;
      s.levels.addAll({'generator': 5, 'reward': 5, 'duration': 5});
      s.economy.balance = 10000;
      expect(
        s.purchase(
          catalog.definitions.firstWhere((d) => d.id == 'prestige'),
          confirmPrestige: true,
        ),
        isTrue,
      );
      expect(s.meta.phase, PrestigePhase.shop);
      expect(s.meta.starLedger.pending, isEmpty);
      expect(s.meta.stars, 0);
      await s.pendingWrites;
      s.dispose();
    },
  );
  test(
    'physical cap defers all remaining rewards and reintroduces them progressively',
    () {
      final c = config.changed('star_active_limit', 2);
      final p = system(settings: c, quotas: 30);
      p.bodies.single.position = const Vec(80, 250);
      p.populate(1);
      expect(p.bodies, hasLength(2));
      expect(p.ledger.pending, hasLength(30));
      for (var i = 0; i < 100; i++) {
        p.populate(1);
      }
      expect(p.bodies, hasLength(2));
      final b = p.bodies.first;
      p.impact(b, Vec.zero, 200, b.position);
      p.sync(p.ledger.redeem(p.broken).ledger);
      p.broken.clear();
      p.bodies.single.position = const Vec(240, 250);
      p.populate(1);
      expect(p.bodies, hasLength(2));
      expect(p.bodies.last.reward.id, 3);
      expect(p.ledger.pending, hasLength(29));
    },
  );
  test('bounded burst pool can omit visuals without dropping star values', () {
    final p = system(quotas: 100);
    var paid = 0;
    for (var i = 0; i < 100; i++) {
      p.entryClock = 0;
      p.populate(0);
      final b = p.bodies.first;
      p.impact(b, Vec.zero, 300, b.position);
      final tx = p.ledger.redeem(p.broken);
      paid += tx.paid;
      p.sync(tx.ledger);
      p.broken.clear();
    }
    expect(p.ledger.pending, isEmpty);
    expect(p.flights.where((f) => f.active), hasLength(24));
    expect(paid, greaterThan(100));
    p.advanceVisuals(1);
    expect(p.flights.any((f) => f.active), isFalse);
  });
  test('bubbles freeze on closing and capture-all never captures them', () {
    final board = Board(catalog.settings({'capture_all': 1}))
      ..starBubbles = system();
    board.specials.advance(20);
    board.activateSpecial(SpecialAbility.captureAll);
    board.update(1 / 60, producing: true);
    expect(board.starBubbles!.bodies, hasLength(1));
    expect(board.captured, 0);
    board.enterClosing();
    final before = jsonEncode(board.starBubbles!.toJson());
    board.update(1, producing: false);
    expect(jsonEncode(board.starBubbles!.toJson()), before);
  });
  test(
    'invalid identity/config/velocity restore rejects without partial session mutation',
    () async {
      final s = session();
      await complete(s);
      final raw = s.snapshot();
      for (final change in <void Function(dynamic)>[
        (j) => j['run']['starBubbles']['bodies'][0]['id'] = 999,
        (j) => j['run']['starBubbles']['bodies'][0]['v'] = [1000, 0],
        (j) => j['run']['starBubbles']['config']['star_active_limit'] = 1000,
        (j) => j['meta']['starLedger']['pending'].add(
          j['meta']['starLedger']['pending'][0],
        ),
      ]) {
        final j = jsonDecode(raw);
        change(j);
        expect(() => s.restore(jsonEncode(j)), throwsA(anything));
        expect(s.snapshot(), raw);
      }
      s.dispose();
    },
  );
  test(
    'DEBUG parameters/rewards/collections never alter normal save or stars',
    () async {
      final store = MemoryStore();
      final s = session(store);
      await s.save();
      final original = s.snapshot();
      s.enterDebug();
      s.debugSetStarParameter('star_count', 3);
      s.debugSetStarParameter('star_value', 7);
      s.debugAwardStarBubbles();
      s.startDay();
      smash(s);
      await s.pendingWrites;
      expect(s.meta.stars, 7);
      expect(s.meta.starLedger.pending.length, 2);
      s.exitDebug();
      expect(s.snapshot(), original);
      expect(store.candidates.first, original);
      expect(s.starConfig['star_count'], 1);
      s.dispose();
    },
  );
  test(
    'durable star checkpoint overrides both stale normal saves after a break',
    () async {
      final store = MemoryStore();
      final s = session(store);
      await complete(s);
      final beforeBreak = s.snapshot();
      smash(s);
      await s.pendingWrites;
      expect(store.prestigeCandidates, hasLength(2));
      store.candidates = [beforeBreak, beforeBreak];
      final r = session(store);
      await r.load();
      expect(r.meta.stars, 1);
      expect(r.meta.starLedger.pending, isEmpty);
      expect(r.board!.starBubbles!.bodies, isEmpty);
      expect(() => r.restore(beforeBreak), throwsFormatException);
      s.dispose();
      r.dispose();
    },
  );
  test(
    'star receipt remains in memory after disk failure and retry persists it once',
    () async {
      final store = MemoryStore();
      final s = session(store);
      await complete(s);
      store.fail = true;
      smash(s);
      await s.pendingWrites;
      expect(s.meta.stars, 1);
      expect(s.saveError, isNotNull);
      expect(s.prestigeReady, isFalse);
      store.fail = false;
      await s.save();
      final r = session(store);
      await r.load();
      expect(r.meta.stars, 1);
      expect(r.meta.starLedger.pending, isEmpty);
      s.dispose();
      r.dispose();
    },
  );
  test(
    'experimental sensor and suction are opt-in and never override held bubbles',
    () {
      for (final experiment in ['none', 'gravity', 'blackHole']) {
        final board = Board(
          catalog.settings({}),
          gravitySupported: true,
          forceGravity: true,
          forcedBlackHoles: 1,
        )..starBubbles = system();
        final b = board.starBubbles!.bodies.single
          ..position = Board.hole + const Vec(-80, -100)
          ..velocity = Vec.zero;
        board.gravityTilt = const Vec(.7, 0);
        for (var i = 0; i < 6; i++) {
          board.gravity.hit(available: true);
        }
        for (var i = 0; i < 6; i++) {
          board.blackHole.hit(1);
        }
        board.bubbleGravity = experiment == 'gravity';
        board.bubbleBlackHole = experiment == 'blackHole';
        board.update(.1, producing: true);
        expect(b.velocity.x, experiment == 'none' ? 0 : greaterThan(0));
        board.touch(b.position, time: 1);
        final p = b.position;
        board.update(.1, producing: true);
        expect(b.position.toJson(), p.toJson());
      }
    },
  );
  test('moving bat surface breaks an otherwise stationary bubble', () {
    final board = Board(catalog.settings({'bat': 1, 'hand': 1}))
      ..starBubbles = system();
    board.batPosition = const Vec(180, 300);
    board.batAngle = 0;
    board.starBubbles!.bodies.single
      ..position = const Vec(180, 260)
      ..velocity = Vec.zero;
    board.touch(const Vec(180, 300), time: 0);
    board.drag(const Vec(180, 210), time: .08);
    board.update(.1, producing: true);
    expect(board.starBubbles!.broken, [1]);
    expect(board.heldBalls, isEmpty);
  });
  test('pure bat rotation contributes contact speed at its tip', () {
    final p = system(settings: config.changed('star_break_speed', 80));
    final board = Board(catalog.settings({'bat': 1, 'hand': 1}))
      ..starBubbles = p;
    board.batPosition = const Vec(180, 300);
    board.batAngle = 0;
    p.bodies.single
      ..position = const Vec(210, 279)
      ..velocity = Vec.zero;
    board.touch(const Vec(144, 300), time: 0);
    expect(board.grabSecondBroomPoint(const Vec(216, 300)), isTrue);
    board.drag(const Vec(144, 320), time: .05);
    board.dragSecondBroomPoint(const Vec(216, 280));
    board.update(.1, producing: true);
    expect(board.batPosition.toJson(), [180.0, 300.0]);
    expect(p.broken, [1]);
  });
  test(
    'physical population stays bounded with 200 balls and 100 pending rewards',
    () {
      final c = config.changed('star_active_limit', 24);
      final p = system(settings: c, quotas: 100);
      final board = Board(catalog.settings({'walls': 3, 'hand': 1}))
        ..starBubbles = p;
      p.bodies.clear();
      for (var i = 0; i < 24; i++) {
        p.bodies.add(
          StarBubble(
            p.ledger.pending[i],
            Vec(35 + 55.0 * (i % 6), 100 + 90.0 * (i ~/ 6)),
            const Vec(50, -20),
          ),
        );
      }
      expect(p.bodies.length, 24);
      final total = p.ledger.pending.fold<int>(0, (int n, r) => n + r.value);
      var paid = 0;

      for (var i = 0; i < 200; i++) {
        board.balls.add(
          Ball(
            board.nextId++,
            Vec(12 + (i % 16) * 21.0, 120 + (i ~/ 16) * 23.0),
            Vec(i.isEven ? 300 : -300, -120),
          ),
        );
      }
      for (var i = 0; i < 180; i++) {
        board.update(1 / 60, producing: false);
        final tx = p.ledger.redeem(p.broken);
        paid += tx.paid;
        expect(
          paid + tx.ledger.pending.fold<int>(0, (int n, r) => n + r.value),
          total,
        );
        p.sync(tx.ledger);
        p.broken.clear();
        p.populate(1 / 60);
        expect(p.bodies.length, lessThanOrEqualTo(24));
        expect(p.flights.length, 24);
        for (final b in p.bodies) {
          expect(b.position.x.isFinite && b.position.y.isFinite, isTrue);
          expect(b.velocity.length, lessThanOrEqualTo(380.000001));
        }
        for (final b in board.balls) {
          expect(b.velocity.length, lessThanOrEqualTo(380.000001));
        }
      }
    },
  );
  test(
    'launcher body separates embedded bubbles outwards without changing its orientation',
    () {
      final board = Board(catalog.settings({'launcher': 1, 'generator': 2}))
        ..starBubbles = system();
      final b = board.starBubbles!.bodies.single
        ..position = board.launcher.position + const Vec(1, 0)
        ..velocity = Vec.zero;
      final angle = board.launcher.angle;
      board.update(1 / 240, producing: false);
      expect(
        (b.position - board.launcher.position).length,
        greaterThanOrEqualTo(
          board.launcher.bodyRadius + board.starBubbles!.radius(b) - .01,
        ),
      );
      expect(board.launcher.angle, angle);
      expect(board.starBubbles!.broken, isEmpty);
    },
  );
  testWidgets(
    'small-screen DEBUG edits configuration and forces pending bubbles',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = session();
      await tester.pumpWidget(GardenApp(session: s));
      await tester.scrollUntilVisible(find.text('Tienda'), 150);
      await tester.tap(find.text('Tienda'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tree-debug-tools')));
      await tester.pumpAndSettle();
      final tile = find.byKey(const ValueKey('debug-star-tools'));
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('debug-star_count'));
      await tester.ensureVisible(field);
      await tester.enterText(field, '3');
      await tester.pump();
      expect(s.starConfig['star_count'], 3);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      final award = find.byKey(const ValueKey('debug-star-award'));
      await tester.ensureVisible(award);
      await tester.tap(award);
      await tester.pumpAndSettle();
      expect(s.meta.starLedger.pending.length, 3);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await s.pendingWrites;
      s.dispose();
    },
  );
  for (final sound in [false, true]) {
    testWidgets(
      'bubble break batch respects sound=$sound and does not play for every star',
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
        final c = testCatalog();
        c.base['star_count'] = 3;
        final s = GameSession(c, MemoryStore(), eventSeed: 42)..setSound(sound);
        await complete(s);
        await tester.pumpWidget(GardenApp(session: s));
        await tester.pump();
        calls.clear();
        final system = s.board!.starBubbles!;
        system.bodies.clear();
        for (var i = 0; i < 3; i++) {
          system.bodies.add(
            StarBubble(
              s.meta.starLedger.pending[i],
              Vec(13, 230 + 40.0 * i),
              const Vec(-300, 0),
            ),
          );
        }
        s.tick(1 / 60);
        await tester.pump();
        expect(s.meta.stars, 3);
        expect(
          calls.where((c) => c.method == 'SystemSound.play'),
          hasLength(sound ? 1 : 0),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await s.pendingWrites;
        s.dispose();
      },
    );
  }
  testWidgets(
    'prestige counter appears inside gameplay alongside normal wallet',
    (tester) async {
      final s = session();
      s.startDay();
      await tester.pumpWidget(GardenApp(session: s));
      await tester.pump();
      expect(find.byKey(const ValueKey('gameplay-stars')), findsOneWidget);
      expect(find.byKey(const ValueKey('gameplay-balance')), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await s.pendingWrites;
      s.dispose();
    },
  );
}
