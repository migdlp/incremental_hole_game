class UpgradeLevel {
  const UpgradeLevel(this.cost, this.value, this.requirement);
  final int cost;
  final double value;
  final String requirement;
  List<String> get requirements =>
      requirement.isEmpty ? const [] : requirement.split('&');
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
  DaySettings(this.values, {this.balanceVersion = 7});
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
    'hand': ['Capacidad de la mano', 'Control'],
    'hand_grip': ['Fuerza de agarre', 'Control'],
    'broom': ['Escoba recta', 'Control'],
    'paddle': ['Escoba más ancha', 'Control'],
    'broom_v': ['Escoba en V', 'Control'],
    'sweep': ['Recogida por barrido', 'Recolección'],
    'collection': ['Área de recogida', 'Recolección'],
    'magnet': ['Imán', 'Recolección'],
    'attraction': ['Alcance del imán', 'Recolección'],
    'g1_auto': ['Cañón 1 · Automático', 'Producción'],
    'g1_auto_speed': ['Cañón 1 · Ritmo automático', 'Producción'],
    'g1_aim': ['Cañón 1 · Puntería', 'Producción'],
    'g2_unlock': ['Cañón 2', 'Producción'],
    'g2_auto': ['Cañón 2 · Automático', 'Producción'],
    'g2_auto_speed': ['Cañón 2 · Ritmo automático', 'Producción'],
    'g2_aim': ['Cañón 2 · Puntería', 'Producción'],
    'g3_unlock': ['Cañón 3', 'Producción'],
    'g3_auto': ['Cañón 3 · Automático', 'Producción'],
    'g3_auto_speed': ['Cañón 3 · Ritmo automático', 'Producción'],
    'g3_aim': ['Cañón 3 · Puntería', 'Producción'],
    'g4_unlock': ['Cañón 4', 'Producción'],
    'g4_auto': ['Cañón 4 · Automático', 'Producción'],
    'g4_auto_speed': ['Cañón 4 · Ritmo automático', 'Producción'],
    'g4_aim': ['Cañón 4 · Puntería', 'Producción'],
    'reward': ['Mayor recompensa', 'Valor'],
    'duration': ['Día más largo', 'Tiempo'],
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
        for (final item in UpgradeLevel(0, 1, levels[i][7]).requirements) {
          final requirement = item.split(':');
          if (requirement.length != 2 ||
              !labels.containsKey(requirement[0]) ||
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
      'ball_value',
      'paddle_radius',
      'collection_radius',
      'ball_radius',
      'hole_capture_radius',
      'robot_speed',
      'ball_limit',
      'coin_pile_limit',
      'particle_limit',
      'hand_capacity',
      'max_ball_speed',
      'wall_restitution',
      'hole_capture_speed',
      'cannon_cooldown',
      'cannon_sweep_period',
      'cannon_shot_speed',
      'g1_arc',
      'g1_auto_interval',
      'g2_arc',
      'g2_auto_interval',
      'g3_arc',
      'g3_auto_interval',
      'g4_arc',
      'g4_auto_interval',
    ]) {
      if (!base.containsKey(key)) throw FormatException('Falta $key');
    }
    return UpgradeCatalog._(base, definitions);
  }

  bool requirementsMet(UpgradeLevel level, Map<String, int> owned) {
    return level.requirements.every((item) {
      final parts = item.split(':');
      return (owned[parts[0]] ?? 0) >= int.parse(parts[1]);
    });
  }

  DaySettings settings(Map<String, int> owned) {
    final values = Map.of(base);
    for (final definition in definitions) {
      final level = owned[definition.id] ?? 0;
      if (level > 0) {
        values[definition.effect] = definition.levels[level - 1].value;
      }
    }
    return DaySettings(values);
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
