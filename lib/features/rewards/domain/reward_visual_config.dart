/// Provisional visual settings only; never used to calculate income.
class RewardVisualConfig {
  const RewardVisualConfig({
    this.capacity = 192,
    this.window = .2,
    this.target = 64,
    this.large = 50,
    this.pending = 1024,
    this.wave = .12,
    this.wait = 5,
    this.emitMin = .0083,
    this.emitMax = .075,
    this.angularMin = 2,
    this.angularMax = 24,
    this.loadScale = 24,
    this.angleJitter = .12,
    this.smallSeparation = .85,
    this.jumpDistance = 38,
    this.hold = 1,
    this.flightScale = 1,
    this.variation = 1,
    this.samples = 30,
    this.badMs = 18,
    this.recovery = 2,
  });
  final double emitMin,
      emitMax,
      angularMin,
      angularMax,
      loadScale,
      angleJitter,
      smallSeparation,
      jumpDistance;
  final double window,
      wave,
      wait,
      hold,
      flightScale,
      variation,
      badMs,
      recovery;
  final int capacity, target, large, pending, samples;
  static const ranges = <String, (double, double)>{
    'reward_visual_limit': (1, 1024),
    'reward_batch_window': (.05, .5),
    'reward_target_coins': (8, 256),
    'reward_large_threshold': (50, 5000),
    'reward_pending_limit': (128, 4096),
    'reward_wave_span': (0, .4),
    'reward_emit_wait': (.1, 8),
    'reward_emit_min': (.008, .05),
    'reward_emit_max': (.05, .2),
    'reward_angular_min': (.5, 8),
    'reward_angular_max': (8, 48),
    'reward_load_scale': (4, 100),
    'reward_angle_jitter': (0, .3),
    'reward_small_separation': (.3, 1.2),
    'reward_jump_distance': (15, 70),
    'reward_hold': (0, 2),
    'reward_flight_scale': (.5, 2),
    'reward_variation': (.25, 2),
    'reward_feedback_samples': (15, 120),
    'reward_bad_ms': (16.67, 40),
    'reward_recovery_seconds': (.5, 5),
  };
  static const optionalDefaults = <String, double>{
    'reward_emit_wait': 5,
    'reward_visual_limit': 192,
    'reward_emit_min': .0083,
    'reward_emit_max': .075,
    'reward_angular_min': 2,
    'reward_angular_max': 24,
    'reward_load_scale': 24,
    'reward_angle_jitter': .12,
    'reward_small_separation': .85,
    'reward_jump_distance': 38,
  };
  static const labels = {
    'reward_visual_limit': 'Capacidad visual máxima',
    'reward_batch_window': 'Microlote (s)',
    'reward_target_coins': 'Objetivo de lluvia',
    'reward_large_threshold': 'Importe para expandir',
    'reward_pending_limit': 'Pendientes antes de agrupar',
    'reward_wave_span': 'Separación de oleada (s)',
    'reward_emit_wait': 'Umbral temporal de agrupación (s)',
    'reward_emit_min': 'Intervalo mínimo (s)',
    'reward_emit_max': 'Intervalo máximo (s)',
    'reward_angular_min': 'Giro mínimo (rad/s)',
    'reward_angular_max': 'Giro máximo (rad/s)',
    'reward_load_scale': 'Carga para acelerar',
    'reward_angle_jitter': 'Variación angular',
    'reward_small_separation': 'Separación angular pequeña',
    'reward_jump_distance': 'Distancia del salto',
    'reward_hold': 'Pausa tras salto (s)',
    'reward_flight_scale': 'Duración del vuelo',
    'reward_variation': 'Variación de trayectorias',
    'reward_feedback_samples': 'Muestras de rendimiento',
    'reward_bad_ms': 'Umbral de frame (ms)',
    'reward_recovery_seconds': 'Recuperación (s)',
  };
  factory RewardVisualConfig.fromMap(Map<String, double> values) {
    for (final e in ranges.entries) {
      final v = values[e.key] ?? optionalDefaults[e.key];
      if (v == null || !v.isFinite || v < e.value.$1 || v > e.value.$2) {
        throw FormatException('Parámetro visual inválido: ${e.key}');
      }
    }
    for (final key in [
      'reward_visual_limit',
      'reward_target_coins',
      'reward_large_threshold',
      'reward_pending_limit',
      'reward_feedback_samples',
    ]) {
      final v = values[key] ?? optionalDefaults[key];
      if (v != v!.roundToDouble()) {
        throw FormatException('Parámetro visual no entero: $key');
      }
    }
    if ((values['reward_emit_min'] ?? .0083) >
        (values['reward_emit_max'] ?? .075)) {
      throw const FormatException('Intervalos incompatibles');
    }
    return RewardVisualConfig(
      capacity: (values['reward_visual_limit'] ?? 192).toInt(),
      emitMin: values['reward_emit_min'] ?? .0083,
      emitMax: values['reward_emit_max'] ?? .075,
      angularMin: values['reward_angular_min'] ?? 2,
      angularMax: values['reward_angular_max'] ?? 24,
      loadScale: values['reward_load_scale'] ?? 24,
      angleJitter: values['reward_angle_jitter'] ?? .12,
      smallSeparation: values['reward_small_separation'] ?? .85,
      jumpDistance: values['reward_jump_distance'] ?? 38,
      window: values['reward_batch_window']!,
      target: values['reward_target_coins']!.toInt(),
      large: values['reward_large_threshold']!.toInt(),
      pending: values['reward_pending_limit']!.toInt(),
      wave: values['reward_wave_span']!,
      wait: values['reward_emit_wait'] ?? 5,
      hold: values['reward_hold']!,
      flightScale: values['reward_flight_scale']!,
      variation: values['reward_variation']!,
      samples: values['reward_feedback_samples']!.toInt(),
      badMs: values['reward_bad_ms']!,
      recovery: values['reward_recovery_seconds']!,
    );
  }
}
