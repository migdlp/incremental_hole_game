enum DayPhase { production, closing, night }

class DayCycle {
  DayCycle({required this.production, required this.closing, double? remaining})
    : remaining = remaining ?? production + closing;
  final double production, closing;
  double remaining;
  DayPhase get phase => remaining <= 0
      ? DayPhase.night
      : remaining <= closing
      ? DayPhase.closing
      : DayPhase.production;
  double advance(double dt) {
    final elapsed = dt.clamp(0.0, remaining);
    remaining = (remaining - elapsed).clamp(0.0, production + closing);
    if (remaining < 1e-8) remaining = 0;
    return elapsed;
  }
}
