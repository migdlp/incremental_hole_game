/// Read-only validator for v8–v13 monetary feeding. Never used by gameplay.
class LegacyFeedingProgress {
  LegacyFeedingProgress({
    required this.startDay,
    this.target,
    this.quotaStep = 0,
  });
  int startDay;
  int period = 1, completedDays = 0;
  int normalPoints = 0, instantPoints = 0;
  int runNormal = 0, runInstant = 0;
  int growths = 0, growthPeriod = 0;
  int? target;
  final int quotaStep;
  static const periodLength = 5;
  bool get due => completedDays == periodLength;
  int get points => normalPoints + instantPoints;
  int get remainingDays => periodLength - completedDays;
  bool get met => target != null && points >= target!;
  bool get missed => due && target != null && !met;
  int? get nextTarget => target == null ? null : target! + quotaStep;
  double? get fraction =>
      target == null ? null : (points / target!).clamp(0.0, 1.0);

  factory LegacyFeedingProgress.fromJson(
    Map<String, dynamic> json, {
    required int day,
    required bool running,
    bool requireGrowth = false,
  }) {
    int number(String key, {int minimum = 0}) {
      final value = json[key];
      if (value is! int || value < minimum || value > 0x1fffffffffffff) {
        throw const FormatException('Registro de alimentación inválido');
      }
      return value;
    }

    final target = json['target'];
    if (target != null &&
        (target is! int || target < 1 || target > 0x1fffffffffffff)) {
      throw const FormatException('Regla de alimentación inválida');
    }
    final state =
        LegacyFeedingProgress(
            startDay: number('startDay', minimum: 1),
            target: target as int?,
            quotaStep: number('quotaStep'),
          )
          ..period = number('period', minimum: 1)
          ..completedDays = number('completedDays')
          ..normalPoints = number('normal')
          ..instantPoints = number('instant')
          ..runNormal = number('runNormal')
          ..runInstant = number('runInstant');
    final hasGrowth =
        json.containsKey('growths') || json.containsKey('growthPeriod');
    if (requireGrowth || hasGrowth) {
      state.growths = number('growths');
      state.growthPeriod = number('growthPeriod');
    } else {
      // Historical quotas are already settled; growth starts with future quotas.
      state.growthPeriod = state.met ? state.period : state.period - 1;
    }
    if (state.growths > state.growthPeriod ||
        state.growthPeriod > state.period ||
        (state.met
            ? state.growthPeriod != state.period
            : state.growthPeriod == state.period)) {
      throw const FormatException('Crecimiento del agujero incoherente');
    }
    final expectedDay = state.startDay + state.completedDays;
    final migratedRun =
        running &&
        state.startDay == day + 1 &&
        state.completedDays == 0 &&
        state.period == 1 &&
        state.normalPoints == 0 &&
        state.instantPoints == 0;
    if (state.completedDays > periodLength ||
        state.runNormal > state.normalPoints ||
        state.runInstant > state.instantPoints ||
        (!migratedRun && expectedDay != day) ||
        (running && state.due) ||
        (state.target == null ? state.quotaStep != 0 : state.quotaStep < 1)) {
      throw const FormatException('Período de alimentación incoherente');
    }
    return state;
  }
}
