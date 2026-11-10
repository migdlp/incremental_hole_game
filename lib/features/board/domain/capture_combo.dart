/// A streak uses simulation time, so pausing never consumes its window.
class CaptureCombo {
  CaptureCombo({this.enabled = true});

  static const window = 1.0;
  final bool enabled;
  int streak = 0;
  double remaining = 0;
  // Extra base-value units awarded so accounting stays exact with golden balls.
  int bonusUnits = 0;

  int get multiplier => !enabled || streak < 5
      ? 1
      : streak < 10
      ? 2
      : 3;

  void advance(double dt) {
    if (!enabled || streak == 0) return;
    remaining -= dt;
    // The boundary itself is inside the window, allowing a capture at 1 s.
    if (remaining < -1e-9) {
      streak = 0;
      remaining = 0;
    } else if (remaining < 0) {
      remaining = 0;
    }
  }

  int capture({required bool golden}) {
    if (!enabled) return golden ? 10 : 1;
    streak++;
    remaining = window;
    final units = golden ? 10 : 1;
    bonusUnits += units * (multiplier - 1);
    return units * multiplier;
  }

  void end() {
    streak = 0;
    remaining = 0;
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'streak': streak,
    'remaining': remaining,
    'bonusUnits': bonusUnits,
  };

  factory CaptureCombo.fromJson(
    Map<String, dynamic> json, {
    required int captured,
    required int goldenCaptured,
  }) {
    final enabled = json['enabled'];
    final streak = json['streak'];
    final remaining = json['remaining'];
    final bonus = json['bonusUnits'];
    if (enabled is! bool ||
        streak is! int ||
        streak < 0 ||
        streak > captured ||
        remaining is! num ||
        !remaining.isFinite ||
        remaining < 0 ||
        remaining > window ||
        (streak == 0 && remaining != 0) ||
        bonus is! int ||
        bonus < 0 ||
        bonus > 2 * (captured + 9 * goldenCaptured) ||
        (captured < 5 && bonus != 0) ||
        (!enabled && (streak != 0 || remaining != 0 || bonus != 0))) {
      throw const FormatException('Combo guardado inválido');
    }
    return CaptureCombo(enabled: enabled)
      ..streak = streak
      ..remaining = remaining.toDouble()
      ..bonusUnits = bonus;
  }
}
