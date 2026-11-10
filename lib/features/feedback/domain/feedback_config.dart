class FeedbackConfig {
  const FeedbackConfig([this.values = defaults]);
  final Map<String, double> values;
  double operator [](String key) => values[key]!;
  static const defaults = <String, double>{
    'maxVoices': 8,
    'groupWindow': .05,
    'captureWindow': .5,
    'frequentRate': 6,
    'massRate': 30,
    'attack': 9,
    'release': 4,
    'pitchVariation': .045,
    'captureGain': .24,
    'coinGain': .22,
    'impactGain': .08,
    'starGain': .3,
    'upgradeGain': .25,
    'absorbGain': .065,
    'rollingGain': .028,
    'impactThreshold': 24,
    'hapticInterval': .18,
    'sinkDuration': .24,
    'sinkCapacity': 1024,
    'rippleGain': .035,
  };
  static const ranges = <String, (double, double)>{
    'maxVoices': (4, 16),
    'groupWindow': (.02, .12),
    'captureWindow': (.2, 2),
    'frequentRate': (2, 20),
    'massRate': (20, 100),
    'attack': (2, 20),
    'release': (1, 12),
    'pitchVariation': (0, .12),
    'captureGain': (0, .5),
    'coinGain': (0, .5),
    'impactGain': (0, .25),
    'starGain': (0, .5),
    'upgradeGain': (0, .5),
    'absorbGain': (0, .15),
    'rollingGain': (0, .1),
    'impactThreshold': (8, 120),
    'hapticInterval': (.1, .6),
    'sinkDuration': (.12, .4),
    'sinkCapacity': (256, 4096),
    'rippleGain': (0, .07),
  };
  factory FeedbackConfig.fromJson(Map<String, dynamic> json) {
    final values = <String, double>{};
    for (final e in ranges.entries) {
      final n = json[e.key];
      if (n is! num || !n.isFinite || n < e.value.$1 || n > e.value.$2) {
        throw FormatException('Configuración audiovisual inválida: ${e.key}');
      }
      values[e.key] = n.toDouble();
    }
    for (final key in ['maxVoices', 'sinkCapacity']) {
      if (values[key] != values[key]!.roundToDouble()) {
        throw FormatException('Valor no entero: $key');
      }
    }
    if (values['massRate']! <= values['frequentRate']!) {
      throw const FormatException('Umbrales de captura inválidos');
    }
    return FeedbackConfig(Map.unmodifiable(values));
  }
  FeedbackConfig changed(String key, double value) =>
      FeedbackConfig.fromJson({...values, key: value});
}
