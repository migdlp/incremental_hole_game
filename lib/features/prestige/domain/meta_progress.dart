import 'dart:convert';

enum PrestigePhase { playing, defeat, shop }

/// Permanent data and run lifecycle. No P01 awards or P02 effects are invented.
class MetaProgress {
  MetaProgress({
    this.revision = 0,
    this.runId = 1,
    this.lastEndedRun = 0,
    this.phase = PrestigePhase.playing,
    this.stars = 0,
    this.upgrades = const {},
    this.discoveries = const [],
    this.pendingStarObjects = const [],
    this.extensions = const {},
    this.firstDefeatSeen = false,
    this.endCause,
  });
  final int revision, runId, lastEndedRun, stars;
  final PrestigePhase phase;
  final Map<String, int> upgrades;
  final List<String> discoveries;
  // Opaque future P01 state: preserve unchanged; never award or discard it.
  final List<dynamic> pendingStarObjects;
  final Map<String, dynamic> extensions;
  final bool firstDefeatSeen;
  final String? endCause;

  MetaProgress _transition(
    PrestigePhase next, {
    bool newRun = false,
    String? cause,
  }) => MetaProgress(
    revision: revision + 1,
    runId: runId + (newRun ? 1 : 0),
    lastEndedRun: newRun ? lastEndedRun : runId,
    phase: next,
    stars: stars,
    upgrades: upgrades,
    discoveries: discoveries,
    pendingStarObjects: pendingStarObjects,
    extensions: extensions,
    firstDefeatSeen: firstDefeatSeen || cause == 'quota',
    endCause: newRun ? null : cause ?? endCause,
  );
  MetaProgress end({required bool voluntary}) {
    if (phase != PrestigePhase.playing || lastEndedRun >= runId) {
      throw StateError('Esta partida ya terminó');
    }
    return _transition(
      voluntary ? PrestigePhase.shop : PrestigePhase.defeat,
      cause: voluntary ? 'voluntary' : 'quota',
    );
  }

  MetaProgress openShop() {
    if (phase != PrestigePhase.defeat) throw StateError('Tienda inaccesible');
    return _transition(PrestigePhase.shop);
  }

  MetaProgress newRun() {
    if (phase != PrestigePhase.shop) {
      throw StateError('No se puede reiniciar aquí');
    }
    return _transition(PrestigePhase.playing, newRun: true);
  }

  Map<String, dynamic> toJson() => {
    'revision': revision,
    'runId': runId,
    'lastEndedRun': lastEndedRun,
    'phase': phase.name,
    'stars': stars,
    'upgrades': upgrades,
    'discoveries': discoveries,
    'pendingStarObjects': pendingStarObjects,
    'extensions': extensions,
    'firstDefeatSeen': firstDefeatSeen,
    'endCause': endCause,
  };
  factory MetaProgress.fromJson(Map<String, dynamic> json) {
    int integer(String key, {int min = 0}) {
      final n = json[key];
      if (n is! int || n < min || n > 0x1fffffffffffff) {
        throw const FormatException('Metaprogresión inválida');
      }
      return n;
    }

    final phase = PrestigePhase.values
        .where((p) => p.name == json['phase'])
        .firstOrNull;
    final upgrades = json['upgrades'], discoveries = json['discoveries'];
    final pending = json['pendingStarObjects'], extensions = json['extensions'];
    if (phase == null ||
        upgrades is! Map<String, dynamic> ||
        upgrades.entries.any(
          (e) =>
              e.key.isEmpty ||
              e.value is! int ||
              e.value < 1 ||
              e.value > 0x1fffffffffffff,
        ) ||
        discoveries is! List ||
        discoveries.any((v) => v is! String || v.isEmpty) ||
        discoveries.toSet().length != discoveries.length ||
        pending is! List ||
        extensions is! Map<String, dynamic> ||
        json['firstDefeatSeen'] is! bool ||
        ![null, 'quota', 'voluntary'].contains(json['endCause'])) {
      throw const FormatException('Datos permanentes inválidos');
    }
    // JSON encode rejects nonfinite/unsupported extension values without defining P01.
    final clone = jsonDecode(
      jsonEncode({'pending': pending, 'extensions': extensions}),
    );
    final state = MetaProgress(
      revision: integer('revision'),
      runId: integer('runId', min: 1),
      lastEndedRun: integer('lastEndedRun'),
      phase: phase,
      stars: integer('stars'),
      upgrades: Map.unmodifiable(upgrades.cast<String, int>()),
      discoveries: List.unmodifiable(discoveries.cast<String>()),
      pendingStarObjects: List.unmodifiable(clone['pending']),
      extensions: Map.unmodifiable(clone['extensions']),
      firstDefeatSeen: json['firstDefeatSeen'] as bool,
      endCause: json['endCause'] as String?,
    );
    if (state.lastEndedRun !=
            state.runId - (phase == PrestigePhase.playing ? 1 : 0) ||
        (phase == PrestigePhase.playing
            ? state.endCause != null
            : state.endCause == null) ||
        (phase == PrestigePhase.defeat &&
            (state.endCause != 'quota' || !state.firstDefeatSeen)) ||
        state.revision <
            2 * (state.runId - 1) + (phase == PrestigePhase.playing ? 0 : 1)) {
      throw const FormatException('Ciclo de prestigio incoherente');
    }
    return state;
  }
}
