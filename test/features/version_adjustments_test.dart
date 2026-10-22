import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/rewards/domain/reward_delivery.dart';
import '../test_support.dart';
import 'package:incremental_hole_game/features/upgrades/domain/catalog.dart';

void main() {
  final catalog = testCatalog();
  test(
    'AJ001: six-ball capacity remains reliable through repeated fast direction changes',
    () {
      final b = Board(catalog.settings({'hand': 5}));
      b.balls.add(Ball(b.nextId++, const Vec(180, 230), Vec.zero));
      for (var i = 0; i < 5; i++) {
        final a = i * math.pi * 2 / 5;
        b.balls.add(
          Ball(
            b.nextId++,
            Vec(180 + math.cos(a) * 24, 230 + math.sin(a) * 24),
            Vec.zero,
          ),
        );
      }
      b.touch(b.balls.first.position);
      for (var i = 0; i < 120; i++) {
        b.update(1 / 60, producing: false);
      }
      expect(b.heldBalls.length, 6);
      for (var i = 0; i < 12; i++) {
        b.drag(i.isEven ? const Vec(60, 130) : const Vec(300, 310));
        for (var j = 0; j < 60; j++) {
          b.update(1 / 60, producing: false);
        }
        expect(b.heldBalls.length, 6);
      }
      expect(
        b.balls.every((ball) => ball.velocity.length <= 380.000001),
        isTrue,
      );
    },
  );
  test(
    'AJ001: retired strength cannot be bought even through its legacy definition',
    () {
      final s = GameSession(catalog, MemoryStore())
        ..economy.balance = 1000
        ..levels['hand'] = 1;
      expect(
        s.purchase(UpgradeCatalog.retiredDefinition('hand_grip')!),
        isFalse,
      );
      expect(s.economy.balance, 1000);
      expect(s.levels, {'hand': 1});
      s.enterDebug();
      expect(s.debugPurchase('hand_grip', 1), isFalse);
      s.exitDebug();
      s.dispose();
    },
  );
  test(
    'AJ004: visible hole origin, real capture and all reward origins share the configurable position',
    () async {
      final s = GameSession(catalog, MemoryStore())..startDay();
      expect(s.board!.holePosition.toJson(), [180.0, 123.2]);
      expect(
        (Board.generator - s.board!.holePosition).length,
        greaterThan(s.board!.captureRadius + 37),
      );
      s.board!.balls.add(
        Ball(s.board!.nextId++, s.board!.holePosition, Vec.zero, golden: true),
      );
      s.tick(1 / 60);
      expect(s.economy.generated, 10);
      expect(s.board!.captured, 1);
      expect(
        s.board!.starBubbles!.bodies.single.position.toJson(),
        s.board!.holePosition.toJson(),
      );
      final coin = RewardCoin()..reset(1, 10);
      expect(coin.y(28, 1, origin: s.board!.holePosition.y), 123.2);
      coin.age = 1 + coin.jump + RewardDelivery.hold + coin.flight;
      expect(coin.y(28, 1, origin: 420), closeTo(28, 1e-8));
      final r = GameSession(catalog, MemoryStore())..restore(s.snapshot());
      expect(r.board!.holePosition.toJson(), s.board!.holePosition.toJson());
      expect(r.meta.starLedger.pending.length, 1);
      final before = jsonDecode(r.snapshot());
      r.tick(.1);
      expect(jsonDecode(r.snapshot()), before);
      await s.pendingWrites;
      await r.pendingWrites;
      s.dispose();
      r.dispose();
    },
  );
  test(
    'AJ004: adjusting the balance moves capture rather than only painting it',
    () {
      final c = testCatalog();
      c.base['hole_y_ratio'] = .6;
      final b = Board(c.settings({}));
      expect(b.holePosition.y, 336);
      b.balls.add(Ball(b.nextId++, Board.hole, Vec.zero));
      b.update(1 / 240, producing: false);
      expect(b.captured, 0);
      b.balls.single.position = b.holePosition;
      b.update(1 / 240, producing: false);
      expect(b.captured, 1);
    },
  );
  testWidgets(
    'AJ003: wallet contains only the coin icon and amount without a decorated panel',
    (tester) async {
      final s = GameSession(catalog, MemoryStore())..startDay();
      await tester.pumpWidget(GardenApp(session: s));
      await tester.pump();
      final wallet = find.byKey(const ValueKey('gameplay-balance'));
      expect(wallet, findsOneWidget);
      final containers = tester.widgetList<Container>(
        find.ancestor(of: wallet, matching: find.byType(Container)),
      );
      expect(containers.where((c) => c.decoration != null), isEmpty);
      expect(
        find.descendant(of: wallet, matching: find.text('0')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await s.pendingWrites;
      s.dispose();
    },
  );
}
