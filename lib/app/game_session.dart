import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../core/vec.dart';
import '../features/motion/motion_input.dart';
import '../features/board/domain/board.dart';
import '../features/board/domain/launcher.dart';
import '../features/board/domain/debug_day_report.dart';
import '../features/board/domain/special_abilities.dart';
import '../features/board/domain/tool.dart';
import '../features/day_cycle/domain/day_cycle.dart';
import '../features/economy/domain/economy.dart';
import '../features/rewards/domain/reward_delivery.dart';
import '../features/rewards/domain/reward_frame_metrics.dart';
import '../features/progression/domain/progress.dart';
import '../features/prestige/domain/meta_progress.dart';
import '../features/prestige/domain/star_rewards.dart';
import '../features/prestige/domain/star_bubbles.dart';
import '../features/feeding/domain/feeding_progress.dart';
import '../features/upgrades/domain/catalog.dart';
import '../persistence/save_store.dart';

class GameSession extends ChangeNotifier {
  GameSession(
    this.catalog,
    this.store, {
    this.motion = const NoMotionInput(),
    int? eventSeed,
  }) : _eventRandomState = eventSeed ?? math.Random().nextInt(0x100000000) {
    feeding = FeedingProgress(
      startDay: 1,
      target: feedingInitialQuota,
      quotaStep: feedingQuotaStep,
    );
  }
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
    if (value) pause();
    _syncMotion();
  }

  void _syncMotion() => motion.setActive(
    running && !paused && !_backgrounded && phase == DayPhase.production,
  );

  final UpgradeCatalog catalog;
  final SaveStore store;
  final economy = Economy();
  late RewardDelivery rewards = _newRewards();
  final rewardFrameMetrics = RewardFrameMetrics();
  int? _debugRewardLimit;
  late RewardVisuals rewardVisuals = _newVisuals();
  RewardDelivery _newRewards() => RewardDelivery(
    delay: catalog.base['reward_delay']!,
    capacity: catalog.base['reward_ledger_limit']!.toInt(),
  );
  RewardVisuals _newVisuals() => RewardVisuals(
    catalog.base['reward_visual_limit']!.toInt(),
    catalog.base['reward_delay']!,
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
  )..sync(meta.starLedger);

  MetaProgress meta = MetaProgress();
  MetaProgress? _metaFloor;
  int _durableMetaRevision = 0;
  bool _allowPrestigeRollback = false;
  bool debugPrestigeRules = false;
  bool get prestigeReady =>
      debugEnabled ||
      (meta.revision <= _durableMetaRevision && saveError == null);
  bool get canPlayRun => meta.phase == PrestigePhase.playing;
  bool get quotaDefeatEnabled => !debugEnabled || debugPrestigeRules;
  void debugSetPrestigeRules(bool value) {
    if (!debugEnabled || running || !canPlayRun) return;
    debugPrestigeRules = value;
    notifyListeners();
  }

  void _clearRun() {
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
    feeding = FeedingProgress(
      startDay: 1,
      target: feedingInitialQuota,
      quotaStep: feedingQuotaStep,
    );
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
    save();
    notifyListeners();
    return true;
  }

  final progress = Progress();
  late FeedingProgress feeding;
  bool _debugFeedingTrials = false;
  bool get debugFeedingFailed => debugFeedingQuotas && feeding.missed;
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
            if (data['version'] != 10 && data['version'] != 11) {
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
        return;
      } on Object {
        // Try the previous complete snapshot before offering an explicit reset.
      }
    }
    if (recoveredPrestige) {
      recoveryMessage =
          'Prestigio recuperado: la partida anterior ya había terminado.';
      return;
    }
    throw const FormatException(
      'El guardado y su copia no se pueden leer. No se han sobrescrito.',
    );
  }

  void startDay() {
    if (running || debugFeedingFailed || !canPlayRun || !prestigeReady) return;
    feeding.beginDay(progress.day);
    _retiredRunLevels.clear();
    final settings = catalog.settings(levels);
    _eventRandomState = (1664525 * _eventRandomState + 1013904223) & 0xffffffff;
    board = Board(
      settings,
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
    debugForceGravity = false;
    debugBlackHoleObjects = 0;
    cycle = DayCycle(production: settings['production_duration'], closing: 0);
    economy.begin();
    rewards = _newRewards();
    rewardVisuals = _newVisuals();
    board!.enableAutomaticCoins();
    board!.starBubbles = _newBubbles(board!)..populate(0);
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

  void tick(double dt) {
    if (!running || paused || !dt.isFinite) return;
    final generatedBefore = economy.generated;
    final metaBefore = meta.revision;
    rewardVisuals.observeFrame(dt);
    _accumulator += dt.clamp(0.0, .1);
    while (_accumulator + 1e-9 >= 1 / 60 && running) {
      _accumulator -= 1 / 60;
      final clock = cycle!;
      final producing = clock.phase == DayPhase.production;
      // Split at the production boundary, and never simulate beyond day end.
      final boundary = producing
          ? clock.remaining - clock.closing
          : clock.remaining;
      final step = math.min(1 / 60, boundary);
      _step(step, producing);
      if (running && step < 1 / 60) {
        _step(math.min(1 / 60 - step, cycle!.remaining), false);
      }
    }
    if (running &&
        (economy.generated != generatedBefore || meta.revision != metaBefore)) {
      save();
    }
    _uiClock += dt.clamp(0.0, .1);
    _checkpoint += dt.clamp(0.0, .1);
    if (_checkpoint >= 5) {
      _checkpoint = 0;
      save();
    }
    if (_uiClock >= .1) {
      _uiClock = 0;
      notifyListeners();
    }
  }

  void _step(double dt, bool producing) {
    if (dt <= 0) return;
    board!.gravitySupported = gravityAvailable;
    board!.gravityTilt = _debugTilt ?? motion.tilt;
    board!.starBubbles ??= _newBubbles(board!);
    final events = board!.update(dt, producing: producing);
    if (debugEnabled) {
      _debugMaxCombo = math.max(_debugMaxCombo, board!.combo.multiplier);
    }
    feeding.credit(
      progress.day,
      normal: events.normalFood,
      instant: events.instantFood,
    );
    if (feeding.met && feeding.period > meta.starLedger.quota) {
      _changeStars(
        meta.starLedger.award(feeding.period, board!.starBubbles!.config),
      );
      board!.starBubbles?.populate(0);
    }
    final bubbles = board!.starBubbles;
    if (bubbles != null && bubbles.broken.isNotEmpty) {
      final transaction = meta.starLedger.redeem(bubbles.broken);
      _changeStars(transaction.ledger, paid: transaction.paid);
      bubbles.broken.clear();
    }
    economy.collect(events.collected);
    for (final value in events.rewards) {
      economy.generated += value;
      final id = rewards.register(value);
      rewardVisuals.add(id, value);
    }
    rewardVisuals.advance(dt);
    final arrived = rewards.advance(dt);
    if (arrived > 0) {
      economy.collect(arrived);
      rewardVisuals.receipt();
    }
    cycle!.advance(dt);
    if (producing && cycle!.phase == DayPhase.closing) {
      board!.enterClosing();
      _syncMotion();
    }
    if (cycle!.phase == DayPhase.night) finishDay();
  }

  void finishDay() {
    if (!running) return;
    economy.collect(rewards.settle());
    rewardVisuals.clear();
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
    final result = DayResult(
      day: progress.day,
      income: economy.collected,
      generated: economy.generated,
      captured: board!.captured,
      previousIncome: progress.last?.income,
      collectedCoins: board!.automaticCoins || board!.collectedCoins == null
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
    if (quotaDefeatEnabled && feeding.missed) {
      _endRun(voluntary: false);
    } else {
      save();
      notifyListeners();
    }
  }

  void touch(Vec position, {double? time}) {
    if (!running || paused || _backgrounded) return;
    board!.gravitySupported = gravityAvailable;
    economy.collect(board!.touch(position, time: time));
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
    _syncMotion();
    _accumulator = 0;
    release(cancel: true);
    save();
    notifyListeners();
  }

  void resume() {
    if (_backgrounded) return;
    paused = false;
    _syncMotion();
    _accumulator = 0;
    notifyListeners();
  }

  bool activateSpecial(SpecialAbility ability) {
    if (!running ||
        paused ||
        phase != DayPhase.production ||
        !board!.activateSpecial(ability)) {
      return false;
    }
    save();
    notifyListeners();
    return true;
  }

  void setSound(bool value) {
    sound = value;
    save();
    notifyListeners();
  }

  void setHaptics(bool value) {
    haptics = value;
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
    debugPrestigeRules = false;
    _debugStars = null;
    debugBubbleGravity = debugBubbleBlackHole = false;
    _debugRewardLimit = null;
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
  int get feedingInitialQuota => catalog.base['feeding_quota_initial']!.toInt();
  int get feedingQuotaStep => catalog.base['feeding_quota_step']!.toInt();
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
    feeding = FeedingProgress(
      startDay: progress.day,
      target: quotas ? amount : null,
      quotaStep: quotas ? feedingQuotaStep : 0,
    );
    notifyListeners();
  }

  void debugRestartFeedingPeriod() =>
      debugConfigureFeeding(quotas: debugFeedingQuotas, target: feeding.target);
  void debugSimulateEmptyDay() {
    if (!debugEnabled || running || debugFeedingFailed) return;
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
    _debugReports.clear();
    _debugFeedingTrials = false;
    feeding = FeedingProgress(
      startDay: 1,
      target: feedingInitialQuota,
      quotaStep: feedingQuotaStep,
    );
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
    if (!canPlayRun || !prestigeReady) return 'Partida no disponible';
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
    if (definition.id == 'prestige') return _endRun(voluntary: true);
    levels[definition.id] = level + 1;
    if (definition.id == 'bat') selectedTool = BallTool.bat;
    if (definition.id == 'broom') selectedTool = BallTool.broom;
    if (definition.id == 'broom_v') selectedTool = BallTool.vee;
    save();
    notifyListeners();
    return true;
  }

  String snapshot() => jsonEncode({
    'version': 11,
    'meta': meta.toJson(),
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
    'visualFeedback': visualFeedback,
    'last': progress.last?.toJson(),
    'run': !running
        ? null
        : {
            'remaining': cycle!.remaining,
            'rewards': rewards.toJson(),
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
        json['version'] != 11) {
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
    final restoredMeta = (json['version'] as int) >= 10
        ? MetaProgress.fromJson(json['meta'] as Map<String, dynamic>)
        : MetaProgress();
    final floor = _metaFloor;
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
          : 17,
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
        (last.day != day - 1 ||
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
          (balanceVersion < 1 || balanceVersion > 17)) {
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
                  balanceVersion >= 15) {
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
          remaining <= 0 ||
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
            (restoredCycle.phase == DayPhase.closing &&
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
            event.ended != (restoredCycle.phase == DayPhase.closing)) {
          throw const FormatException('Tiempo de Agujero negro incoherente');
        }
      }
      restoredBoard.tool = restoredTool;
      if (restoredCycle.phase == DayPhase.closing) {
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
                  settings['ball_value'].toInt()) {
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
    final savedFeeding = json['feeding'];
    final FeedingProgress restoredFeeding;
    if ((json['version'] as int) >= 8) {
      if (savedFeeding is! Map<String, dynamic>) {
        throw const FormatException('Falta la alimentación');
      }
      restoredFeeding = FeedingProgress.fromJson(
        savedFeeding,
        day: day,
        running: run != null,
      );
      if (restoredBoard != null &&
          restoredBoard.settings.balanceVersion >= 14 &&
          (restoredFeeding.startDay > day ||
              restoredFeeding.runNormal != restoredBoard.normalFood ||
              restoredFeeding.runInstant != restoredBoard.instantFood)) {
        throw const FormatException('Capturas de alimentación incoherentes');
      }
      if (restoredBoard != null &&
          restoredBoard.settings.balanceVersion < 14 &&
          restoredFeeding.startDay != day + 1) {
        throw const FormatException('Migración de alimentación incoherente');
      }
    } else {
      // Historical captures cannot be reconstructed without guessing ability use.
      restoredFeeding = FeedingProgress(
        startDay: day + (run != null ? 1 : 0),
        target: feedingInitialQuota,
        quotaStep: feedingQuotaStep,
      );
    }
    if (restoredMeta.phase != PrestigePhase.playing &&
        (restoredFeeding.points != 0 ||
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
        );
      } else {
        restoredBoard.starBubbles = StarBubbles(
          StarConfig(catalog.base),
          ballRadius: restoredBoard.radius,
          maximumSpeed: restoredBoard.maximumSpeed,
        )..sync(restoredMeta.starLedger);
      }
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
    final savedSound = json['sound'] as bool;
    final savedHaptics = json['haptics'] as bool? ?? true;
    final savedVisualFeedback = json['visualFeedback'] as bool? ?? false;
    meta = restoredMeta;
    _metaFloor = restoredMeta;
    progress.day = day;
    progress.record = record;
    progress.last = last;
    economy.balance = balance;
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
    rewardVisuals = _newVisuals();
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
    visualFeedback = savedVisualFeedback;
    paused = running;
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
  }

  Future<void> get pendingWrites => _writes;

  @override
  void dispose() {
    _disposed = true;
    motion.dispose();
    super.dispose();
  }
}
