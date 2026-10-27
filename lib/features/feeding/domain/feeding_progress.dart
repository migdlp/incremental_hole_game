import 'legacy_feeding_progress.dart';

/// Capturable balls only, with a four-production-day deadline per active quota.
class FeedingProgress {
  static const initialQuota = 25;
  static const _opening = [25, 50, 100, 500, 1000];
  static BigInt quotaAt(int level) {
    if (level < 1) throw ArgumentError.value(level, 'level');
    return level <= _opening.length
        ? BigInt.from(_opening[level - 1])
        : BigInt.from(1000) * BigInt.from(10).pow(level - _opening.length);
  }

  // Custom DEBUG targets retain their independent decimal progression.
  String _curve;
  FeedingProgress({required this.startDay, int? target = initialQuota})
    : _curve = target == initialQuota ? 'opening-25-v1' : 'decimal-v1',
      quotaStartDay = startDay,
      initialTarget = target == null ? null : BigInt.from(target),
      target = target == null ? null : BigInt.from(target) {
    if (startDay < 1 || (target != null && target < 1)) {
      throw ArgumentError('Inicio u objetivo de alimentación inválido');
    }
  }

  static const quotaDays = 4;
  int startDay, quotaStartDay;
  bool dayClosed = false;
  int quotaDay(int day) => (day - quotaStartDay + 1).clamp(1, quotaDays);
  int futureDays(int day) => quotaDays - quotaDay(day);
  bool expiresAt(int day) =>
      target != null && day >= quotaStartDay + quotaDays - 1;

  int period = 1, completedDays = 0;
  BigInt normalPoints = BigInt.zero, instantPoints = BigInt.zero;
  int runCapturedBaseline = 0;
  int growths = 0, growthPeriod = 0;
  BigInt? initialTarget, target;
  BigInt get points => normalPoints + instantPoints;
  int get completed => period - 1;
  BigInt? get remaining => target == null ? null : target! - points;
  BigInt? get nextTarget => target == null
      ? null
      : _curve == 'opening-25-v1'
      ? quotaAt(period + 1)
      : target! * BigInt.from(10);
  BigInt _expectedTarget() => _curve == 'opening-25-v1'
      ? quotaAt(period)
      : initialTarget! * BigInt.from(10).pow(completed);
  double? get fraction => target == null ? null : ratio(points, target!);

  // Bookkeeping advances only for actual production days.
  bool beginDay(int day) {
    if (day < startDay) return false;
    if (day != startDay + completedDays) {
      throw StateError('Jornada de alimentación incoherente');
    }
    dayClosed = false;
    runBalls = BigInt.zero;
    runCapturedBaseline = 0;
    return true;
  }

  /// Ordered completion events; excess is consumed exactly once by each quota.
  List<int> credit(int day, {required int normal, required int instant}) =>
      creditBalls(
        day,
        normal: BigInt.from(normal),
        instant: BigInt.from(instant),
      );

  List<int> creditBalls(
    int day, {
    required BigInt normal,
    required BigInt instant,
  }) {
    if (normal.isNegative || instant.isNegative) {
      throw ArgumentError('Alimentación negativa');
    }
    if (day < startDay) return const [];
    if (day != startDay + completedDays) {
      throw StateError('Captura fuera de jornada');
    }
    // Upgrade old 100 × 10^n saves only inside the capture transaction. Existing
    // excess completes the new objectives through the same unique reward events.
    if (_curve == 'upgrade-from-100') {
      _curve = 'opening-25-v1';
      initialTarget = BigInt.from(initialQuota);
      target = quotaAt(period);
    }
    normalPoints += normal;
    instantPoints += instant;
    // Per-day counters use BigInt as well; no conversion through double.
    runBalls += normal + instant;
    final events = <int>[];
    while (target != null && points >= target!) {
      var consumed = target!;
      final fromNormal = normalPoints < consumed ? normalPoints : consumed;
      normalPoints -= fromNormal;
      consumed -= fromNormal;
      instantPoints -= consumed;
      events.add(period);
      growths++;
      growthPeriod = period;
      target = nextTarget;
      period++;
      quotaStartDay = day;
    }
    return events;
  }

  BigInt runBalls = BigInt.zero;
  bool finishDay(int day) {
    if (day < startDay || day == startDay + completedDays - 1) return false;
    if (day != startDay + completedDays) {
      throw StateError('Jornada de alimentación incoherente');
    }
    completedDays++;
    dayClosed = true;
    return true;
  }

  Map<String, dynamic> toJson() => {
    'rules': 'balls-four-days-v2',
    'curve': _curve,
    'quotaStartDay': quotaStartDay,
    'dayClosed': dayClosed,
    'startDay': startDay,
    'period': period,
    'completedDays': completedDays,
    'normal': normalPoints.toString(),
    'instant': instantPoints.toString(),
    'runBalls': runBalls.toString(),
    'runCapturedBaseline': runCapturedBaseline,
    'initialTarget': initialTarget?.toString(),
    'target': target?.toString(),
    'growths': growths,
    'growthPeriod': growthPeriod,
  };

  factory FeedingProgress.fromJson(
    Map<String, dynamic> json, {
    required int day,
    required bool running,
  }) {
    int number(String key, {int minimum = 0}) {
      final n = json[key];
      if (n is! int || n < minimum || n > 0x1fffffffffffff) {
        throw const FormatException('Registro de alimentación inválido');
      }
      return n;
    }

    BigInt big(String key) {
      final s = json[key];
      if (s is! String || !RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(s)) {
        throw const FormatException('Contador de bolas inválido');
      }
      return BigInt.parse(s);
    }

    final deadlines = json['rules'] == 'balls-four-days-v2';
    if (!deadlines && json['rules'] != 'balls-v1') {
      throw const FormatException('Reglas de alimentación inválidas');
    }
    final state = FeedingProgress(startDay: number('startDay', minimum: 1))
      ..period = number('period', minimum: 1)
      ..completedDays = number('completedDays')
      ..normalPoints = big('normal')
      ..instantPoints = big('instant')
      ..runBalls = big('runBalls')
      ..runCapturedBaseline = number('runCapturedBaseline')
      ..growths = number('growths')
      ..growthPeriod = number('growthPeriod')
      ..initialTarget = json['initialTarget'] == null
          ? null
          : big('initialTarget')
      ..target = json['target'] == null ? null : big('target');
    final curve = json['curve'];
    if (curve != null &&
        !['opening-25-v1', 'decimal-v1', 'upgrade-from-100'].contains(curve)) {
      throw const FormatException('Curva de cuotas inválida');
    }
    state._curve =
        curve as String? ??
        (state.initialTarget == BigInt.from(100)
            ? 'upgrade-from-100'
            : 'decimal-v1');
    if ((state._curve == 'opening-25-v1' &&
            state.initialTarget != BigInt.from(initialQuota)) ||
        (state._curve == 'upgrade-from-100' &&
            state.initialTarget != BigInt.from(100))) {
      throw const FormatException('Origen de curva inválido');
    }
    if (deadlines) {
      if (json['dayClosed'] is! bool) {
        throw const FormatException('Cierre de jornada inválido');
      }
      state.dayClosed = json['dayClosed'] as bool;
      state.quotaStartDay = number('quotaStartDay', minimum: 1);
    } else {
      // Old saves stored the *next* day between production days. Start a safe
      // fresh deadline on their current/just-finished day, never retroactively.
      state.dayClosed = !running && state.completedDays > 0;
      state.quotaStartDay = day - (state.dayClosed ? 1 : 0);
    }
    final migratedRun =
        running &&
        state.startDay == day + 1 &&
        state.completedDays == 0 &&
        state.runBalls == BigInt.zero;
    final expectedDay =
        state.startDay +
        state.completedDays -
        (deadlines && state.dayClosed ? 1 : 0);
    if ((!migratedRun && expectedDay != day) ||
        (running && state.dayClosed) ||
        (state.dayClosed && state.completedDays == 0) ||
        (deadlines &&
            state.target != null &&
            day > state.quotaStartDay + quotaDays - 1) ||
        state.quotaStartDay > (migratedRun ? state.startDay : day) ||
        state.growths > state.growthPeriod ||
        state.growthPeriod != state.completed ||
        (state.target == null
            ? state.initialTarget != null
            : state.initialTarget == null ||
                  state.initialTarget! <= BigInt.zero ||
                  state.target != state._expectedTarget() ||
                  state.points >= state.target!)) {
      throw const FormatException('Progreso de cuotas incoherente');
    }
    return state;
  }

  /// Monetary partial progress is intentionally discarded, never treated as balls.
  factory FeedingProgress.migrate(
    Map<String, dynamic> json, {
    required int day,
    required bool running,
    required bool requireGrowth,
    int capturedBaseline = 0,
  }) {
    final old = LegacyFeedingProgress.fromJson(
      json,
      day: day,
      running: running,
      requireGrowth: requireGrowth,
    );
    final completed = old.period - 1 + (old.met ? 1 : 0);
    final state =
        FeedingProgress(startDay: old.startDay > day ? day : old.startDay)
          ..period = completed + 1
          ..completedDays = old.completedDays
          ..growths = old.growths
          ..growthPeriod = completed
          ..runCapturedBaseline = capturedBaseline
          ..dayClosed = !running && old.completedDays > 0
          ..quotaStartDay = day - (!running && old.completedDays > 0 ? 1 : 0);
    state.target = quotaAt(state.period);
    return state;
  }
}

/// A bounded presentation ratio without overflowing double at huge quotas.
double ratio(BigInt value, BigInt target) =>
    ((value * BigInt.from(1000000)) ~/ target).toInt().clamp(0, 1000000) /
    1000000;

String ballNumber(BigInt value) {
  final digits = value.toString();
  if (digits.length > 24) {
    final tail = digits.substring(6);
    final approximate = tail.contains(RegExp(r'[1-9]')) ? '≈ ' : '';
    final fraction = digits.substring(1, 6).replaceFirst(RegExp(r'0+$'), '');
    return '$approximate${digits[0]}${fraction.isEmpty ? '' : ',$fraction'} ×10^${digits.length - 1}';
  }
  return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}
