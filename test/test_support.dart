import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/features/feedback/domain/feedback_controller.dart';
import 'package:incremental_hole_game/features/feedback/domain/feedback_config.dart';
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

/// Deterministic sink for audiovisual tests; never calls a device or writes money.
class RecordingFeedbackBackend implements FeedbackBackend {
  RecordingFeedbackBackend({this.hasHaptics = true});
  @override
  String get status => 'Backend de pruebas';
  final bool hasHaptics;
  final played = <SoundCue>[];
  final pulses = <String>[];
  final stopped = <int>[];
  double absorb = 0, rolling = 0;
  int frames = 0, stops = 0;
  @override
  Future<FeedbackBank?> prepare() async =>
      FeedbackBank(const FeedbackConfig(), {});
  @override
  void frame(
    List<SoundCue> play,
    List<int> stop,
    double absorb,
    double rolling,
    String? haptic,
  ) {
    played.addAll(play);
    stopped.addAll(stop);
    frames++;
    this.absorb = absorb;
    this.rolling = rolling;
    if (hasHaptics && haptic != null) pulses.add(haptic);
  }

  @override
  void stop() {
    absorb = rolling = 0;
    stops++;
  }

  @override
  void dispose() => stop();
}

/// Existing shop/control fixtures start after P02's mandatory opening day.
/// Clear only the last-results presentation so tests can inspect the shop directly.
void prepareNormalShop(GameSession session) {
  session.startDay();
  session.finishDay();
  session.progress.last = null;
}

/// Legacy accounting/physics tests now complete the mandatory E03 interaction.
/// Prefer delayed/non-economic choices so these fixtures keep their original focus.
Future<void> resolveEvolutionFixture(GameSession session) async {
  await session.pendingWrites;
  const priority = [
    'E03-03',
    'E03-11',
    'E03-09',
    'E03-05',
    'E03-01',
    'E03-04',
    'E03-08',
    'E03-07',
    'E03-06',
    'E03-02',
    'E03-12',
    'E03-10',
  ];
  while (session.evolution.hasChoices) {
    final id = priority.firstWhere(session.evolution.options.contains);
    if (!session.chooseEvolution(id, serial: session.evolution.serial))
      throw StateError('Fixture E03 sin guardar');
    await session.pendingWrites;
  }
}

/// Advance real simulation, rather than forging only one of its synchronized clocks.
void advanceToProductionBoundary(GameSession session, double remaining) {
  while (session.running && session.cycle!.remaining > remaining + 1e-8) {
    session.tick((session.cycle!.remaining - remaining).clamp(0, .1));
  }
}
