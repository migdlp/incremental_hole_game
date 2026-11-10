import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/features/day_cycle/domain/day_cycle.dart';
import '../test_support.dart';

void advance(GameSession session, int frames) {
  for (var i = 0; i < frames; i++) {
    session.tick(1 / 60);
  }
}

void main() {
  final catalog = testCatalog();
  test('initial day lasts 13 seconds including three for collection', () {
    final session = GameSession(catalog, MemoryStore())..startDay();
    expect(session.cycle!.remaining, 13);
    advance(session, 600);
    expect(session.phase, DayPhase.closing);
    expect(session.cycle!.remaining, closeTo(3, .001));
    expect(session.board!.balls.length, 15);
    advance(session, 179);
    expect(session.running, isTrue);
    expect(session.board!.balls.length, 15); // no production during closing
    advance(session, 1);
    expect(session.running, isFalse);
  });

  test(
    'generation starts at 1.5 balls per second and every upgrade is faster',
    () {
      for (var level = 0; level <= 5; level++) {
        final levels = {'generator': level};
        final current = catalog.settings(levels);
        expect(
          current['spawn_interval'],
          closeTo(1 / (1.5 * pow(1.25, level)), 1e-9),
        );
        expect(current['production_duration'], 10);
        if (level == 0) {
          expect(1 / current['spawn_interval'], closeTo(1.5, 1e-9));
        }
        if (level > 0) {
          expect(
            current['spawn_interval'],
            lessThan(
              catalog.settings({'generator': level - 1})['spawn_interval'],
            ),
          );
        }
      }
      for (var level = 1; level <= 3; level++) {
        expect(
          catalog.settings({
            'generator': 1,
            'duration': level,
          })['production_duration'],
          10 + level * 3,
        );
      }
    },
  );

  test(
    'first ball waits two thirds of a second, then three spawn every two seconds',
    () {
      final session = GameSession(catalog, MemoryStore())..startDay();
      advance(session, 39);
      expect(session.board!.balls, isEmpty);
      advance(session, 1);
      expect(session.board!.balls.length, 1);
      advance(session, 80);
      expect(session.board!.balls.length, 3);
    },
  );

  test(
    'unknown balance and unpurchased configuration are rejected atomically',
    () {
      final session = GameSession(catalog, MemoryStore())..startDay();
      final data = jsonDecode(session.snapshot()) as Map<String, dynamic>;
      data['run']['balanceVersion'] = 999;
      expect(() => session.restore(jsonEncode(data)), throwsFormatException);
      data['run']['balanceVersion'] = 7;
      data['run']['settings']['production_duration'] = 75;
      expect(() => session.restore(jsonEncode(data)), throwsFormatException);
      expect(session.cycle!.remaining, 13);
    },
  );
}
