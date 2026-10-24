/// Provisional visual settings only; never used to calculate income.
class RewardVisualConfig {
  const RewardVisualConfig({
    this.window = .2,
    this.target = 64,
    this.large = 50,
    this.pending = 1024,
    this.wave = .12,
    this.wait = .4,
    this.hold = 1,
    this.flightScale = 1,
    this.variation = 1,
    this.samples = 30,
    this.badMs = 18,
    this.recovery = 2,
  });
  final double window,
      wave,
      wait,
      hold,
      flightScale,
      variation,
      badMs,
      recovery;
  final int target, large, pending, samples;
  static const ranges = <String, (double, double)>{
    'reward_batch_window': (.05, .5),
    'reward_target_coins': (8, 256),
    'reward_large_threshold': (50, 5000),
    'reward_pending_limit': (128, 4096),
    'reward_wave_span': (0, .4),
    'reward_max_wait': (.1, 2),
    'reward_hold': (0, 2),
    'reward_flight_scale': (.5, 2),
    'reward_variation': (.25, 2),
    'reward_feedback_samples': (15, 120),
    'reward_bad_ms': (16.67, 40),
    'reward_recovery_seconds': (.5, 5),
  };
  static const labels = {
    'reward_batch_window': 'Microlote (s)',
    'reward_target_coins': 'Objetivo de lluvia',
    'reward_large_threshold': 'Importe para expandir',
    'reward_pending_limit': 'Pendientes antes de agrupar',
    'reward_wave_span': 'Separación de oleada (s)',
    'reward_max_wait': 'Espera máxima visual (s)',
    'reward_hold': 'Pausa tras salto (s)',
    'reward_flight_scale': 'Duración del vuelo',
    'reward_variation': 'Variación de trayectorias',
    'reward_feedback_samples': 'Muestras de rendimiento',
    'reward_bad_ms': 'Umbral de frame (ms)',
    'reward_recovery_seconds': 'Recuperación (s)',
  };
  factory RewardVisualConfig.fromMap(Map<String, double> values) {
    for (final e in ranges.entries) {
      final v = values[e.key];
      if (v == null || !v.isFinite || v < e.value.$1 || v > e.value.$2) {
        throw FormatException('Parámetro visual inválido: ${e.key}');
      }
    }
    for (final key in [
      'reward_target_coins',
      'reward_large_threshold',
      'reward_pending_limit',
      'reward_feedback_samples',
    ]) {
      if (values[key] != values[key]!.roundToDouble()) {
        throw FormatException('Parámetro visual no entero: $key');
      }
    }
    return RewardVisualConfig(
      window: values['reward_batch_window']!,
      target: values['reward_target_coins']!.toInt(),
      large: values['reward_large_threshold']!.toInt(),
      pending: values['reward_pending_limit']!.toInt(),
      wave: values['reward_wave_span']!,
      wait: values['reward_max_wait']!,
      hold: values['reward_hold']!,
      flightScale: values['reward_flight_scale']!,
      variation: values['reward_variation']!,
      samples: values['reward_feedback_samples']!.toInt(),
      badMs: values['reward_bad_ms']!,
      recovery: values['reward_recovery_seconds']!,
    );
  }
}
