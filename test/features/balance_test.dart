import 'dart:convert';
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
    expect(session.board!.balls, isEmpty); // no taps, no shots
    advance(session, 179);
    expect(session.running, isTrue);
    expect(session.board!.balls, isEmpty);
    advance(session, 1);
    expect(session.running, isFalse);
  });

  test('every duration level adds three seconds', () {
    expect(catalog.settings({})['production_duration'], 10);
    for (var level = 1; level <= 3; level++) {
      expect(
        catalog.settings({
          'generator': 1,
          'duration': level,
        })['production_duration'],
        10 + level * 3,
      );
    }
  });

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
