// Evidence for export continuity: real transitions, restore, defeat and next run.
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import '../test/test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('export five real session days across restore and run reset', () async {
    final store = MemoryStore();
    var session = GameSession(testCatalog(), store, eventSeed: 42)
      ..balanceTestKind = 'automated_physics';
    for (var day = 1; day <= 4; day++) {
      session.startDay();
      for (var frame = 0; session.running; frame++) {
        session.tick(1 / 60);
        if (day == 2 && frame == 120) {
          await session.pendingWrites;
          final snapshot = session.snapshot();
          session.dispose();
          session = GameSession(testCatalog(), store, eventSeed: 42)
            ..balanceTestKind = 'automated_physics';
          session.restore(snapshot);
          expect(session.paused, isTrue);
          session.resume();
        }
      }
      await session.pendingWrites;
    }
    expect(session.canPlayRun, isFalse);
    expect(session.continueToPrestigeShop(), isTrue);
    await session.pendingWrites;
    expect(session.beginNewRun(), isTrue);
    await session.pendingWrites;
    await Future<void>.delayed(Duration.zero);
    expect(session.running, isTrue);
    while (session.running) {
      session.tick(1 / 60);
    }
    await session.pendingWrites;
    expect(session.balanceLab.days.length, 5);
    expect(session.balanceLab.days.last['run_id'], '2');
    const output = String.fromEnvironment(
      'BAL_OUTPUT',
      defaultValue: '/tmp/bal-export-smoke',
    );
    Directory(output).createSync(recursive: true);
    final before = jsonDecode(session.snapshot());
    for (var repeat = 0; repeat < 2; repeat++) {
      final files = session.balanceExportFiles;
      final exported =
          jsonDecode(files['session.json']!) as Map<String, dynamic>;
      exported['metadata']['test_protocol'] =
          'five_days_restore_day2_frame120_quota_defeat_next_run';
      exported['metadata']['confirmed_restore_count'] = 1;
      files['session.json'] = const JsonEncoder.withIndent(
        '  ',
      ).convert(exported);
      for (final entry in files.entries) {
        File('$output/${entry.key}').writeAsStringSync(entry.value);
      }
    }
    expect(jsonDecode(session.snapshot()), before);
    session.dispose();
  });
}
