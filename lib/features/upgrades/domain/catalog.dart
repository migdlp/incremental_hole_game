class UpgradeLevel {
  const UpgradeLevel(this.cost, this.value, this.requirement);
  final int cost;
  final double value;
  final String requirement;
}

class UpgradeDefinition {
  const UpgradeDefinition(
    this.id,
    this.name,
    this.branch,
    this.effect,
    this.unit,
    this.levels,
  );
  final String id, name, branch, effect, unit;
  final List<UpgradeLevel> levels;
}

class DaySettings {
  DaySettings(this.values, {this.balanceVersion = 2});
  final int balanceVersion;
  final Map<String, double> values;
  double operator [](String key) => values[key] ?? 0;
  Map<String, double> toJson() => Map.of(values);
  factory DaySettings.fromJson(Map<String, dynamic> json) => DaySettings(
    json.map((key, value) => MapEntry(key, (value as num).toDouble())),
  );
}

class UpgradeCatalog {
  UpgradeCatalog._(this.base, this.definitions);
  final Map<String, double> base;
  final List<UpgradeDefinition> definitions;
  static const labels = {
    'broom': ['Escoba recta', 'Control'],
    'paddle': ['Escoba más ancha', 'Control'],
    'broom_v': ['Escoba en V', 'Control'],
    'sweep': ['Recogida por barrido', 'Control'],
    'collection': ['Radio de recogida', 'Control'],
    'magnet': ['Imán', 'Control'],
    'generator': ['Generador rápido', 'Producción'],
    'reward': ['Mayor recompensa', 'Producción'],
    'duration': ['Día más largo', 'Producción'],
    'robot': ['Robot ayudante', 'Automatización'],
    'robot_speed': ['Velocidad del robot', 'Automatización'],
  };

  factory UpgradeCatalog.fromCsv(String csv) {
    final base = <String, double>{};
    final rows = <String, List<List<String>>>{};
    for (final line in csv.trim().split('\n').skip(1)) {
      final cells = line.trim().split(',');
      if (cells.length != 9) {
        throw const FormatException('Fila de balance inválida');
      }
      final value = double.parse(cells[5]);
      if (!value.isFinite || value <= 0) {
        throw const FormatException('Efecto inválido');
      }
      if (cells[0] == 'base') {
        if (base.containsKey(cells[4])) {
          throw const FormatException('Base duplicada');
        }
        base[cells[4]] = value;
      } else if (cells[0] == 'upgrade' && labels.containsKey(cells[1])) {
        rows.putIfAbsent(cells[1], () => []).add(cells);
      } else {
        throw const FormatException('ID de balance desconocido');
      }
    }
    final definitions = <UpgradeDefinition>[];
    for (final entry in labels.entries) {
      final levels = rows[entry.key];
      if (levels == null) throw const FormatException('Falta una mejora');
      for (var i = 0; i < levels.length; i++) {
        if (int.parse(levels[i][2]) != i + 1 || int.parse(levels[i][3]) < 0) {
          throw const FormatException('Niveles de mejora inválidos');
        }
        if (levels[i][7].isNotEmpty) {
          final requirement = levels[i][7].split(':');
          if (!labels.containsKey(requirement[0]) ||
              int.parse(requirement[1]) < 1) {
            throw const FormatException('Requisito inválido');
          }
        }
      }
      definitions.add(
        UpgradeDefinition(
          entry.key,
          entry.value[0],
          entry.value[1],
          levels.first[4],
          levels.first[6],
          [
            for (final row in levels)
              UpgradeLevel(int.parse(row[3]), double.parse(row[5]), row[7]),
          ],
        ),
      );
    }
    for (final key in [
      'production_duration',
      'closing_duration',
      'spawn_interval',
      'ball_value',
      'paddle_radius',
      'collection_radius',
      'ball_radius',
      'hole_capture_radius',
      'robot_speed',
      'ball_limit',
      'coin_pile_limit',
      'particle_limit',
    ]) {
      if (!base.containsKey(key)) throw FormatException('Falta $key');
    }
    return UpgradeCatalog._(base, definitions);
  }

  bool requirementsMet(UpgradeLevel level, Map<String, int> owned) {
    if (level.requirement.isEmpty) return true;
    final parts = level.requirement.split(':');
    return (owned[parts[0]] ?? 0) >= int.parse(parts[1]);
  }

  DaySettings settings(Map<String, int> owned, {int balanceVersion = 2}) {
    final values = Map.of(base);
    for (final definition in definitions) {
      final level = owned[definition.id] ?? 0;
      if (level > 0) {
        values[definition.effect] = definition.levels[level - 1].value;
      }
    }
    // Historical values keep in-progress v1/v2 saves playable until that day ends.
    if (balanceVersion == 1) {
      values['production_duration'] = const [
        60.0,
        65.0,
        70.0,
        75.0,
      ][owned['duration'] ?? 0];
      values['spawn_interval'] = const [
        .75,
        .65,
        .55,
        .45,
      ][owned['generator'] ?? 0];
    }
    return DaySettings(values, balanceVersion: balanceVersion);
  }

  void validateLevels(Map<String, int> levels) {
    for (final entry in levels.entries) {
      final definition = definitions
          .where((d) => d.id == entry.key)
          .firstOrNull;
      if (definition == null ||
          entry.value < 0 ||
          entry.value > definition.levels.length) {
        throw const FormatException('Mejoras guardadas inválidas');
      }
      if (entry.value > 0 &&
          !requirementsMet(definition.levels[entry.value - 1], levels)) {
        throw const FormatException('Requisito guardado incumplido');
      }
    }
  }
}
