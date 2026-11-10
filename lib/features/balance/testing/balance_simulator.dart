import 'dart:convert';
import '../../../app/game_session.dart';
import '../../../core/vec.dart';
import '../../../persistence/save_store.dart';
import '../../board/domain/tool.dart';
import '../../board/domain/special_abilities.dart';
import '../../feeding/domain/feeding_progress.dart';
import '../../prestige/domain/meta_progress.dart';
import '../../prestige/domain/permanent_skills.dart';
import '../../evolution/domain/evolution.dart';
import '../../upgrades/domain/catalog.dart';
import '../domain/balance_metrics.dart';

/// Test-only curve; production FeedingProgress and its defaults are untouched.
class _ExperimentalFeeding extends FeedingProgress {
  _ExperimentalFeeding(this.curve) : super(startDay: 1, target: 1) {
    target = curve.first;
    initialTarget = curve.first;
  }
  final List<BigInt> curve;
  @override
  BigInt? get nextTarget => period < curve.length ? curve[period] : null;
}

class _SimulationStore implements SaveStore, PrestigeStore {
  @override
  Future<List<String>> loadCandidates() async => [];
  @override
  Future<void> save(String contents, {String? previous}) async {}
  @override
  Future<List<String>> loadPrestigeCandidates() async => [];
  @override
  Future<void> savePrestige(String contents) async {}
}

/// Headless real GameSession, fixed steps and deterministic input policy.
/// This is a bot. It is never classified as a human or a physical Android test.
Future<Map<String, dynamic>> simulateBalance(
  UpgradeCatalog catalog,
  Map<String, dynamic> scenario,
  int seed,
) async {
  final maxDays = scenario['days'] as int? ?? 8;
  if (maxDays < 1 || maxDays > 500) throw const FormatException('days 1..500');
  if (seed < 0 || seed > 0xffffffff) throw const FormatException('seed uint32');
  final strategy = scenario['interaction'] as String? ?? 'idle';
  if (!['idle', 'hand_seek', 'abilities'].contains(strategy)) {
    throw const FormatException('unknown interaction strategy');
  }
  final levels = Map<String, int>.from(scenario['normal_levels'] as Map? ?? {});
  for (final e in levels.entries) {
    final defs = catalog.definitions.where(
      (d) => d.id == e.key && d.id != 'prestige',
    );
    if (defs.isEmpty || e.value < 0 || e.value > defs.single.levels.length) {
      throw FormatException('invalid normal level ${e.key}');
    }
    // Direct starting unlocks are experimental endowments, explicitly exported.
  }
  final p02 = (scenario['p02'] as List? ?? []).cast<String>();
  if (p02.toSet().length != p02.length ||
      p02.any((id) => PermanentSkill.find(id) == null)) {
    throw const FormatException('invalid P02');
  }
  final e03 = Map<String, int>.from(scenario['e03'] as Map? ?? {});
  if (e03.entries.any(
    (e) => EvolutionSkill.find(e.key) == null || e.value < 0 || e.value > 5,
  )) {
    throw const FormatException('invalid E03');
  }
  final budget = scenario['starting_coins'] as String? ?? '0';
  final initialCoins = int.parse(budget);
  if (initialCoins < 0 || initialCoins > 0x1fffffffffffff) {
    throw const FormatException('budget');
  }
  final buying = (scenario['purchase_priority'] as List? ?? []).cast<String>();
  if (buying.any(
    (id) => !catalog.definitions.any((d) => d.id == id && id != 'prestige'),
  )) {
    throw const FormatException('purchase strategy');
  }
  final session = GameSession(catalog, _SimulationStore(), eventSeed: seed)
    ..balanceTestKind = 'automated_physics';
  try {
    session.levels.addAll(levels);
    session.meta = MetaProgress(
      upgrades: {for (final id in p02) id: 1},
      evolutionLevels: e03,
    );
    session.economy.balance =
        initialCoins + (p02.contains(PermanentSkill.inheritance) ? 100 : 0);
    final curveInput = scenario['quota_curve'] as List?;
    List<BigInt>? curve;
    if (curveInput != null) {
      curve = curveInput.map((x) => BigInt.parse(x as String)).toList();
      if (curve.isEmpty || curve.any((x) => x <= BigInt.zero)) {
        throw const FormatException('quota curve');
      }
      session.feeding = _ExperimentalFeeding(curve);
    }
    String stop = 'horizon';
    for (var day = 0; day < maxDays; day++) {
      session.startDay();
      if (!session.running) throw StateError('simulation did not start');
      var frame = 0;
      Vec? pointer;
      while (session.running) {
        if (session.evolutionBlocked) {
          await session.pendingWrites;
          if (session.evolutionChoiceReady) {
            // Stable first option, not a reroll or invented card.
            session.chooseEvolution(
              session.evolution.options.first,
              serial: session.evolution.serial,
            );
            await session.pendingWrites;
          }
          if (!session.evolution.hasChoices) {
            await Future<void>.delayed(Duration.zero);
          }
          continue;
        }
        final board = session.board!;
        if (strategy == 'hand_seek') {
          if (pointer == null && board.balls.isNotEmpty) {
            session.selectTool(BallTool.hand);
            pointer = board.balls.first.position;
            session.touch(pointer, time: frame / 60);
          } else if (pointer != null) {
            final delta = board.holePosition - pointer;
            pointer = pointer + delta.limit(240 / 60);
            session.drag(pointer, time: frame / 60);
            if (delta.length <= 4 || frame % 120 == 0) {
              session.release(time: frame / 60);
              pointer = null;
            }
          }
        }
        if (strategy == 'abilities') {
          for (final ability in SpecialAbility.values) {
            if (board.specials.ready(ability)) board.activateSpecial(ability);
          }
        }
        session.tick(1 / 60);
        await session.pendingWrites;
        if (++frame > 120000) throw StateError('simulation stalled');
      }
      if (!session.canPlayRun) {
        stop = 'quota_defeat';
        break;
      }
      if (curve != null && session.feeding.completed >= curve.length) {
        stop = 'experimental_curve_exhausted';
        break;
      }
      // Accepted normal purchases through the actual economy/prerequisites.
      for (final id in buying) {
        final def = catalog.definitions.firstWhere((d) => d.id == id);
        while (session.purchaseBlock(def) == null) {
          session.purchase(def);
          await session.pendingWrites;
        }
      }
    }
    final output = session.balanceLab.export(
      context: {
        ...session.balanceExportContext,
        'test_kind': 'automated_physics',
        'strategy_version': 1,
        'scenario': scenario,
        'scenario_sha256': configurationHash(scenario),
        'seed': seed,
        'fixed_step_s': 1 / 60,
        'stop_reason': stop,
        'board_seed_rule': 'day * 7919 (GameSession default)',
        'sensor': 'NoMotionInput; no real sensor',
        'renderer': 'none',
        'source_commit': BalanceLab.commit,
        'runtime_scope': 'Flutter test host; no Android performance claims',
      },
    );
    // No clocks, hardware timings, cosmetic RNG or filenames in this fingerprint.
    output['deterministic_sha256'] = configurationHash(output);
    return jsonDecode(jsonEncode(output)) as Map<String, dynamic>;
  } finally {
    await session.pendingWrites;
    session.dispose();
  }
}
