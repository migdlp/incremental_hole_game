import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/presentation/garden_game.dart';
import '../test_support.dart';

void simulate(Board board, double seconds) {
  for (var i = 0; i < (seconds * 240).round(); i++) {
    board.update(1 / 240, producing: false);
  }
}

void main() {
  final catalog = testCatalog();
  Board broom({bool vee = false}) => Board(
    catalog.settings({
      'hand': 2,
      'broom': 1,
      if (vee) 'paddle': 1,
      if (vee) 'broom_v': 1,
    }),
  )..broomPosition = const Vec(180, 250);

  test('two grab points set orientation and translate a rigid broom', () {
    for (final vee in [false, true]) {
      final board = broom(vee: vee);
      final handles = board.broomHandles;
      board.touch(handles.first);
      expect(board.grabSecondBroomPoint(handles.last), isTrue);
      expect(board.grabSecondBroomPoint(handles.last), isFalse);
      // Rotate the initial contacts ninety degrees around their midpoint.
      final pivot = (handles.first + handles.last) * .5;
      Vec rotated(Vec point) {
        final delta = point - pivot;
        return pivot + Vec(delta.y, -delta.x);
      }

      final first = rotated(handles.first), second = rotated(handles.last);
      board.drag(first);
      board.dragSecondBroomPoint(second);
      final before = board.toolAngle;
      board.update(1 / 60, producing: false);
      expect(
        (board.toolAngle - before).abs(),
        lessThanOrEqualTo(3 / 60 + 1e-6),
      );
      simulate(board, 1);
      expect(math.sin(board.toolAngle).abs(), lessThan(.001));
      final center = board.broomPosition;
      board.drag(first + const Vec(25, 20));
      board.dragSecondBroomPoint(second + const Vec(25, 20));
      simulate(board, .4);
      expect(board.broomPosition.x, closeTo(center.x + 25, .01));
      expect(board.broomPosition.y, closeTo(center.y + 20, .01));
      expect(
        (board.broomHandles.first - board.broomHandles.last).length,
        closeTo((handles.first - handles.last).length, .01),
      );
    }
  });

  test('lifting either finger preserves the remaining grip without a jump', () {
    for (final promote in [false, true]) {
      final board = broom();
      board.touch(board.broomHandles.first);
      board.grabSecondBroomPoint(board.broomHandles.last);
      board.drag(const Vec(180, 210));
      board.dragSecondBroomPoint(const Vec(180, 290));
      simulate(board, .7);
      final position = board.broomPosition;
      final angle = board.toolAngle;
      if (promote) {
        board.promoteSecondBroomPoint();
      } else {
        board.releaseSecondBroomPoint();
      }
      simulate(board, .1);
      expect((board.broomPosition - position).length, lessThan(.001));
      expect(board.holdingBroom, isTrue);
      expect(board.hasSecondBroomPoint, isFalse);
      board.drag(board.target! + const Vec(20, 10));
      simulate(board, .3);
      expect(board.broomPosition.x, closeTo(position.x + 20, .001));
      expect(board.toolAngle, closeTo(angle, .001));
      board.releasePointer();
      expect(board.holdingBroom, isFalse);
    }
  });

  test('pinching does not flip, stretch or produce nonfinite physics', () {
    final board = broom();
    board.touch(board.broomHandles.first);
    board.grabSecondBroomPoint(board.broomHandles.last);
    final angle = board.toolAngle;
    board.drag(const Vec(180, 250));
    board.dragSecondBroomPoint(const Vec(180, 250));
    simulate(board, .5);
    expect(board.toolAngle, angle);
    expect(board.broomPosition.x.isFinite, isTrue);
    expect(board.broomPosition.y.isFinite, isTrue);
    expect((board.broomHandles.first - board.broomHandles.last).length, 80);
  });

  test(
    'second touch never steals a ball grip; pause and closing release both points',
    () {
      final session = GameSession(catalog, MemoryStore())
        ..levels.addAll({'hand': 2, 'broom': 1})
        ..startDay();
      final board = session.board!;
      board.balls.add(Ball(board.nextId++, const Vec(100, 200), Vec.zero));
      session.touch(board.balls.first.position);
      expect(session.grabSecondBroomPoint(board.broomHandles.last), isFalse);
      expect(board.heldBall, isNotNull);
      session.release();
      session.touch(board.broomHandles.first);
      expect(session.grabSecondBroomPoint(board.broomHandles.last), isTrue);
      session.pause();
      expect(board.holdingBroom, isFalse);
      expect(board.hasSecondBroomPoint, isFalse);
      session.resume();
      session.touch(board.broomHandles.first);
      expect(session.grabSecondBroomPoint(board.broomHandles.last), isTrue);
      final restored = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      expect(restored.board!.holdingBroom, isFalse);
      expect(restored.board!.hasSecondBroomPoint, isFalse);
      board.enterClosing();
      final position = board.broomPosition;
      expect(board.hasSecondBroomPoint, isFalse);
      expect(session.grabSecondBroomPoint(board.broomHandles.first), isFalse);
      simulate(board, .2);
      expect(board.broomPosition, position);
    },
  );

  testWidgets(
    'actual two-finger events rotate and hand off on primary release',
    (tester) async {
      final session = GameSession(catalog, MemoryStore())
        ..levels.addAll({'hand': 2, 'broom': 1})
        ..startDay();
      session.board!.broomPosition = const Vec(180, 250);
      await tester.pumpWidget(GardenApp(session: session));
      await tester.pump(const Duration(milliseconds: 50));
      final widget = tester.widget<GameWidget>(
        find.byWidgetPredicate((widget) => widget is GameWidget),
      );
      final game = widget.game as GardenGame;
      final topLeft = tester.getTopLeft(
        find.byWidgetPredicate((widget) => widget is GameWidget),
      );
      Offset point(Vec value) =>
          topLeft + game.origin + Offset(value.x, value.y) * game.scale;
      final board = session.board!;
      final first = await tester.startGesture(
        point(board.broomHandles.first),
        pointer: 1,
      );
      final second = await tester.startGesture(
        point(board.broomHandles.last),
        pointer: 2,
      );
      expect(board.hasSecondBroomPoint, isTrue);
      await first.moveTo(point(const Vec(180, 210)));
      await second.moveTo(point(const Vec(180, 290)));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 17));
      }
      expect(math.sin(board.toolAngle).abs(), lessThan(.01));
      await first.up();
      expect(board.holdingBroom, isTrue);
      expect(board.hasSecondBroomPoint, isFalse);
      final x = board.broomPosition.x;
      await second.moveTo(point(const Vec(210, 290)));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 17));
      }
      expect(board.broomPosition.x, greaterThan(x + 20));
      await second.up();
      expect(board.holdingBroom, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await session.pendingWrites;
      session.dispose();
    },
  );
}
