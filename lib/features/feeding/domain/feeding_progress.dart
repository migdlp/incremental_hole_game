import 'legacy_feeding_progress.dart';

/// Capturable balls only. Money and day deadlines never enter this ledger.
class FeedingProgress {
  static const initialQuota = 100;
  FeedingProgress({required this.startDay, int? target = initialQuota})
    : initialTarget = target == null ? null : BigInt.from(target),
      target = target == null ? null : BigInt.from(target) {
    if (startDay < 1 || (target != null && target < 1)) {
      throw ArgumentError('Inicio u objetivo de alimentación inválido');
    }
  }

  int startDay;
  int period = 1, completedDays = 0;
  BigInt normalPoints = BigInt.zero, instantPoints = BigInt.zero;
  int runCapturedBaseline = 0;
  int growths = 0, growthPeriod = 0;
  BigInt? initialTarget, target;
  BigInt get points => normalPoints + instantPoints;
  int get completed => period - 1;
  BigInt? get remaining => target == null ? null : target! - points;
  BigInt? get nextTarget => target == null ? null : target! * BigInt.from(10);
  double? get fraction => target == null ? null : ratio(points, target!);

  // Day bookkeeping validates snapshots without evaluating any deadline.
  bool beginDay(int day) {
    if (day < startDay) return false;
    if (day != startDay + completedDays) {
      throw StateError('Jornada de alimentación incoherente');
    }
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
      period++;
      target = nextTarget;
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
    return true;
  }

  Map<String, dynamic> toJson() => {
    'rules': 'balls-v1',
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

    if (json['rules'] != 'balls-v1') {
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
    final migratedRun =
        running &&
        state.startDay == day + 1 &&
        state.completedDays == 0 &&
        state.runBalls == BigInt.zero;
    if ((!migratedRun && state.startDay + state.completedDays != day) ||
        state.growths > state.growthPeriod ||
        state.growthPeriod != state.completed ||
        (state.target == null
            ? state.initialTarget != null
            : state.initialTarget == null ||
                  state.initialTarget! <= BigInt.zero ||
                  state.target !=
                      state.initialTarget! *
                          BigInt.from(10).pow(state.completed) ||
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
          ..runCapturedBaseline = capturedBaseline;
    state.target = state.initialTarget! * BigInt.from(10).pow(completed);
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
