import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/upgrades/domain/skill_tree.dart';
import '../test_support.dart';

void main() {
  final catalog = testCatalog();
  Board grip() {
    final board = Board(catalog.settings({'hand': 1}));
    board.balls.addAll([
      Ball(board.nextId++, const Vec(80, 250), Vec.zero),
      Ball(board.nextId++, const Vec(110, 250), Vec.zero),
    ]);
    board.touch(board.balls.first.position);
    return board;
  }

  void advance(Board board, int frames, {int hz = 240}) {
    for (var i = 0; i < frames; i++) {
      board.update(1 / hz, producing: false);
    }
  }

  test(
    'fixed high grip follows smoothly, retains both balls during normal pulls and preserves capacity',
    () {
      final board = grip();
      final second = board.balls.last, initial = board.balls.last.position;
      expect(board.gripStrength, 4);
      advance(board, 1);
      expect((second.position - initial).length, lessThan(1));
      advance(board, 240);
      for (final point in [
        const Vec(250, 250),
        const Vec(40, 250),
        const Vec(290, 250),
      ]) {
        board.drag(point);
        advance(board, 180);
        expect(board.heldBalls, hasLength(2));
      }
      expect(board.handCapacity, 2);
      board.enterClosing();
      expect(board.heldBalls, isEmpty);
      expect(board.balls.every((b) => b.velocity.length == 0), isTrue);
    },
  );
  test(
    'fixed grip needs a manually held ball and never adds capacity or coin reach',
    () {
      final board = grip()..releasePointer(cancel: true);
      board.touch(const Vec(30, 200));
      advance(board, 240);
      expect(board.heldBalls, isEmpty);
      expect(board.handCapacity, 2);
      expect(board.settings['magnet_radius'], 0);
    },
  );
  test(
    'grip is reliable at 30, 60 and 120 fps without any strength purchase',
    () {
      Vec follow(int hz) {
        final board = grip();
        advance(board, hz, hz: hz);
        for (var i = 1; i <= hz; i++) {
          board.drag(Vec(80 + 70 * i / hz, 250));
          board.update(1 / hz, producing: false);
        }
        expect(board.heldBalls, hasLength(2));
        return board.balls.last.position;
      }

      final baseline = follow(60);
      expect((follow(30) - baseline).length, lessThan(3));
      expect((follow(120) - baseline).length, lessThan(3));
      expect(catalog.definitions.any((d) => d.id == 'hand_grip'), isFalse);
      expect(
        SkillTree(catalog).nodes.any((n) => n.definition.id == 'hand_grip'),
        isFalse,
      );
    },
  );
  test(
    'legacy strength purchases are refunded once and keep interrupted physics until the next day',
    () {
      final original = GameSession(catalog, MemoryStore())
        ..levels.addAll({'hand': 1, 'hand_grip': 2})
        ..economy.balance = 100
        ..startDay();
      original.board = Board(
        catalog.settings(original.levels, balanceVersion: 17),
      );
      final j = jsonDecode(original.snapshot()) as Map<String, dynamic>;
      j['version'] = 11;
      final restored = GameSession(catalog, MemoryStore())
        ..restore(jsonEncode(j));
      expect(restored.levels, {'hand': 1});
      expect(restored.economy.balance, 175);
      expect(restored.board!.gripStrength, 1.5);
      expect(restored.board!.holePosition.toJson(), [180.0, 50.0]);
      final reopened = GameSession(catalog, MemoryStore())
        ..restore(restored.snapshot());
      expect(reopened.economy.balance, 175);
      expect(reopened.board!.gripStrength, 1.5);
      reopened.finishDay();
      reopened.startDay();
      expect(reopened.board!.gripStrength, 4);
      expect(reopened.board!.handCapacity, 2);
      expect(reopened.board!.holePosition.toJson(), [180.0, 414.4]);
    },
  );

  test(
    'all node dependencies and routed segments use eight directions without passing through nodes',
    () {
      final tree = SkillTree(catalog);
      bool aligned(double x, double y) =>
          x == 0 || y == 0 || x.abs() == y.abs();
      for (final node in tree.nodes) {
        for (final id in node.parents) {
          final parent = tree.byId(id);
          expect(
            aligned(node.x - parent.x, node.y - parent.y),
            isTrue,
            reason: '$id → ${node.id}',
          );
          final points = tree.paths[(id, node.id)]!;
          expect(points.first, (parent.x, parent.y));
          expect(points.last, (node.x, node.y));
          for (var i = 1; i < points.length; i++) {
            final a = points[i - 1], b = points[i];
            final dx = b.$1 - a.$1, dy = b.$2 - a.$2;
            expect(aligned(dx, dy), isTrue);
            for (final other in tree.nodes.where(
              (n) => n.id != id && n.id != node.id,
            )) {
              final t =
                  (((other.x - a.$1) * dx + (other.y - a.$2) * dy) /
                          (dx * dx + dy * dy))
                      .clamp(0.0, 1.0);
              final distance = math.sqrt(
                math.pow(a.$1 + dx * t - other.x, 2) +
                    math.pow(a.$2 + dy * t - other.y, 2),
              );
              expect(
                distance,
                greaterThanOrEqualTo(29.99),
                reason: '$id → ${node.id} crosses ${other.id}',
              );
            }
          }
        }
      }
    },
  );

  testWidgets(
    'results keep three key numbers and one action on a small phone with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final income in [0, 4]) {
        final session = GameSession(catalog, MemoryStore())..startDay();
        session.board!.captured = income;
        session.economy.generated = income;
        session.economy.collected = income;
        session.finishDay();
        await tester.pumpWidget(GardenApp(session: session));
        await tester.pumpAndSettle();
        final popup = find.byKey(const ValueKey('day-results-popup'));
        expect(
          find.byKey(const ValueKey('visual-day-results')),
          findsOneWidget,
        );
        expect(find.text('Resumen de la jornada'), findsNothing);
        expect(find.text('Récord diario'), findsNothing);
        expect(find.text('Respecto al anterior'), findsNothing);
        expect(
          find.descendant(
            of: popup,
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          ),
          findsOneWidget,
        );
        expect(find.text('Tienda'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await session.pendingWrites;
        session.dispose();
      }
    },
  );
}
