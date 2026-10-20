/// Ephemeral observations for comparing trial days; never part of a save.
class DebugDayReport {
  const DebugDayReport({
    required this.day,
    required this.spawned,
    required this.captured,
    required this.goldenCaptured,
    required this.maxCombo,
    required this.generated,
    required this.collected,
  });

  final int day, spawned, captured, goldenCaptured, maxCombo;
  final int generated, collected;
  int get lost => generated - collected;
  String get summary =>
      'Día $day · emitidas $spawned · capturadas $captured '
      '(doradas $goldenCaptured) · combo máximo ×$maxCombo\n'
      'Monedas: generadas $generated · cobradas $collected · perdidas $lost';
}
