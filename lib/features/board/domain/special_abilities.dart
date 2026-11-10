import 'dart:math' as math;
import '../../upgrades/domain/catalog.dart';

enum SpecialAbility { captureAll, boost }

/// Simulation time only. Each day begins empty; active boosts recharge afterwards.
class SpecialAbilities {
  SpecialAbilities(this.settings);
  final DaySettings settings;
  double captureCharge = 0, boostCharge = 0, boostRemaining = 0;

  bool unlocked(SpecialAbility ability) =>
      settings[ability == SpecialAbility.captureAll
          ? 'capture_all_unlocked'
          : 'boost_unlocked'] >
      0;
  double cooldown(SpecialAbility ability) =>
      ability == SpecialAbility.captureAll
      ? settings['capture_all_cooldown']
      : settings['boost_cooldown'];
  double charge(SpecialAbility ability) =>
      ability == SpecialAbility.captureAll ? captureCharge : boostCharge;
  bool ready(SpecialAbility ability) =>
      unlocked(ability) &&
      cooldown(ability) > 0 &&
      charge(ability) + 1e-9 >= cooldown(ability) &&
      (ability != SpecialAbility.boost || boostRemaining == 0);
  double progress(SpecialAbility ability) =>
      !unlocked(ability) || cooldown(ability) <= 0
      ? 0
      : (charge(ability) / cooldown(ability)).clamp(0.0, 1.0);
  double get generationMultiplier =>
      boostRemaining > 0 ? settings['boost_multiplier'] : 1;

  void advance(double dt) {
    if (unlocked(SpecialAbility.captureAll)) {
      captureCharge = math.min(
        cooldown(SpecialAbility.captureAll),
        captureCharge + dt,
      );
    }
    if (unlocked(SpecialAbility.boost)) {
      final chargingTime = math.max(0.0, dt - boostRemaining);
      boostRemaining = math.max(0.0, boostRemaining - dt);
      boostCharge = math.min(
        cooldown(SpecialAbility.boost),
        boostCharge + chargingTime,
      );
    }
  }

  bool activate(SpecialAbility ability) {
    if (!ready(ability)) return false;
    if (ability == SpecialAbility.captureAll) {
      captureCharge = 0;
    } else {
      boostCharge = 0;
      boostRemaining = settings['boost_duration'];
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'captureCharge': captureCharge,
    'boostCharge': boostCharge,
    'boostRemaining': boostRemaining,
  };

  void restore(Map<String, dynamic> json) {
    double read(String key, double maximum) {
      final value = json[key];
      if (value is! num || !value.isFinite || value < 0 || value > maximum) {
        throw const FormatException('Carga de habilidad inválida');
      }
      return value.toDouble();
    }

    captureCharge = read(
      'captureCharge',
      unlocked(SpecialAbility.captureAll)
          ? cooldown(SpecialAbility.captureAll)
          : 0,
    );
    boostCharge = read(
      'boostCharge',
      unlocked(SpecialAbility.boost) ? cooldown(SpecialAbility.boost) : 0,
    );
    boostRemaining = read(
      'boostRemaining',
      unlocked(SpecialAbility.boost) ? settings['boost_duration'] : 0,
    );
    if (boostRemaining > 0 && boostCharge != 0) {
      throw const FormatException('Recarga durante aceleración');
    }
  }
}
