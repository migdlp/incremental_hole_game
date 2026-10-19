import 'dart:math' as math;
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
  Board grip(int level) {
    final board = Board(catalog.settings({'hand': 1, 'hand_grip': level}));
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
    'successive grip levels bring the next ball in faster without snapping',
    () {
      var previousError = double.infinity;
      for (var level = 0; level <= 5; level++) {
        final board = grip(level);
        final second = board.balls.last;
        final initial = second.position;
        advance(board, 1);
        expect((second.position - initial).length, lessThan(1));
        advance(board, 35);
        final error = (second.position - const Vec(94, 250)).length;
        expect(error, lessThan(previousError));
        previousError = error;
        expect(board.heldBalls, hasLength(2));
        expect(board.handCapacity, 2);
        expect(board.ballMagnetRadius, 36);
        board.releasePointer(cancel: true);
        expect(board.heldBalls, isEmpty);
        expect(board.balls.every((ball) => ball.velocity.length == 0), isTrue);
      }
    },
  );

  test(
    'stronger grip retains an extra ball during a pull that breaks the base grip',
    () {
      final weak = grip(0), strong = grip(5);
      advance(weak, 240);
      advance(strong, 240);
      weak.drag(const Vec(200, 250));
      strong.drag(const Vec(200, 250));
      advance(weak, 48);
      advance(strong, 48);
      expect(weak.heldBalls, hasLength(1));
      expect(strong.heldBalls, hasLength(2));
      strong.enterClosing();
      expect(strong.heldBalls, isEmpty);
      expect(strong.balls.every((ball) => ball.velocity.length == 0), isTrue);
    },
  );

  test(
    'grip still needs a manually held ball and does not increase capacity or coin reach',
    () {
      final board = grip(5)..releasePointer(cancel: true);
      board.touch(const Vec(30, 200));
      advance(board, 240);
      expect(board.heldBalls, isEmpty);
      expect(board.settings['magnet_radius'], 0);
      expect(board.handCapacity, 2);
      expect(board.balls.last.position.x, closeTo(110, .01));
    },
  );

  test(
    'grip is stable across frame rates and purchases restore without upgrading old runs',
    () {
      Vec follow(int hz) {
        final board = grip(5);
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
      final session = GameSession(catalog, MemoryStore())
        ..economy.balance = 1000;
      final definition = catalog.definitions.firstWhere(
        (d) => d.id == 'hand_grip',
      );
      expect(session.purchase(definition), isFalse);
      expect(
        session.purchase(catalog.definitions.firstWhere((d) => d.id == 'hand')),
        isTrue,
      );
      expect(session.purchase(definition), isTrue);
      session.startDay();
      final restored = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      expect(restored.board!.gripStrength, 1.25);
      expect(restored.levels['hand_grip'], 1);
      expect(restored.economy.balance, 962);
      expect(restored.board!.heldBalls, isEmpty);
      final old = GameSession(catalog, MemoryStore())..startDay();
      final reopened = GameSession(catalog, MemoryStore())
        ..restore(old.snapshot());
      expect(reopened.board!.gripStrength, 1);
      expect(reopened.levels.containsKey('hand_grip'), isFalse);
      expect(
        reopened.board!.settings.values.containsKey('hand_grip_strength'),
        isFalse,
      );
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
        expect(find.text('Ir al árbol de mejoras'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await session.pendingWrites;
        session.dispose();
      }
    },
  );
}
