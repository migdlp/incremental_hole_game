// Run using tool/run_balance.sh; Flutter test host reuses the real GameSession.
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/features/balance/domain/balance_metrics.dart';
import 'package:incremental_hole_game/features/balance/testing/balance_simulator.dart';
import 'package:incremental_hole_game/features/upgrades/domain/catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'BAL-TOOLS reproducible session batch',
    () async {
      const input = String.fromEnvironment(
        'BAL_SCENARIOS',
        defaultValue: 'docs/balance/BAL-TOOLS/scenarios/baseline.json',
      );
      const directory = String.fromEnvironment(
        'BAL_OUTPUT',
        defaultValue: '/tmp/feed-the-hole-balance',
      );
      final config =
          jsonDecode(File(input).readAsStringSync()) as Map<String, dynamic>;
      final catalog = UpgradeCatalog.fromCsv(
        File(
          config['balance_csv'] as String? ?? 'docs/balance.csv',
        ).readAsStringSync(),
      );
      final output = Directory(directory)..createSync(recursive: true);
      for (final scenario
          in (config['scenarios'] as List).cast<Map<String, dynamic>>()) {
        final id = scenario['id'] as String;
        if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
          throw const FormatException('scenario id');
        }
        for (final seed in (config['seeds'] as List).cast<int>()) {
          final result = await simulateBalance(catalog, scenario, seed);
          File('${output.path}/$id-$seed.json').writeAsStringSync(
            const JsonEncoder.withIndent('  ').convert(result),
          );
          final lab = BalanceLab.restore(result);
          File('${output.path}/$id-$seed.csv').writeAsStringSync(lab.csv);
          File('${output.path}/$id-$seed.txt').writeAsStringSync(lab.summary);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
