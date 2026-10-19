import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../core/vec.dart';
import '../features/board/domain/board.dart';
import '../features/board/domain/tool.dart';
import '../features/day_cycle/domain/day_cycle.dart';
import '../features/economy/domain/economy.dart';
import '../features/progression/domain/progress.dart';
import '../features/upgrades/domain/catalog.dart';
import '../persistence/save_store.dart';

class GameSession extends ChangeNotifier {
  GameSession(this.catalog, this.store);
  final UpgradeCatalog catalog;
  final SaveStore store;
  final economy = Economy();
  final progress = Progress();
  final levels = <String, int>{};
  final _grandfathered = <String, int>{};
  BallTool selectedTool = BallTool.hand;
  Board? board;
  DayCycle? cycle;
  bool paused = false;
  bool sound = true;
  String? saveError;
  String? recoveryMessage;
  double _accumulator = 0, _uiClock = 0, _checkpoint = 0;
  String? _lastSaved;
  Future<void> _writes = Future.value();
  bool _disposed = false;
  bool get running => cycle != null;
  DayPhase get phase => cycle?.phase ?? DayPhase.night;

  Future<void> load() async {
    final candidates = await store.loadCandidates();
    if (candidates.isEmpty) return;
    for (var i = 0; i < candidates.length; i++) {
      try {
        restore(candidates[i]);
        _lastSaved = candidates[i];
        if (i > 0) {
          recoveryMessage = 'Partida recuperada desde la copia de seguridad.';
        }
        return;
      } on Object {
        // Try the previous complete snapshot before offering an explicit reset.
      }
    }
    throw const FormatException(
      'El guardado y su copia no se pueden leer. No se han sobrescrito.',
    );
  }

  void startDay() {
    if (running) return;
    final settings = catalog.settings(levels);
    board = Board(
      settings,
      randomState: progress.day * 7919,
      tool: selectedTool,
    );
    cycle = DayCycle(
      production: settings['production_duration'],
      closing: settings['closing_duration'],
    );
    economy.begin();
    paused = false;
    _accumulator = 0;
    _checkpoint = 0;
    save();
    notifyListeners();
  }

  void tick(double dt) {
    if (!running || paused || !dt.isFinite) return;
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
    final events = board!.update(dt, producing: producing);
    economy.collect(events.collected);
    for (var i = 0; i < events.captured; i++) {
      final value = board!.settings['ball_value'].toInt();
      economy.generated += value;
      board!.releaseCoin(value);
    }
    cycle!.advance(dt);
    if (producing && cycle!.phase == DayPhase.closing) {
      board!.enterClosing();
    }
    if (cycle!.phase == DayPhase.night) finishDay();
  }

  void finishDay() {
    if (!running) return;
    final result = DayResult(
      day: progress.day,
      income: economy.collected,
      generated: economy.generated,
      captured: board!.captured,
      previousIncome: progress.last?.income,
    );
    release(cancel: true);
    economy.bank();
    progress.finish(result);
    board = null;
    cycle = null;
    paused = false;
    _accumulator = 0;
    save();
    notifyListeners();
  }

  void touch(Vec position, {double? time}) {
    if (!running || paused) return;
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
    final collected = board?.releasePointer(cancel: cancel, time: time) ?? 0;
    economy.collect(collected);
    if (collected > 0) notifyListeners();
  }

  bool toolAvailable(BallTool tool) {
    final settings = catalog.settings(levels);
    return switch (tool) {
      BallTool.hand => true,
      BallTool.broom => settings['broom_unlocked'] > 0,
      BallTool.vee => settings['v_unlocked'] > 0,
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
    _accumulator = 0;
    release(cancel: true);
    save();
    notifyListeners();
  }

  void resume() {
    paused = false;
    _accumulator = 0;
    notifyListeners();
  }

  void setSound(bool value) {
    sound = value;
    save();
    notifyListeners();
  }

  String? purchaseBlock(UpgradeDefinition definition) {
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
      return 'Faltan \$${next.cost - economy.balance}';
    }
    return null;
  }

  bool purchase(UpgradeDefinition definition) {
    if (purchaseBlock(definition) != null) return false;
    final level = levels[definition.id] ?? 0;
    if (!economy.spend(definition.levels[level].cost)) return false;
    levels[definition.id] = level + 1;
    if (definition.id == 'broom') selectedTool = BallTool.broom;
    if (definition.id == 'broom_v') selectedTool = BallTool.vee;
    save();
    notifyListeners();
    return true;
  }

  String snapshot() => jsonEncode({
    'version': 4,
    'grandfathered': _grandfathered,
    'tool': selectedTool.name,
    'day': progress.day,
    'balance': economy.balance,
    'record': progress.record,
    'levels': levels,
    'sound': sound,
    'last': progress.last?.toJson(),
    'run': !running
        ? null
        : {
            'remaining': cycle!.remaining,
            'collected': economy.collected,
            'generated': economy.generated,
            'settings': board!.settings.toJson(),
            'balanceVersion': board!.settings.balanceVersion,
            'board': board!.toJson(),
          },
  });

  void restore(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final legacy = json['version'] == 1;
    if (!legacy &&
        json['version'] != 2 &&
        json['version'] != 3 &&
        json['version'] != 4) {
      throw const FormatException('Versión de guardado no compatible');
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
    // Old paddle purchases become width upgrades and retain access to the broom.
    if (legacy && (savedLevels['paddle'] ?? 0) > 0) savedLevels['broom'] = 1;
    final oldProgress = json['version'] != 4;
    final grandfathered = oldProgress
        ? Map<String, int>.of(savedLevels)
        : (json['grandfathered'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, value as int),
          );
    catalog.validateLevels(
      savedLevels,
      grandfathered: grandfathered,
      legacy: oldProgress,
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
            record < last.income)) {
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
          (balanceVersion < 1 || balanceVersion > 5)) {
        throw const FormatException('Versión de balance inválida');
      }
      final settings = catalog.settings(
        savedLevels,
        balanceVersion: balanceVersion,
      );
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
              settings['production_duration'] + settings['closing_duration']) {
        throw const FormatException('Tiempo inválido');
      }
      restoredCycle = DayCycle(
        production: settings['production_duration'],
        closing: settings['closing_duration'],
        remaining: remaining,
      );
      restoredBoard = Board.fromJson(
        settings,
        run['board'] as Map<String, dynamic>,
      );
      restoredBoard.tool = restoredTool;
      if (restoredCycle.phase == DayPhase.closing) {
        restoredBoard.enterClosing();
      }
      collected = run['collected'] as int;
      generated = run['generated'] as int;
      if (collected < 0 ||
          generated != collected + restoredBoard.pending ||
          generated !=
              restoredBoard.captured * settings['ball_value'].toInt()) {
        throw const FormatException('Contabilidad inválida');
      }
    }
    // Commit only after validating every module; a failed load leaves no partial state.
    final savedSound = json['sound'] as bool;
    progress.day = day;
    progress.record = record;
    progress.last = last;
    economy.balance = balance;
    economy.collected = collected;
    economy.generated = generated;
    levels
      ..clear()
      ..addAll(savedLevels);
    _grandfathered
      ..clear()
      ..addAll(grandfathered);
    selectedTool = restoredTool;
    if (legacy) {
      recoveryMessage =
          'Partida actualizada: conservas saldo y mejoras. '
          'Las monedas se recogen pulsando; el barrido se compra aparte.';
    }
    board = restoredBoard;
    cycle = restoredCycle;
    sound = savedSound;
    paused = running;
    _accumulator = 0;
  }

  Future<void> save() {
    final data = snapshot();
    _writes = _writes.then((_) async {
      final previousError = saveError;
      try {
        await store.save(data, previous: _lastSaved);
        _lastSaved = data;
        saveError = null;
      } on Object {
        saveError =
            'No se pudo guardar. Tu progreso sigue en memoria; vuelve a intentar guardar.';
      }
      if (!_disposed && previousError != saveError) notifyListeners();
    });
    return _writes;
  }

  Future<void> get pendingWrites => _writes;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
