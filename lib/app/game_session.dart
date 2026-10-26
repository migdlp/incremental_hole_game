import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import '../features/feedback/domain/feedback_controller.dart';
import '../features/feedback/domain/feedback_config.dart';
import '../features/feedback/domain/absorption_effects.dart';
import '../features/feedback/platform/platform_feedback_backend.dart';
import 'package:flutter/foundation.dart';
import '../core/vec.dart';
import '../features/board/domain/coin_denomination.dart';
import '../features/motion/motion_input.dart';
import '../features/board/domain/board.dart';
import '../features/board/domain/launcher.dart';
import '../features/board/domain/debug_day_report.dart';
import '../features/board/domain/special_abilities.dart';
import '../features/board/domain/tool.dart';
import '../features/day_cycle/domain/day_cycle.dart';
import '../features/economy/domain/economy.dart';
import '../features/rewards/domain/reward_delivery.dart';
import '../features/rewards/domain/reward_visual_config.dart';
import '../features/rewards/domain/reward_frame_metrics.dart';
import '../features/progression/domain/progress.dart';
import '../features/prestige/domain/meta_progress.dart';
import '../features/evolution/domain/evolution.dart';
import '../features/prestige/domain/permanent_skills.dart';
import '../features/prestige/domain/star_rewards.dart';
import '../features/prestige/domain/star_bubbles.dart';
import '../features/feeding/domain/feeding_progress.dart';
import '../features/feeding/domain/legacy_feeding_progress.dart';
import '../features/upgrades/domain/catalog.dart';
import '../persistence/save_store.dart';

class GameSession extends ChangeNotifier {
  GameSession(
    this.catalog,
    this.store, {
    this.motion = const NoMotionInput(),
    int? eventSeed,
    FeedbackController? feedback,
  }) : feedback =
           feedback ?? FeedbackController(backend: PlatformFeedbackBackend()),
       _eventRandomState = eventSeed ?? math.Random().nextInt(0x100000000) {
    feeding = FeedingProgress(startDay: 1, target: feedingInitialQuota);
    evolution = EvolutionRun(
      randomState: _eventRandomState,
      cardRandom: (_eventRandomState ^ 0x7951) & 0xffffffff,
    );
  }
  final FeedbackController feedback;
  final MotionInput motion;
  int _eventRandomState;
  bool _backgrounded = false;
  bool debugForceGravity = false;
  int debugBlackHoleObjects = 0;
  void debugSetBlackHoleObjects(int count) {
    if (!debugEnabled || running || count < 0 || count > 3) return;
    debugBlackHoleObjects = count;
    notifyListeners();
  }

  String debugGravityTilt = 'sensor';
  static const gravityDebugTilts = {
    'sensor': 'Sensor real',
    'flat': 'Simular: reposo',
    'left': 'Simular: izquierda',
    'right': 'Simular: derecha',
    'up': 'Simular: arriba',
    'down': 'Simular: abajo',
  };
  Vec? get _debugTilt => !debugEnabled
      ? null
      : switch (debugGravityTilt) {
          'flat' => Vec.zero,
          'left' => const Vec(-.7, 0),
          'right' => const Vec(.7, 0),
          'up' => const Vec(0, -.7),
          'down' => const Vec(0, .7),
          _ => null,
        };
  bool get gravityAvailable => _debugTilt != null || motion.available;
  void debugSetGravityTilt(String value) {
    if (!debugEnabled || !gravityDebugTilts.containsKey(value)) return;
    debugGravityTilt = value;
    if (!gravityAvailable) debugForceGravity = false;
    notifyListeners();
  }

  void debugSetForceGravity(bool value) {
    if (!debugEnabled || running || (value && !gravityAvailable)) return;
    debugForceGravity = value;
    notifyListeners();
  }

  void setBackgrounded(bool value) {
    _backgrounded = value;
    feedback.setBackground(value);
    if (value) pause();
    _syncMotion();
  }

  void _syncMotion() => motion.setActive(
    running &&
        !paused &&
        !evolutionBlocked &&
        !_backgrounded &&
        phase == DayPhase.production,
  );

  final UpgradeCatalog catalog;
  final SaveStore store;
  final economy = Economy();
  final _debugRewardParameters = <String, double>{};
  RewardVisualConfig get rewardConfig =>
      RewardVisualConfig.fromMap({...catalog.base, ..._debugRewardParameters});
  double rewardParameterValue(String key) =>
      _debugRewardParameters[key] ??
      catalog.base[key] ??
      RewardVisualConfig.optionalDefaults[key]!;
  void debugSetRewardParameter(String key, double value) {
    if (!debugEnabled ||
        running ||
        !RewardVisualConfig.ranges.containsKey(key)) {
      return;
    }
    final proposed = {...catalog.base, ..._debugRewardParameters, key: value};
    RewardVisualConfig.fromMap(proposed);
    _debugRewardParameters[key] = value;
    rewardVisuals = _newVisuals();
    notifyListeners();
  }

  Map<int, int> _countsFor(int amount) {
    final counts = rewardVisuals.projectedCounts;
    return counts.entries.fold<int>(0, (sum, e) => sum + e.key * e.value) ==
            amount
        ? counts
        : {
            for (final s in CoinDenomination.split(amount))
              s.denomination.amount: s.count,
          };
  }

  late RewardDelivery rewards = _newRewards();
  final rewardFrameMetrics = RewardFrameMetrics();
  final rewardRepaint = ChangeNotifier();
  int debugCoinRainCaptures = 0;
  void debugSetCoinRainCaptures(int count) {
    if (!debugEnabled || running || ![0, 1, 10, 50, 100, 200].contains(count)) {
      return;
    }
    debugCoinRainCaptures = count;
    notifyListeners();
  }

  int? _debugRewardLimit;
  late RewardVisuals rewardVisuals = _newVisuals();
  RewardDelivery _newRewards() => RewardDelivery(
    delay: catalog.base['reward_delay']!,
    capacity: catalog.base['reward_ledger_limit']!.toInt(),
  );
  RewardVisuals _newVisuals() => RewardVisuals(
    rewardConfig.capacity,
    catalog.base['reward_delay']!,
    config: rewardConfig,
  )..debugLimit = _debugRewardLimit;
  void debugSetRewardLimit(int? value) {
    if (!debugEnabled ||
        (value != null && (value < 0 || value > rewardVisuals.capacity))) {
      return;
    }
    _debugRewardLimit = value;
    rewardVisuals.debugLimit = value;
    notifyListeners();
  }

  StarConfig? _debugStars;
  StarConfig get starConfig => _debugStars ?? StarConfig(catalog.base);
  bool debugBubbleGravity = false, debugBubbleBlackHole = false;
  void debugSetStarParameter(String key, double value) {
    if (!debugEnabled || running || !StarConfig.ranges.containsKey(key)) return;
    _debugStars = starConfig.changed(key, value);
    notifyListeners();
  }

  void debugSetBubbleInteractions({bool? gravity, bool? blackHole}) {
    if (!debugEnabled) return;
    debugBubbleGravity = gravity ?? debugBubbleGravity;
    debugBubbleBlackHole = blackHole ?? debugBubbleBlackHole;
    board?.bubbleGravity = debugBubbleGravity;
    board?.bubbleBlackHole = debugBubbleBlackHole;
    notifyListeners();
  }

  void debugAwardStarBubbles() {
    if (!debugEnabled || !canPlayRun) return;
    _changeStars(meta.starLedger.award(meta.starLedger.quota + 1, starConfig));
    board?.starBubbles?.populate(0);
    notifyListeners();
  }

  void _changeStars(StarLedger ledger, {int paid = 0}) {
    meta = meta.withStars(ledger, paid: paid);
    _metaFloor = meta;
    board?.starBubbles?.sync(ledger);
  }

  StarBubbles _newBubbles(Board board) => StarBubbles(
    starConfig,
    ballRadius: board.radius,
    maximumSpeed: board.maximumSpeed,
    hole: board.holePosition,
  )..sync(meta.starLedger);

  MetaProgress meta = MetaProgress();
  MetaProgress? _metaFloor;
  int _durableMetaRevision = 0;
  bool _allowPrestigeRollback = false;
  bool get prestigeReady =>
      debugEnabled ||
      (meta.revision <= _durableMetaRevision && saveError == null);
  EvolutionRun evolution = EvolutionRun();
  bool _evolutionCommitPending = false;
  bool get evolutionBlocked => evolution.hasChoices || _evolutionCommitPending;
  bool get evolutionChoiceReady =>
      evolution.hasChoices &&
      !_evolutionCommitPending &&
      prestigeReady &&
      !_backgrounded;
  bool chooseEvolution(String id, {required int serial}) {
    if (!evolutionChoiceReady ||
        serial != evolution.serial ||
        !evolution.options.contains(id)) {
      return false;
    }
    final levels = evolution.resolve(id, expectedSerial: serial);
    meta = meta.withEvolution(levels);
    _metaFloor = meta;
    _evolutionCommitPending = true;
    feedback.emit(FeedbackEvent.upgrade, gameplay: false);
    save().then((_) {
      if (!_disposed) _finishEvolutionCommit();
    });
    notifyListeners();
    return true;
  }

  void _finishEvolutionCommit() {
    if (!prestigeReady || !canPlayRun || _disposed) return;
    _evolutionCommitPending = false;
    if (!evolution.hasChoices && evolution.closingPending) {
      evolution.closingPending = false;
      finishDay();
    } else {
      feedback.setPlaying(running && !paused && !evolutionBlocked);
      _syncMotion();
      notifyListeners();
    }
  }

  PermanentRun permanentRun = PermanentRun();
  bool get normalShopAvailable =>
      canPlayRun && (progress.day > 1 || feeding.dayClosed);
  bool canBuyPermanent(String id) {
    final skill = PermanentSkill.find(id);
    return meta.phase == PrestigePhase.shop &&
        prestigeReady &&
        skill != null &&
        !meta.owns(id) &&
        meta.stars >= skill.price;
  }

  bool buyPermanent(String id) {
    if (!canBuyPermanent(id)) return false;
    meta = meta.purchase(id);
    _metaFloor = meta;
    save();
    feedback.emit(FeedbackEvent.upgrade, gameplay: false);
    notifyListeners();
    return true;
  }

  bool get canPlayRun => meta.phase == PrestigePhase.playing;

  void _clearRun() {
    permanentRun = PermanentRun();
    evolution = EvolutionRun(
      levels: meta.evolutionLevels,
      randomState: (_eventRandomState ^ meta.runId) & 0xffffffff,
      cardRandom: (_eventRandomState ^ (meta.runId * 7919)) & 0xffffffff,
    );
    _evolutionCommitPending = false;
    _rewardTransitionRemaining = 0;
    feedback.setPlaying(false);
    feedback.reset();
    recoveryMessage = null;
    release(cancel: true);
    board?.enterClosing();
    board?.blackHole.finishDay();
    board = null;
    cycle = null;
    paused = false;
    economy.balance = economy.collected = economy.generated = 0;
    progress.day = 1;
    progress.record = 0;
    progress.last = null;
    levels.clear();
    _grandfathered.clear();
    _previousTree.clear();
    _retiredRunLevels.clear();
    selectedTool = BallTool.hand;
    _launcherPosition = const Vec(285, 510);
    _launcherAngle = math.pi * 1.75;
    feeding = FeedingProgress(startDay: 1, target: feedingInitialQuota);
    rewards = _newRewards();
    rewardVisuals = _newVisuals();
    debugForceGravity = false;
    debugBlackHoleObjects = 0;
    debugGravityTilt = 'sensor';
    _debugFeedingTrials = false;
    _debugReports.clear();
    _debugMaxCombo = 1;
    _accumulator = _checkpoint = _uiClock = 0;
    _syncMotion();
  }

  bool _endRun({required bool voluntary}) {
    if (!canPlayRun) return false;
    meta = meta.end(voluntary: voluntary);
    _metaFloor = meta;
    _clearRun();
    save();
    notifyListeners();
    return true;
  }

  bool continueToPrestigeShop() {
    if (meta.phase != PrestigePhase.defeat || !prestigeReady) return false;
    meta = meta.openShop();
    _metaFloor = meta;
    save();
    notifyListeners();
    return true;
  }

  bool beginNewRun() {
    if (meta.phase != PrestigePhase.shop || !prestigeReady) return false;
    meta = meta.newRun();
    _metaFloor = meta;
    _clearRun();
    if (meta.owns(PermanentSkill.inheritance)) economy.balance = 100;
    final newRunId = meta.runId;
    save().then((_) {
      if (!_disposed && meta.runId == newRunId && canPlayRun && prestigeReady) {
        startDay();
      }
    });
    notifyListeners();
    return true;
  }

  final progress = Progress();
  late FeedingProgress feeding;
  bool _debugFeedingTrials = false;
  final levels = <String, int>{};
  final _grandfathered = <String, int>{};
  final _previousTree = <String, int>{};
  final _retiredRunLevels = <String, int>{};
  BallTool selectedTool = BallTool.hand;
  Vec _launcherPosition = const Vec(285, 510);
  double _launcherAngle = math.pi * 1.75;
  Board? board;
  DayCycle? cycle;
  bool paused = false;
  bool sound = true;
  bool haptics = true;
  double effectsVolume = .8;
  void _feedbackPreferences() => feedback.preferences(
    sound: sound,
    haptics: haptics,
    volume: effectsVolume,
  );
  void setEffectsVolume(double value) {
    if (!value.isFinite || value < 0 || value > 1) return;
    effectsVolume = value;
    _feedbackPreferences();
    save();
    notifyListeners();
  }

  bool visualFeedback = false;
  String? saveError;
  String? recoveryMessage;
  double _accumulator = 0, _uiClock = 0, _checkpoint = 0;
  String? _lastSaved;
  Future<void> _writes = Future.value();
  String? _pendingSave;
  int _pendingMetaRevision = 0;
  bool _saving = false;
  bool _disposed = false;
  String? _debugBaseline;
  FeedbackConfig? _feedbackBaseline;
  void debugSetFeedbackParameter(String key, double value) {
    if (!debugEnabled || running || !FeedbackConfig.ranges.containsKey(key)) {
      return;
    }
    try {
      final config = feedback.config.changed(key, value);
      feedback.reset();
      feedback.config = config;
      notifyListeners();
    } on FormatException {
      /* Reject incompatible DEBUG threshold combinations. */
    }
  }

  void debugPreviewFeedback(FeedbackEvent event) {
    if (!debugEnabled || running) return;
    feedback.emit(event, gameplay: false);
  }

  bool _debugFullTree = true;
  final _debugReports = <DebugDayReport>[];
  List<DebugDayReport> get debugReports => List.unmodifiable(_debugReports);
  int _debugMaxCombo = 1;
  bool get debugEnabled => _debugBaseline != null;
  bool get debugFullTree => debugEnabled && _debugFullTree;
  bool get running => cycle != null;
  DayPhase get phase => cycle?.phase ?? DayPhase.night;

  Future<void> load() async {
    var recoveredPrestige = false;
    if (store is PrestigeStore) {
      final checkpoints = await (store as PrestigeStore)
          .loadPrestigeCandidates();
      if (checkpoints.isNotEmpty) {
        final ranked = <({String raw, int revision})>[];
        for (final raw in checkpoints) {
          try {
            final data = jsonDecode(raw) as Map<String, dynamic>;
            if (data['version'] != 10 &&
                data['version'] != 11 &&
                data['version'] != 12 &&
                data['version'] != 13 &&
                data['version'] != 14 &&
                data['version'] != 15 &&
                data['version'] != 16) {
              throw const FormatException('Checkpoint incompatible');
            }
            final state = MetaProgress.fromJson(
              data['meta'] as Map<String, dynamic>,
            );
            ranked.add((raw: raw, revision: state.revision));
          } on Object {
            /* A second current copy may recover a torn checkpoint. */
          }
        }
        ranked.sort((a, b) => b.revision.compareTo(a.revision));
        for (final checkpoint in ranked.where(
          (c) => c.revision == ranked.first.revision,
        )) {
          try {
            restore(checkpoint.raw);
            _durableMetaRevision = meta.revision;
            recoveredPrestige = true;
            break;
          } on Object {
            /* Try the other complete copy; never revive an old run. */
          }
        }
        if (!recoveredPrestige) {
          throw const FormatException(
            'El checkpoint de prestigio no se puede leer. No se ha recuperado una partida antigua.',
          );
        }
      }
    }
    final candidates = await store.loadCandidates();
    if (candidates.isEmpty) {
      if (recoveredPrestige) {
        recoveryMessage = 'Prestigio recuperado desde su checkpoint.';
      }
      if(_evolutionCommitPending && prestigeReady) { _finishEvolutionCommit(); await pendingWrites; }
      return;
    }
    for (var i = 0; i < candidates.length; i++) {
      try {
        restore(candidates[i]);
        _lastSaved = candidates[i];
        if (meta.revision > _durableMetaRevision) await save();
        if (i > 0) {
          recoveryMessage = 'Partida recuperada desde la copia de seguridad.';
        }
        if(_evolutionCommitPending && prestigeReady) { _finishEvolutionCommit(); await pendingWrites; }
        return;
      } on Object {
        // Try the previous complete snapshot before offering an explicit reset.
      }
    }
    if (recoveredPrestige) {
      recoveryMessage =
          'Prestigio recuperado: la partida anterior ya había terminado.';
      if(_evolutionCommitPending && prestigeReady) { _finishEvolutionCommit(); await pendingWrites; }
      return;
    }
    throw const FormatException(
      'El guardado y su copia no se pueden leer. No se han sobrescrito.',
    );
  }

  void startDay() {
    if (running || !canPlayRun || !prestigeReady) return;
    _rewardTransitionRemaining = 0;
    if (feeding.dayClosed || progress.last?.day == progress.day) progress.day++;
    feeding.beginDay(progress.day);
    _retiredRunLevels.clear();
    final settings = catalog.settings(levels);
    _eventRandomState = (1664525 * _eventRandomState + 1013904223) & 0xffffffff;
    permanentRun.beginDay(
      goldenTime: meta.owns(PermanentSkill.gold)
          ? settings['production_duration'] *
                (.05 + .85 * (_eventRandomState / 0x100000000))
          : null,
    );
    feedback.reset();
    _feedbackPreferences();
    feedback.setPlaying(true);
    board = Board(
      settings,
      absorption: AbsorptionEffects(config: feedback.config),
      randomState: progress.day * 7919,
      tool: selectedTool,
      gravitySupported: gravityAvailable,
      gravitySeed: _eventRandomState,
      blackHoleSeed: _eventRandomState,
      launcherPosition: _launcherPosition,
      launcherAngle: _launcherAngle,
      forcedBlackHoles: debugEnabled ? debugBlackHoleObjects : 0,
      forceGravity: debugEnabled && debugForceGravity,
    );
    evolution.levels = meta.evolutionLevels;
    evolution.beginDay();
    board!.evolution = evolution;
    board!.permanentRun = permanentRun;
    board!.productionEcho = meta.owns(PermanentSkill.echo);
    debugForceGravity = false;
    debugBlackHoleObjects = 0;
    cycle = DayCycle(production: settings['production_duration'], closing: 0);
    economy.begin();
    rewards = _newRewards();
    rewardVisuals = _newVisuals();
    rewardVisuals.collection.begin('${meta.runId}:${progress.day}');
    rewardFrameMetrics.clear();
    if (debugEnabled) {
      for (
        var i = 0;
        i < math.min(debugCoinRainCaptures, settings['ball_limit'].toInt());
        i++
      ) {
        board!.balls.add(Ball(board!.nextId++, board!.holePosition, Vec.zero));
      }
      debugCoinRainCaptures = 0;
    }
    board!.syncHoleGrowth(feeding.growths);
    board!.enableAutomaticCoins();
    board!.starBubbles = _newBubbles(board!)..populateImmediate();
    board!.bubbleGravity = debugEnabled && debugBubbleGravity;
    board!.bubbleBlackHole = debugEnabled && debugBubbleBlackHole;
    _debugMaxCombo = 1;
    paused = false;
    _accumulator = 0;
    _checkpoint = 0;
    _syncMotion();
    save();
    notifyListeners();
  }

  double _rewardTransitionRemaining = 0;
  bool get rewardTransitionActive =>
      !_disposed &&
      !running &&
      !_backgrounded &&
      _rewardTransitionRemaining > 0;
  void advanceRewardTransition(double dt) {
    if (!rewardTransitionActive || !dt.isFinite || dt <= 0) return;
    dt = dt.clamp(0, .1);
    _rewardTransitionRemaining -= dt;
    final before = rewardVisuals.arrivedQuantity;
    rewardVisuals.advance(dt, allowEmission: false);
    if (rewardVisuals.arrivedQuantity > before) {
      feedback.emit(
        FeedbackEvent.coinIn,
        count: rewardVisuals.arrivedQuantity - before,
        gameplay: false,
      );
    }
    if (_rewardTransitionRemaining <= 0 || rewardVisuals.activeCount == 0) {
      rewardVisuals.clear(preserveCollection: true);
      _rewardTransitionRemaining = 0;
    }
    rewardRepaint.notifyListeners();
  }

  int _frameEmissionStart = 0;
  void tick(double dt) {
    if (_disposed || !running || paused || evolutionBlocked || !dt.isFinite) {
      return;
    }
    final generatedBefore = economy.generated;
    final metaBefore = meta.revision;
    _frameEmissionStart = rewardVisuals.emittedObjects;
    final quotaBefore = feeding.period;
    rewardVisuals.observeFrame(dt);
    _accumulator += dt.clamp(0.0, .1);
    while (_accumulator + 1e-9 >= 1 / 60 && running && !evolutionBlocked) {
      _accumulator -= 1 / 60;
      final clock = cycle!;
      final producing = clock.phase == DayPhase.production;
      // Split at the production boundary, and never simulate beyond day end.
      final boundary = producing
          ? clock.remaining - clock.closing
          : clock.remaining;
      final step = math.min(1 / 60, boundary);
      _step(step, producing);
      if (running && !evolutionBlocked && step < 1 / 60) {
        _step(math.min(1 / 60 - step, cycle!.remaining), false);
      }
    }
    if (running &&
        (economy.generated != generatedBefore || meta.revision != metaBefore)) {
      save();
    }
    rewardRepaint.notifyListeners();
    _uiClock += dt.clamp(0.0, .1);
    _checkpoint += dt.clamp(0.0, .1);
    if (_checkpoint >= 5) {
      _checkpoint = 0;
      save();
    }
    if (_uiClock >= .1 || feeding.period != quotaBefore) {
      _uiClock = 0;
      notifyListeners();
    }
  }

  void _step(double dt, bool producing) {
    if (dt <= 0) return;
    board!.gravitySupported = gravityAvailable;
    board!.gravityTilt = _debugTilt ?? motion.tilt;
    board!.starBubbles ??= _newBubbles(board!);
    final beforeContact = board!.contactSerial,
        beforeBat = board!.batImpactSerial,
        beforeShots = board!.launcher.shots,
        beforeCrystal = board!.starBubbles?.contactSerial ?? 0;
    final events = board!.update(dt, producing: producing);
    if (events.captured > 0) {
      feedback.emit(FeedbackEvent.capture, count: events.captured);
    }
    if (board!.contactSerial > beforeContact) {
      feedback.emit(
        FeedbackEvent.collision,
        count: board!.contactSerial - beforeContact,
        strength: board!.contactStrength,
      );
    }
    if (board!.batImpactSerial > beforeBat) {
      feedback.emit(FeedbackEvent.bat, strength: board!.lastBatImpactStrength);
    }
    if (board!.launcher.shots > beforeShots) {
      feedback.emit(FeedbackEvent.launcher);
    }
    if ((board!.starBubbles?.contactSerial ?? 0) > beforeCrystal) {
      feedback.emit(
        FeedbackEvent.crystal,
        strength: board!.starBubbles!.contactStrength,
      );
    }
    feedback.motion(board!.rollingActivity);
    if (debugEnabled) {
      _debugMaxCombo = math.max(_debugMaxCombo, board!.combo.multiplier);
    }
    // Board food counters are historical monetary rewards. Only captured balls
    // feed AJ-005B, including instant abilities, golden balls and combos equally.
    final completedQuotas = feeding.credit(
      progress.day,
      normal: events.captured,
      instant: 0,
    );
    board!.syncHoleGrowth(feeding.growths);
    for (final quota in completedQuotas) {
      feedback.emit(FeedbackEvent.quota);
      // The ledger high-water mark is checked before drawing: no repeated rolls.
      if (quota > meta.starLedger.quota) {
        var duplicate = false;
        if (meta.owns(PermanentSkill.astral)) {
          _eventRandomState =
              (1664525 * _eventRandomState + 1013904223) & 0xffffffff;
          duplicate = _eventRandomState < 0x80000000;
        }
        _changeStars(
          meta.starLedger.award(
            quota,
            board!.starBubbles!.config,
            duplicate: duplicate,
          ),
        );
        board!.starBubbles?.populateImmediate();
      }
    }
    for (final quota in completedQuotas) {
      evolution.grant(quota);
    }
    final bubbles = board!.starBubbles;
    if (bubbles != null && bubbles.broken.isNotEmpty) {
      final transaction = meta.starLedger.redeem(bubbles.broken);
      _changeStars(transaction.ledger, paid: transaction.paid);
      if (transaction.paid > 0) {
        feedback.emit(FeedbackEvent.star, count: bubbles.broken.length);
      }
      bubbles.broken.clear();
    }
    economy.collect(events.collected);
    for (final value in events.rewards) {
      economy.generated += value;
      if (value == 0) continue;
      final id = rewards.register(value);
      rewardVisuals.add(id, value);
    }
    final beforeEmitted = rewardVisuals.emittedQuantity,
        beforeArrived = rewardVisuals.arrivedQuantity;
    rewardVisuals.geometry(
      board!.holePosition.x,
      board!.holePosition.y,
      board!.captureRadius,
    );
    rewardVisuals.advance(
      dt,
      allowEmission: rewardVisuals.emittedObjects == _frameEmissionStart,
    );
    if (rewardVisuals.emittedQuantity > beforeEmitted) {
      feedback.emit(
        FeedbackEvent.coinOut,
        count: rewardVisuals.emittedQuantity - beforeEmitted,
      );
    }
    if (rewardVisuals.arrivedQuantity > beforeArrived) {
      feedback.emit(
        FeedbackEvent.coinIn,
        count: rewardVisuals.arrivedQuantity - beforeArrived,
      );
    }
    final arrived = rewards.advance(dt);
    if (arrived > 0) {
      economy.collect(arrived);
      rewardVisuals.receipt();
    }
    cycle!.advance(dt);
    if (producing && cycle!.phase != DayPhase.production) {
      board!.enterClosing();
      _syncMotion();
    }
    if (evolution.hasChoices) {
      evolution.closingPending = cycle!.phase == DayPhase.night;
      _accumulator = 0;
      release(cancel: true);
      feedback.setPlaying(false);
      // The confirmed capture/quota remain audible once as UI feedback while
      // gameplay loops and timers are suspended by the selector.
      if (events.captured > 0) {
        feedback.emit(
          FeedbackEvent.capture,
          count: events.captured,
          gameplay: false,
        );
      }
      if (completedQuotas.isNotEmpty) {
        feedback.emit(
          FeedbackEvent.quota,
          count: completedQuotas.length,
          gameplay: false,
        );
      }
      _syncMotion();
      save();
      notifyListeners();
    } else if (cycle!.phase == DayPhase.night) {
      finishDay();
    }
  }

  void finishDay() {
    if (!running || evolutionBlocked) return;
    economy.collect(rewards.settle());
    rewardVisuals.stopEmitting();
    _rewardTransitionRemaining = rewardVisuals.activeCount > 0 ? .45 : 0;
    if (_rewardTransitionRemaining == 0) {
      rewardVisuals.clear(preserveCollection: true);
    }
    rewardRepaint.notifyListeners();
    board!.absorption.clear();
    feedback.setPlaying(false);
    board!.enterClosing();
    if (debugEnabled) {
      _debugReports.add(
        DebugDayReport(
          day: progress.day,
          spawned: board!.spawned,
          captured: board!.captured,
          goldenCaptured: board!.goldenCaptured,
          maxCombo: _debugMaxCombo,
          generated: economy.generated,
          collected: economy.collected,
        ),
      );
      if (_debugReports.length > 20) _debugReports.removeAt(0);
    }
    // All confirmed captures, quota transitions and P01/P02 events were handled
    // in _step before reaching this boundary. Never give moving balls extra time.
    if (feeding.expiresAt(progress.day)) {
      _endRun(voluntary: false);
      return;
    }
    final result = DayResult(
      day: progress.day,
      income: economy.collected,
      generated: economy.generated,
      captured: board!.captured,
      previousIncome: progress.last?.income,
      collectedCoins: board!.automaticCoins
          ? Map.unmodifiable(_countsFor(economy.collected))
          : board!.collectedCoins == null
          ? null
          : Map.unmodifiable(board!.collectedCoins!),
    );
    release(cancel: true);
    economy.bank();
    _launcherPosition = board!.launcher.position;
    _launcherAngle = board!.launcher.angle;
    board!.blackHole.finishDay();
    feeding.finishDay(progress.day);
    progress.finish(result);
    board = null;
    cycle = null;
    paused = false;
    _syncMotion();
    _accumulator = 0;
    save();
    notifyListeners();
  }

  void touch(Vec position, {double? time}) {
    if (!running || paused || evolutionBlocked || _backgrounded) return;
    board!.gravitySupported = gravityAvailable;
    final blackBefore = board!.blackHole.activations,
        gravityBefore = board!.gravity.remaining;
    economy.collect(board!.touch(position, time: time));
    if (board!.blackHole.activations > blackBefore ||
        (gravityBefore == 0 && board!.gravity.remaining > 0)) {
      feedback.emit(FeedbackEvent.special);
    }
    notifyListeners();
  }

  void drag(Vec position, {double? time}) {
    if (running && !paused) {
      final collected = board!.drag(position, time: time);
      economy.collect(collected);
      if (collected > 0) notifyListeners();
    }
  }

  void release({bool cancel = false, double? time}) {
    final before = board?.gravity.revision;
    final beforeBlackHole = board?.blackHole.revision;
    final saveLauncherPose =
        board?.holdingLauncher == true && !cancel && !paused && !_backgrounded;
    final collected =
        board?.releasePointer(
          cancel: cancel || paused || _backgrounded,
          time: time,
        ) ??
        0;
    economy.collect(collected);
    final hit =
        before != board?.gravity.revision ||
        beforeBlackHole != board?.blackHole.revision;
    if (hit || saveLauncherPose) save();
    if (collected > 0 || hit || saveLauncherPose) notifyListeners();
  }

  bool grabSecondBroomPoint(Vec position) =>
      running && !paused && board!.grabSecondBroomPoint(position);

  void dragSecondBroomPoint(Vec position) {
    if (running && !paused) board!.dragSecondBroomPoint(position);
  }

  void releaseSecondBroomPoint({bool promote = false}) {
    if (!running) return;
    if (promote) {
      board!.promoteSecondBroomPoint();
    } else {
      board!.releaseSecondBroomPoint();
    }
  }

  bool toolAvailable(BallTool tool) {
    final settings = catalog.settings(levels);
    return switch (tool) {
      BallTool.hand => true,
      BallTool.broom => settings['broom_unlocked'] > 0,
      BallTool.vee => settings['v_unlocked'] > 0,
      BallTool.bat => settings['bat_power'] > 0,
    };
  }

  void selectTool(BallTool tool) {
    if (!toolAvailable(tool) || (running && paused)) return;
    selectedTool = tool;
    board?.selectTool(tool);
    save();
    notifyListeners();
  }

  void pause() {
    if (!running || paused) return;
    paused = true;
    feedback.setPlaying(false);
    _syncMotion();
    _accumulator = 0;
    release(cancel: true);
    save();
    notifyListeners();
  }

  void resume() {
    if (_backgrounded || evolutionBlocked) return;
    paused = false;
    feedback.setPlaying(running);
    _feedbackPreferences();
    _syncMotion();
    _accumulator = 0;
    notifyListeners();
  }

  bool activateSpecial(SpecialAbility ability) {
    if (!running ||
        paused ||
        evolutionBlocked ||
        phase != DayPhase.production ||
        !board!.activateSpecial(ability)) {
      return false;
    }
    feedback.emit(FeedbackEvent.special);
    save();
    notifyListeners();
    return true;
  }

  void setSound(bool value) {
    sound = value;
    _feedbackPreferences();
    if (value) {
      unawaited(feedback.prepare());
    }
    save();
    notifyListeners();
  }

  void setHaptics(bool value) {
    haptics = value;
    _feedbackPreferences();
    save();
    notifyListeners();
  }

  void setVisualFeedback(bool value) {
    visualFeedback = value;
    save();
    notifyListeners();
  }

  /// Debug play is temporary: purchases and days never reach the real save.
  bool enterDebug() {
    if (debugEnabled || running || !canPlayRun || !prestigeReady) return false;
    final baseline = snapshot();
    save();
    _debugBaseline = baseline;
    _feedbackBaseline = feedback.config;
    _debugFeedingTrials = false;
    _debugReports.clear();
    _debugFullTree = true;
    notifyListeners();
    return true;
  }

  void exitDebug() {
    final baseline = _debugBaseline;
    if (baseline == null) return;
    board?.blackHole.finishDay();
    _allowPrestigeRollback = true;
    try {
      restore(baseline);
    } finally {
      _allowPrestigeRollback = false;
    }
    _debugBaseline = null;
    if (_feedbackBaseline != null) feedback.config = _feedbackBaseline!;
    _feedbackBaseline = null;
    _debugStars = null;
    debugBubbleGravity = debugBubbleBlackHole = false;
    _debugRewardLimit = null;
    _debugRewardParameters.clear();
    debugCoinRainCaptures = 0;
    rewardVisuals.debugLimit = null;
    _debugFeedingTrials = false;
    debugForceGravity = false;
    debugGravityTilt = 'sensor';
    debugBlackHoleObjects = 0;
    _syncMotion();
    _debugReports.clear();
    _debugFullTree = true;
    _checkpoint = _uiClock = 0;
    notifyListeners();
  }

  void setDebugFullTree(bool value) {
    if (!debugEnabled) return;
    _debugFullTree = value;
    notifyListeners();
  }

  bool debugPurchase(
    String id,
    int targetLevel, {
    bool confirmPrestige = false,
  }) {
    if (!debugEnabled || running || !canPlayRun) return false;
    if (id == 'prestige') {
      return targetLevel == 1 && confirmPrestige && _endRun(voluntary: true);
    }
    final definition = catalog.definitions.where((d) => d.id == id).firstOrNull;
    if (definition == null ||
        targetLevel < 1 ||
        targetLevel > definition.levels.length ||
        targetLevel <= (levels[id] ?? 0)) {
      return false;
    }
    final next = Map<String, int>.of(levels);
    void unlock(UpgradeDefinition definition, int level) {
      if ((next[definition.id] ?? 0) >= level) return;
      for (final upgrade in definition.levels.take(level)) {
        for (final requirement in upgrade.requirements) {
          final parts = requirement.split(':');
          unlock(
            catalog.definitions.firstWhere((d) => d.id == parts[0]),
            int.parse(parts[1]),
          );
        }
      }
      next[definition.id] = level;
    }

    unlock(definition, targetLevel);
    _applyDebugLevels(next);
    feedback.emit(FeedbackEvent.upgrade, gameplay: false);
    return true;
  }

  bool debugBuyAll() {
    if (!debugEnabled || running || !canPlayRun) return false;
    _applyDebugLevels({
      for (final definition in catalog.definitions)
        if (definition.id != 'prestige')
          definition.id: definition.levels.length,
    });
    return true;
  }

  void _applyDebugLevels(Map<String, int> next) {
    catalog.validateLevels(
      next,
      grandfathered: _grandfathered,
      previousTree: _previousTree,
      retiredRemoved: true,
    );
    if ((next['bat'] ?? 0) > (levels['bat'] ?? 0)) {
      selectedTool = BallTool.bat;
    } else if ((next['broom_v'] ?? 0) > (levels['broom_v'] ?? 0)) {
      selectedTool = BallTool.vee;
    } else if ((next['broom'] ?? 0) > (levels['broom'] ?? 0)) {
      selectedTool = BallTool.broom;
    }
    levels
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  bool get debugFeedingQuotas => debugEnabled && _debugFeedingTrials;
  int get feedingInitialQuota => FeedingProgress.initialQuota;
  void debugConfigureFeeding({required bool quotas, int? target}) {
    if (!debugEnabled || running || !canPlayRun) return;
    final amount = target ?? feedingInitialQuota;
    if (amount < 1 || amount > 1000000) return;
    _debugFeedingTrials = quotas;
    _changeStars(
      StarLedger(
        nextId: meta.starLedger.nextId,
        pending: meta.starLedger.pending,
      ),
    );
    evolution.lastQuota = 0;
    evolution.pending = 0;
    evolution.options = [];
    evolution.closingPending = false;
    final closed = feeding.dayClosed || progress.last?.day == progress.day;
    feeding = FeedingProgress(
      startDay: progress.day,
      target: quotas ? amount : null,
    );
    if (closed) {
      feeding.dayClosed = true;
      feeding.completedDays = 1;
    }
    notifyListeners();
  }

  void debugRestartFeedingPeriod() => debugConfigureFeeding(
    quotas: debugFeedingQuotas,
    target: feeding.initialTarget?.toInt(),
  );
  void debugSimulateEmptyDay() {
    if (!debugEnabled || running) return;
    startDay();
    finishDay();
  }

  void debugAddCoins() {
    if (!debugEnabled || running || !canPlayRun) return;
    economy.balance += 1000;
    notifyListeners();
  }

  void debugReset() {
    if (!debugEnabled || running || !canPlayRun) return;
    _changeStars(const StarLedger());
    permanentRun = PermanentRun();
    evolution = EvolutionRun(levels: meta.evolutionLevels);
    _evolutionCommitPending = false;
    _debugReports.clear();
    _debugFeedingTrials = false;
    feeding = FeedingProgress(startDay: 1, target: feedingInitialQuota);
    debugForceGravity = false;
    debugGravityTilt = 'sensor';
    debugBlackHoleObjects = 0;
    _launcherPosition = const Vec(285, 510);
    _launcherAngle = math.pi * 1.75;
    levels.clear();
    _grandfathered.clear();
    _previousTree.clear();
    selectedTool = BallTool.hand;
    economy.balance = 0;
    economy.begin();
    progress
      ..day = 1
      ..record = 0
      ..last = null;
    notifyListeners();
  }

  String? purchaseBlock(UpgradeDefinition definition) {
    if (UpgradeCatalog.retiredIds.contains(definition.id)) {
      return 'Mejora retirada';
    }
    if (!canPlayRun || !prestigeReady) return 'Partida no disponible';
    if (!normalShopAvailable && !debugEnabled) {
      return 'Completa la primera jornada';
    }
    if (running) return 'Disponible durante la noche';
    final level = levels[definition.id] ?? 0;
    if (level >= definition.levels.length) return 'Completado';
    final next = definition.levels[level];
    if (!catalog.requirementsMet(next, levels)) {
      final parts = next.requirements
          .firstWhere((item) {
            final parts = item.split(':');
            return (levels[parts[0]] ?? 0) < int.parse(parts[1]);
          })
          .split(':');
      final name = catalog.definitions.firstWhere((d) => d.id == parts[0]).name;
      return 'Requiere $name · nivel ${parts[1]}';
    }
    if (economy.balance < next.cost) {
      return 'Faltan ${next.cost - economy.balance} monedas';
    }
    return null;
  }

  bool purchase(UpgradeDefinition definition, {bool confirmPrestige = false}) {
    if (purchaseBlock(definition) != null) return false;
    if (definition.id == 'prestige' && !confirmPrestige) return false;
    final level = levels[definition.id] ?? 0;
    if (!economy.spend(definition.levels[level].cost)) return false;
    if (definition.id == 'prestige') {
      final ended = _endRun(voluntary: true);
      if (ended) feedback.emit(FeedbackEvent.upgrade, gameplay: false);
      return ended;
    }
    levels[definition.id] = level + 1;
    feedback.emit(FeedbackEvent.upgrade, gameplay: false);
    if (definition.id == 'bat') selectedTool = BallTool.bat;
    if (definition.id == 'broom') selectedTool = BallTool.broom;
    if (definition.id == 'broom_v') selectedTool = BallTool.vee;
    save();
    notifyListeners();
    return true;
  }

  String snapshot() => jsonEncode({
    'version': 16,
    'meta': meta.toJson(),
    'evolution': evolution.toJson(),
    'permanentRun': permanentRun.toJson(),
    'feeding': feeding.toJson(),
    'eventRandom': _eventRandomState,
    'launcherPose': {
      'position': (board?.launcher.position ?? _launcherPosition).toJson(),
      'angle': board?.launcher.angle ?? _launcherAngle,
    },
    'grandfathered': _grandfathered,
    'previousTree': _previousTree,
    'tool': selectedTool.name,
    'day': progress.day,
    'balance': economy.balance,
    'record': progress.record,
    'levels': levels,
    'sound': sound,
    'haptics': haptics,
    'effectsVolume': effectsVolume,
    'visualFeedback': visualFeedback,
    'last': progress.last?.toJson(),
    'run': !running
        ? null
        : {
            'remaining': cycle!.remaining,
            'rewards': rewards.toJson(),
            'rewardPresentation': rewardVisuals.toJson(),
            'rewardCounts': _countsFor(
              economy.generated,
            ).map((key, value) => MapEntry('$key', value)),
            'retiredLevels': _retiredRunLevels,
            'collected': economy.collected,
            'generated': economy.generated,
            'settings': board!.settings.toJson(),
            'balanceVersion': board!.settings.balanceVersion,
            'board': board!.toJson(),
            'starBubbles': (board!.starBubbles ?? _newBubbles(board!)).toJson(),
          },
  });

  void restore(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final legacy = json['version'] == 1;
    if (!legacy &&
        json['version'] != 2 &&
        json['version'] != 3 &&
        json['version'] != 4 &&
        json['version'] != 5 &&
        json['version'] != 6 &&
        json['version'] != 7 &&
        json['version'] != 8 &&
        json['version'] != 9 &&
        json['version'] != 10 &&
        json['version'] != 11 &&
        json['version'] != 12 &&
        json['version'] != 13 &&
        json['version'] != 14 &&
        json['version'] != 15 &&
        json['version'] != 16) {
      throw const FormatException('Versión de guardado no compatible');
    }
    if ((json['version'] as int) >= 10 &&
        json['meta'] is! Map<String, dynamic>) {
      throw const FormatException('Falta la metaprogresión');
    }
    if ((json['version'] as int) >= 11 &&
        json['meta']['starLedger'] is! Map<String, dynamic>) {
      throw const FormatException('Falta el registro de estrellas');
    }
    final restoredPermanentRun = json['permanentRun'] == null
        ? PermanentRun()
        : PermanentRun.fromJson(json['permanentRun'] as Map<String, dynamic>);
    final restoredMeta = (json['version'] as int) >= 10
        ? MetaProgress.fromJson(json['meta'] as Map<String, dynamic>)
        : MetaProgress();
    final floor = _metaFloor;
    if ((json['version'] as int) >= 16 &&
        (json['evolution'] is! Map<String, dynamic> ||
            !(json['meta'] as Map).containsKey('evolution'))) {
      throw const FormatException('Falta evolución E03');
    }
    final hasEvolution = (json['version'] as int) >= 16;
    final restoredEvolution = !hasEvolution
        ? EvolutionRun(levels: restoredMeta.evolutionLevels)
        : EvolutionRun.fromJson(
            json['evolution'] as Map<String, dynamic>,
            levels: restoredMeta.evolutionLevels,
          );
    if (!_allowPrestigeRollback &&
        floor != null &&
        (restoredMeta.revision < floor.revision ||
            (restoredMeta.revision == floor.revision &&
                jsonEncode(restoredMeta.toJson()) !=
                    jsonEncode(floor.toJson())))) {
      throw const FormatException(
        'Este guardado pertenece a una partida o metaprogresión anterior',
      );
    }
    if (restoredMeta.phase != PrestigePhase.playing &&
        (json['run'] != null ||
            json['day'] != 1 ||
            json['balance'] != 0 ||
            json['record'] != 0 ||
            json['last'] != null ||
            (json['levels'] as Map).isNotEmpty)) {
      throw const FormatException('Partida activa después del prestigio');
    }
    final day = json['day'] as int,
        balance = json['balance'] as int,
        record = json['record'] as int;
    if (day < 1 || balance < 0 || record < 0) {
      throw const FormatException('Progreso inválido');
    }
    final savedLevels = (json['levels'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as int),
    );
    if ((savedLevels['prestige'] ?? 0) > 0) {
      throw const FormatException('Prestigio comprado sin reiniciar');
    }
    // Old paddle purchases become width upgrades and retain access to the broom.
    if (legacy && (savedLevels['paddle'] ?? 0) > 0) savedLevels['broom'] = 1;
    final oldProgress = (json['version'] as int) < 4;
    final grandfathered = oldProgress
        ? Map<String, int>.of(savedLevels)
        : (json['grandfathered'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, value as int),
          );
    final previousTree = json['version'] == 4
        ? Map<String, int>.of(savedLevels)
        : (json['previousTree'] as Map<String, dynamic>? ?? {}).map(
            (key, value) => MapEntry(key, value as int),
          );
    if ((json['version'] as int) >= 12 &&
        savedLevels.containsKey('hand_grip')) {
      throw const FormatException('Fuerza de agarre retirada');
    }
    catalog.validateLevels(
      savedLevels,
      grandfathered: grandfathered,
      previousTree: previousTree,
      legacy: oldProgress,
      balanceVersion: (json['version'] as int) < 9
          ? 14
          : json['version'] == 9
          ? 15
          : json['version'] == 10
          ? 16
          : json['version'] == 11
          ? 17
          : 20,
      retiredRemoved: (json['version'] as int) >= 9,
    );
    var restoredTool = legacy
        ? ((savedLevels['broom'] ?? 0) > 0 ? BallTool.broom : BallTool.hand)
        : BallTool.values.firstWhere(
            (tool) => tool.name == json['tool'],
            orElse: () => throw const FormatException('Herramienta inválida'),
          );
    final expectedSettings = catalog.settings(savedLevels);
    if (restoredTool == BallTool.broom &&
        expectedSettings['broom_unlocked'] == 0) {
      restoredTool = BallTool.hand;
    }
    if (restoredTool == BallTool.bat && expectedSettings['bat_power'] == 0) {
      throw const FormatException('Bate sin desbloquear');
    }
    if (restoredTool == BallTool.vee && expectedSettings['v_unlocked'] == 0) {
      throw const FormatException('Herramienta sin desbloquear');
    }
    final last = json['last'] == null
        ? null
        : DayResult.fromJson(json['last'] as Map<String, dynamic>);
    if (last != null &&
        (last.day !=
                ((json['version'] as int) >= 15 && json['run'] == null
                    ? day
                    : day - 1) ||
            last.income < 0 ||
            last.generated < last.income ||
            last.captured < 0 ||
            record < last.income ||
            (last.collectedCoins != null &&
                last.collectedCoins!.entries.fold<int>(
                      0,
                      (sum, e) => sum + e.key * e.value,
                    ) !=
                    last.income))) {
      throw const FormatException('Resultado inválido');
    }
    final run = json['run'] as Map<String, dynamic>?;
    Board? restoredBoard;
    DayCycle? restoredCycle;
    var collected = 0, generated = 0;
    if (run != null) {
      final savedSettings = DaySettings.fromJson(
        run['settings'] as Map<String, dynamic>,
      );
      final balanceVersion = !legacy && json['version'] != 2
          ? run['balanceVersion']
          : 1;
      if (balanceVersion is! int ||
          (balanceVersion < 1 || balanceVersion > 20)) {
        throw const FormatException('Versión de balance inválida');
      }
      final runRetired = run['retiredLevels'] == null
          ? <String, int>{}
          : (run['retiredLevels'] as Map<String, dynamic>).map((id, value) {
              final definition = UpgradeCatalog.retiredDefinition(id);
              if (definition == null ||
                  value is! int ||
                  value < 0 ||
                  value > definition.levels.length ||
                  (id == 'hand_grip'
                      ? balanceVersion >= 18
                      : balanceVersion >= 15)) {
                throw const FormatException(
                  'Archivo de compras retiradas inválido',
                );
              }
              return MapEntry(id, value);
            });
      final settings = catalog.settings({
        ...savedLevels,
        ...runRetired,
      }, balanceVersion: balanceVersion);
      if (!savedSettings.values.containsKey('hand_capacity') &&
          (savedLevels['hand'] ?? 0) == 0) {
        savedSettings.values['hand_capacity'] = 1;
      }
      final expected = Map.of(settings.values);
      if (legacy) {
        expected.remove('broom_unlocked');
        expected.remove('v_unlocked');
        expected.remove('coin_sweep');
      }
      if (!mapEquals(savedSettings.values, expected)) {
        throw const FormatException('Configuración de jornada inválida');
      }
      final remaining = (run['remaining'] as num).toDouble();
      if (!remaining.isFinite ||
          remaining < 0 ||
          (remaining == 0 && !restoredEvolution.closingPending) ||
          remaining >
              settings['production_duration'] +
                  ((json['version'] as int) >= 9
                      ? 0
                      : settings['closing_duration'])) {
        throw const FormatException('Tiempo inválido');
      }
      restoredCycle = DayCycle(
        production: settings['production_duration'],
        closing: (json['version'] as int) >= 9
            ? 0
            : settings['closing_duration'],
        remaining: remaining,
      );
      final savedBoard = run['board'] as Map<String, dynamic>;
      if ((json['version'] as int) >= 6 && savedBoard['combo'] == null) {
        throw const FormatException('Falta el estado del combo');
      }
      // An active pre-combo day must keep its original rewards until it ends.
      if ((json['version'] as int) < 6 && savedBoard['combo'] != null) {
        throw const FormatException('Combo en guardado anterior');
      }
      restoredBoard = Board.fromJson(settings, savedBoard);
      if (balanceVersion >= 8 &&
          restoredBoard.combo.enabled != (settings['combo_unlocked'] > 0)) {
        throw const FormatException('Racha sin desbloquear');
      }
      if (balanceVersion >= 11) {
        final elapsed = math.min(
          settings['production_duration'],
          settings['production_duration'] + restoredCycle.closing - remaining,
        );
        if ((restoredBoard.gravity.elapsed - elapsed).abs() > 1e-6 ||
            (restoredCycle.phase != DayPhase.production &&
                (restoredBoard.gravity.hasObject ||
                    restoredBoard.gravity.active))) {
          throw const FormatException('Tiempo de Gravedad incoherente');
        }
      }
      if (balanceVersion >= 12) {
        final event = restoredBoard.blackHole;
        final elapsed = math.min(
          settings['production_duration'],
          settings['production_duration'] + restoredCycle.closing - remaining,
        );
        if ((event.elapsed - elapsed).abs() > 1e-6 ||
            event.ended != (restoredCycle.phase != DayPhase.production)) {
          throw const FormatException('Tiempo de Agujero negro incoherente');
        }
      }
      restoredBoard.tool = restoredTool;
      if (restoredCycle.phase != DayPhase.production) {
        restoredBoard.enterClosing();
      }
      collected = run['collected'] as int;
      generated = run['generated'] as int;
      if (collected < 0 ||
          (restoredBoard.collectedCoins != null &&
              restoredBoard.collectedCoins!.entries.fold<int>(
                    0,
                    (sum, e) => sum + e.key * e.value,
                  ) !=
                  collected) ||
          ((json['version'] as int) < 9 &&
              generated != collected + restoredBoard.pending) ||
          generated !=
              (restoredBoard.captured +
                          9 * restoredBoard.goldenCaptured +
                          restoredBoard.combo.bonusUnits) *
                      settings['ball_value'].toInt() +
                  restoredBoard.evolutionBonus) {
        throw const FormatException('Contabilidad inválida');
      }
    }
    var restoredRewards = _newRewards();
    if (run != null) {
      if (collected > generated) throw const FormatException('Cobro inválido');
      if ((json['version'] as int) >= 9) {
        final ledger = run['rewards'];
        if (ledger is! Map<String, dynamic> || !restoredBoard!.automaticCoins) {
          throw const FormatException('Falta el registro de recompensas');
        }
        restoredRewards = RewardDelivery.fromJson(
          ledger,
          outstanding: generated - collected,
          delay: catalog.base['reward_delay']!,
          capacity: catalog.base['reward_ledger_limit']!.toInt(),
        );
      } else {
        // Old visible coins and reserves are guaranteed too: settle the exact gap.
        if (generated > collected) {
          restoredRewards.register(generated - collected);
        }
      }
    }
    final restoredCounts = run?['rewardCounts'] == null
        ? <int, int>{
            for (final s in CoinDenomination.split(generated))
              s.denomination.amount: s.count,
          }
        : CoinDenomination.readCounts(run!['rewardCounts']);
    if (restoredCounts.entries.fold<int>(
          0,
          (sum, e) => sum + e.key * e.value,
        ) !=
        generated) {
      throw const FormatException('Desglose de recompensas incoherente');
    }
    final restoredVisuals = _newVisuals();
    restoredVisuals.collection.begin('${restoredMeta.runId}:$day');
    final presentation = run?['rewardPresentation'];
    if (presentation != null) {
      if (presentation is! Map<String, dynamic>) {
        throw const FormatException('Presentación inválida');
      }
      restoredVisuals.restorePresentation(presentation, expected: generated);
      if (presentation['collection'] != null) {
        try {
          restoredVisuals.collection.restore(
            presentation['collection'],
            identity: '${restoredMeta.runId}:$day',
            planned: restoredVisuals.counts,
          );
        } on FormatException {
          // Optional presentation data cannot discard a valid economic save.
          restoredVisuals.collection.begin('${restoredMeta.runId}:$day');
        }
      } else {
        restoredVisuals.collection.begin('${restoredMeta.runId}:$day');
      }
    } else {
      restoredVisuals.restoreCounts(restoredCounts);
    }
    final savedFeeding = json['feeding'];
    final FeedingProgress restoredFeeding;
    if ((json['version'] as int) >= 8) {
      if (savedFeeding is! Map<String, dynamic>) {
        throw const FormatException('Falta la alimentación');
      }
      if ((json['version'] as int) >= 15 &&
          savedFeeding['rules'] != 'balls-four-days-v2') {
        throw const FormatException('Falta el plazo de cuota');
      }
      if ((json['version'] as int) >= 14) {
        restoredFeeding = FeedingProgress.fromJson(
          savedFeeding,
          day: day,
          running: run != null,
        );
        if (restoredBoard != null &&
            restoredFeeding.startDay <= day &&
            restoredFeeding.runBalls +
                    BigInt.from(restoredFeeding.runCapturedBaseline) !=
                BigInt.from(restoredBoard.captured)) {
          throw const FormatException('Capturas de bolas incoherentes');
        }
      } else {
        final old = LegacyFeedingProgress.fromJson(
          savedFeeding,
          day: day,
          running: run != null,
          requireGrowth: (json['version'] as int) >= 13,
        );
        if (restoredBoard != null &&
            restoredBoard.settings.balanceVersion >= 14 &&
            (old.startDay > day ||
                old.runNormal != restoredBoard.normalFood ||
                old.runInstant != restoredBoard.instantFood)) {
          throw const FormatException('Capturas de alimentación incoherentes');
        }
        restoredFeeding = FeedingProgress.migrate(
          savedFeeding,
          day: day,
          running: run != null,
          requireGrowth: (json['version'] as int) >= 13,
          capturedBaseline: restoredBoard?.captured ?? 0,
        );
      }
    } else {
      // Historical captures cannot be reconstructed without guessing ability use.
      restoredFeeding = FeedingProgress(
        startDay: run == null && last != null ? day - 1 : day,
        target: feedingInitialQuota,
      )..runCapturedBaseline = restoredBoard?.captured ?? 0;
      if (run == null && last != null) {
        restoredFeeding.completedDays = 1;
        restoredFeeding.dayClosed = true;
      }
    }
    final migratedClosedDay =
        (json['version'] as int) < 15 &&
        run == null &&
        restoredMeta.phase == PrestigePhase.playing &&
        (last != null || restoredFeeding.dayClosed);
    final restoredDay = day - (migratedClosedDay ? 1 : 0);
    if (migratedClosedDay) {
      // Historical monetary periods could already point at a fresh period with
      // zero completed days. Align that bookkeeping with the actual closed day.
      restoredFeeding.startDay = math.min(
        restoredFeeding.startDay,
        restoredDay,
      );
      restoredFeeding.completedDays =
          restoredDay - restoredFeeding.startDay + 1;
      restoredFeeding.dayClosed = true;
      restoredFeeding.quotaStartDay = restoredDay;
    }
    if ((json['version'] as int) >= 15 &&
        restoredMeta.phase == PrestigePhase.playing &&
        restoredFeeding.dayClosed &&
        restoredFeeding.expiresAt(day)) {
      throw const FormatException('Cuota vencida sin transición de derrota');
    }
    if (restoredMeta.phase != PrestigePhase.playing &&
        (restoredFeeding.points != BigInt.zero ||
            restoredFeeding.completedDays != 0 ||
            restoredFeeding.period != 1 ||
            restoredFeeding.startDay != 1)) {
      throw const FormatException(
        'Alimentación retenida después de prestigiar',
      );
    }
    if (restoredBoard != null) {
      final savedBubbles = run!['starBubbles'];
      if ((json['version'] as int) >= 11) {
        if (savedBubbles is! Map<String, dynamic>) {
          throw const FormatException('Faltan burbujas de prestigio');
        }
        restoredBoard.starBubbles = StarBubbles.restore(
          savedBubbles,
          restoredMeta.starLedger,
          ballRadius: restoredBoard.radius,
          maximumSpeed: restoredBoard.maximumSpeed,
          hole: restoredBoard.holePosition,
        );
      } else {
        restoredBoard.starBubbles = StarBubbles(
          StarConfig(catalog.base),
          ballRadius: restoredBoard.radius,
          maximumSpeed: restoredBoard.maximumSpeed,
          hole: restoredBoard.holePosition,
        )..sync(restoredMeta.starLedger);
      }
    }
    restoredBoard?.syncHoleGrowth(restoredFeeding.growths);
    if (!hasEvolution) {
      restoredEvolution.lastQuota = restoredFeeding.completed;
      restoredEvolution.dayElapsed = restoredCycle == null
          ? 0
          : (restoredCycle.production +
                    restoredCycle.closing -
                    restoredCycle.remaining)
                .clamp(0, restoredCycle.production);
    }
    if (restoredEvolution.lastQuota != restoredFeeding.completed ||
        (restoredEvolution.hasChoices && restoredBoard == null) ||
        (restoredEvolution.closingPending &&
            (restoredCycle == null || restoredCycle.phase != DayPhase.night)) ||
        (restoredBoard != null &&
            (restoredEvolution.dayElapsed >
                restoredBoard.settings['production_duration'] + 1e-6)) ||
        (restoredBoard != null &&
            restoredBoard.evolutionBonus > 0 &&
            (restoredMeta.evolutionLevels[EvolutionSkill.of(
                      EvolutionId.millionaire,
                    ).id] ??
                    0) ==
                0 &&
            (restoredMeta.evolutionLevels[EvolutionSkill.of(
                      EvolutionId.luck,
                    ).id] ??
                    0) ==
                0)) {
      throw const FormatException('Integración E03 incoherente');
    }
    // Commit only after validating every module; a failed load leaves no partial state.
    final savedEventRandom = json['eventRandom'] ?? _eventRandomState;
    if (savedEventRandom is! int ||
        savedEventRandom < 0 ||
        savedEventRandom > 0xffffffff) {
      throw const FormatException('Estado aleatorio de eventos inválido');
    }
    final pose = json['launcherPose'];
    if (pose != null && pose is! Map<String, dynamic>) {
      throw const FormatException('Pose del lanzador inválida');
    }
    final savedPosition = pose == null
        ? const Vec(285, 510)
        : Vec.fromJson(pose['position']);
    final savedAngle = pose == null ? math.pi * 1.75 : pose['angle'];
    if (savedAngle is! num ||
        !savedAngle.isFinite ||
        savedAngle < 0 ||
        savedAngle >= math.pi * 2) {
      throw const FormatException('Orientación del lanzador inválida');
    }
    final savedLauncher = Launcher(
      catalog.settings(savedLevels),
      position: savedPosition,
      angle: savedAngle.toDouble(),
    );
    if ((savedPosition - savedLauncher.position).length > 1e-6) {
      throw const FormatException('Posición del lanzador inválida');
    }
    final savedVolume = json['effectsVolume'] ?? .8;
    if (savedVolume is! num ||
        !savedVolume.isFinite ||
        savedVolume < 0 ||
        savedVolume > 1) {
      throw const FormatException('Volumen inválido');
    }
    final savedSound = json['sound'] as bool;
    final savedHaptics = json['haptics'] as bool? ?? true;
    final savedVisualFeedback = json['visualFeedback'] as bool? ?? false;
    if (json['permanentRun'] != null) {
      if ((!restoredMeta.owns(PermanentSkill.echo) &&
              (restoredPermanentRun.cycles != 0 ||
                  restoredPermanentRun.pendingEcho != 0)) ||
          (!restoredMeta.owns(PermanentSkill.gold) &&
              (restoredPermanentRun.goldenAt != null ||
                  restoredPermanentRun.goldenSpawned)) ||
          (restoredMeta.phase != PrestigePhase.playing &&
              (restoredPermanentRun.cycles != 0 ||
                  restoredPermanentRun.pendingEcho != 0 ||
                  restoredPermanentRun.goldenAt != null ||
                  restoredPermanentRun.elapsed != 0))) {
        throw const FormatException('Habilidades temporales incoherentes');
      }
      if (restoredBoard != null && restoredPermanentRun.goldenAt != null) {
        final duration = restoredBoard.settings['production_duration'];
        final elapsed =
            duration + restoredCycle!.closing - restoredCycle.remaining;
        if (restoredPermanentRun.goldenAt! >= duration ||
            (restoredPermanentRun.elapsed - elapsed).abs() > 1e-6 ||
            (restoredPermanentRun.goldenSpawned &&
                restoredPermanentRun.elapsed + 1e-9 <
                    restoredPermanentRun.goldenAt!)) {
          throw const FormatException('Reloj de Fiebre dorada incoherente');
        }
      }
    }
    meta = restoredMeta;
    evolution = restoredEvolution;
    _evolutionCommitPending = evolution.closingPending && !evolution.hasChoices;
    restoredBoard?.evolution = evolution;
    permanentRun = restoredPermanentRun;
    restoredBoard?.permanentRun = permanentRun;
    restoredBoard?.productionEcho = meta.owns(PermanentSkill.echo);
    _metaFloor = restoredMeta;
    progress.day = restoredDay;
    progress.record = record;
    progress.last = last;
    final retiredGrip = savedLevels['hand_grip'] ?? 0;
    final gripRefund = retiredGrip == 0
        ? 0
        : UpgradeCatalog.retiredDefinition('hand_grip')!.levels
              .take(retiredGrip)
              .fold<int>(0, (sum, level) => sum + level.cost);
    economy.balance = balance + gripRefund;
    economy.collected = collected;
    economy.generated = generated;
    _retiredRunLevels
      ..clear()
      ..addAll({
        for (final entry in savedLevels.entries)
          if (UpgradeCatalog.retiredIds.contains(entry.key))
            entry.key: entry.value,
      });
    if (run?['retiredLevels'] != null) {
      _retiredRunLevels.addAll(
        (run!['retiredLevels'] as Map<String, dynamic>).cast<String, int>(),
      );
    }
    levels
      ..clear()
      ..addAll(
        savedLevels
          ..removeWhere((id, _) => UpgradeCatalog.retiredIds.contains(id)),
      );
    _grandfathered
      ..clear()
      ..addAll(
        grandfathered
          ..removeWhere((id, _) => UpgradeCatalog.retiredIds.contains(id)),
      );
    _previousTree
      ..clear()
      ..addAll(
        previousTree
          ..removeWhere((id, _) => UpgradeCatalog.retiredIds.contains(id)),
      );
    selectedTool = restoredTool;
    if (legacy) {
      recoveryMessage =
          'Partida actualizada: conservas saldo y mejoras. '
          'Las recompensas ahora se cobran automáticamente.';
    }
    feeding = restoredFeeding;
    _launcherPosition = savedLauncher.position;
    _launcherAngle = savedLauncher.angle;
    _eventRandomState = savedEventRandom;
    board = restoredBoard;
    board?.gravitySupported = gravityAvailable;
    rewards = restoredRewards;
    rewardVisuals = restoredVisuals;
    _rewardTransitionRemaining = 0;
    if (restoredBoard != null) {
      restoredBoard.enableAutomaticCoins();
      economy.collect(rewards.settle());
    }
    final wasClosing = restoredCycle?.phase == DayPhase.closing;
    if (restoredCycle != null && (json['version'] as int) < 9 && !wasClosing) {
      restoredCycle = DayCycle(
        production: restoredCycle.production,
        closing: 0,
        remaining: restoredCycle.remaining - restoredCycle.closing,
      );
    }
    cycle = restoredCycle;
    sound = savedSound;
    haptics = savedHaptics;
    effectsVolume = savedVolume.toDouble();
    feedback.reset();
    feedback.setPlaying(false);
    _feedbackPreferences();
    visualFeedback = savedVisualFeedback;
    paused = running && !evolution.hasChoices;
    _syncMotion();
    _accumulator = 0;
    if (wasClosing) finishDay();
  }

  Future<void> save() {
    if (debugEnabled) return _writes;
    _pendingSave = snapshot();
    _pendingMetaRevision = meta.revision;
    if (!_saving) {
      _saving = true;
      _writes = _drainSaves();
    }
    return _writes;
  }

  Future<void> _drainSaves() async {
    // One write in flight and at most one newer complete snapshot in memory.
    // Every later snapshot includes all previously registered capture rewards.
    while (_pendingSave != null) {
      final data = _pendingSave!;
      final metaRevision = _pendingMetaRevision;
      _pendingSave = null;
      final previousError = saveError;
      try {
        if (metaRevision > _durableMetaRevision) {
          if (store is! PrestigeStore) {
            throw StateError('Guardado de prestigio no disponible');
          }
          await (store as PrestigeStore).savePrestige(data);
          _durableMetaRevision = metaRevision;
          if (!_disposed) notifyListeners();
        }
        await store.save(data, previous: _lastSaved);
        _lastSaved = data;
        saveError = null;
      } on Object {
        saveError =
            'No se pudo guardar. Tu progreso sigue en memoria; vuelve a intentar guardar.';
      }
      if (!_disposed && previousError != saveError) notifyListeners();
    }
    _saving = false;
    if (_evolutionCommitPending && prestigeReady && !_disposed) {
      _finishEvolutionCommit();
    }
  }

  Future<void> get pendingWrites => _writes;

  @override
  void dispose() {
    _disposed = true;
    feedback.dispose();
    rewardRepaint.dispose();
    motion.dispose();
    super.dispose();
  }
}
