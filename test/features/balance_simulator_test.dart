import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/features/balance/testing/balance_simulator.dart';
import '../test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('real session bot is reproducible and explicitly labelled', () async {
    final scenario = <String, dynamic>{
      'id': 'test',
      'days': 2,
      'interaction': 'hand_seek',
      'p02': ['H04'],
      'normal_levels': {'generator': 2},
      'e03': {'E03-07': 1},
    };
    final a = await simulateBalance(testCatalog(), scenario, 42);
    final b = await simulateBalance(testCatalog(), scenario, 42);
    expect(a['deterministic_sha256'], b['deterministic_sha256']);
    expect(a, b);
    expect((a['days'] as List).length, 2);
    for (final day in a['days']) {
      expect(day['test_kind'], 'automated_physics');
      expect(day['board']['validation'], isEmpty);
    }
    final c = await simulateBalance(testCatalog(), scenario, 79);
    expect(c['deterministic_sha256'], isNot(a['deterministic_sha256']));
  });
  test(
    'experimental quota curve stays in runner and stops when exhausted',
    () async {
      final result = await simulateBalance(testCatalog(), {
        'id': 'curve',
        'days': 3,
        'interaction': 'hand_seek',
        'quota_curve': ['1'],
        'normal_levels': {'hand': 1},
      }, 42);
      expect(result['metadata']['stop_reason'], 'experimental_curve_exhausted');
      expect(result['days'].first['quota_start']['target'], '1');
      final normal = await simulateBalance(testCatalog(), {
        'id': 'normal',
        'days': 1,
      }, 42);
      expect(normal['days'].first['quota_start']['target'], '25');
    },
  );
  test('invalid scenario configuration fails explicitly', () async {
    expect(
      () => simulateBalance(testCatalog(), {
        'normal_levels': {'generator': 999},
      }, 42),
      throwsFormatException,
    );
    expect(
      () => simulateBalance(testCatalog(), {'interaction': 'teleport'}, 42),
      throwsFormatException,
    );
  });
}
