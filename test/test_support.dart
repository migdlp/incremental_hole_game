import 'dart:io';
import 'package:incremental_hole_game/features/upgrades/domain/catalog.dart';
import 'package:incremental_hole_game/persistence/save_store.dart';

/// Accounting fixtures may disable automatic emissions to isolate explicit captures.
/// Normal gameplay, cadence and physical integration tests use the real balance.
UpgradeCatalog testCatalog({bool automaticSpawns = true}) {
  var csv = File('docs/balance.csv').readAsStringSync();
  if (!automaticSpawns) {
    csv = csv
        .split('\n')
        .map((line) {
          final row = line.split(',');
          if (row.length == 9 && row[4] == 'spawn_interval') {
            row[5] = '${double.parse(row[5]) * 10000}';
          }
          return row.join(',');
        })
        .join('\n');
  }
  return UpgradeCatalog.fromCsv(csv);
}

class MemoryStore implements SaveStore, PrestigeStore {
  List<String> candidates = [];
  List<String> writes = [];
  bool fail = false;
  List<String> prestigeCandidates = [];
  @override
  Future<List<String>> loadPrestigeCandidates() async => prestigeCandidates;
  @override
  Future<void> savePrestige(String contents) async {
    if (fail) throw const FileSystemException('Disk unavailable');
    prestigeCandidates = [contents, contents];
  }

  @override
  Future<List<String>> loadCandidates() async => candidates;
  @override
  Future<void> save(String contents, {String? previous}) async {
    if (fail) throw const FileSystemException('Disk unavailable');
    writes.add(contents);
    candidates = [contents, if (previous != null) previous];
  }
}

// Historical monetary feeding fixture; changing only the outer save version is
// insufficient now that AJ-005B writes decimal BigInt ball counters.
Map<String, dynamic> legacyFeeding({int normal = 0, int instant = 0}) => {
  'startDay': 1,
  'period': 1,
  'completedDays': 0,
  'normal': normal,
  'instant': instant,
  'runNormal': normal,
  'runInstant': instant,
  'target': 10,
  'quotaStep': 10,
};
