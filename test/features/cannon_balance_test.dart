import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/upgrades/domain/catalog.dart';
import '../test_support.dart';

/// Shots a perfect player lands in a full production phase, tapping every step.
int perfectShots(DaySettings settings) {
  final board = Board(settings);
  var shots = 0;
  var time = 0.0;
  final production = settings['production_duration'];
  while (time < production - 1e-9) {
    if (board.fireCannon(board.cannons.first)) shots++;
    board.update(1 / 60, producing: true);
    board.balls.clear(); // keep the muzzle free: only the cooldown matters
    time += 1 / 60;
  }
  return shots;
}

void main() {
  final catalog = testCatalog();
  UpgradeDefinition find(String id) =>
      catalog.definitions.firstWhere((d) => d.id == id);

  test('a perfect first day fires ten shots', () {
    expect(perfectShots(catalog.settings({})), 10);
  });

  test('first purchase needs between one and two perfect days', () {
    final income = perfectShots(catalog.settings({}));
    final cost = find('hand').levels.first.cost;
    expect(cost, 13);
    expect(cost, greaterThan(income));
    expect(cost, lessThanOrEqualTo(income * 2));
  });

  test('cannon unlock prices grow along the chain', () {
    int price(String id) => find(id).levels.first.cost;
    expect(price('g2_unlock'), lessThan(price('g3_unlock')));
    expect(price('g3_unlock'), lessThan(price('g4_unlock')));
  });

  test('automatic intervals strictly decrease per level', () {
    for (final n in [1, 2, 3, 4]) {
      final values = find(
        'g${n}_auto_speed',
      ).levels.map((l) => l.value).toList();
      for (var i = 1; i < values.length; i++) {
        expect(values[i], lessThan(values[i - 1]), reason: 'g$n level $i');
      }
      expect(values.first, lessThan(catalog.base['g${n}_auto_interval']!));
    }
  });

  test('aim never widens', () {
    for (final n in [1, 2, 3, 4]) {
      final values = find('g${n}_aim').levels.map((l) => l.value).toList();
      for (var i = 1; i < values.length; i++) {
        expect(values[i], lessThan(values[i - 1]), reason: 'g$n level $i');
      }
      expect(values.first, lessThan(150));
    }
  });

  test('shot speed stays below the ball speed cap', () {
    final base = catalog.base;
    expect(base['cannon_shot_speed']!, lessThan(base['max_ball_speed']!));
  });
}
