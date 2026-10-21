import 'legacy_balance.dart';
import 'balance_v4.dart';
import 'balance_v5.dart';
import 'balance_v6.dart';
import 'balance_v7.dart';
import 'balance_v8.dart';
import 'balance_v9.dart';
import 'balance_v10.dart';
import 'balance_v11.dart';
import 'balance_v12.dart';
import 'balance_v13.dart';
import 'balance_v14.dart';
import 'balance_v15.dart';

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
  DaySettings(this.values, {this.balanceVersion = 16});
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
    'prestige': ['Prestigio', 'Prestigio'],
    'hand': ['Capacidad de la mano', 'Control'],
    'walls': ['Paredes rebotadoras', 'Control'],
    'bat': ['Bate de béisbol', 'Control'],
    'hand_grip': ['Fuerza de agarre', 'Control'],
    'broom': ['Escoba recta', 'Control'],
    'paddle': ['Escoba más ancha', 'Control'],
    'broom_v': ['Escoba en V', 'Control'],
    'double_spawn': ['Doble emisión', 'Producción'],
    'generator': ['Generador rápido', 'Producción'],
    'launcher': ['Generador lanzador', 'Producción'],
    'launcher_rate': ['Frecuencia del lanzador', 'Producción'],
    'reward': ['Mayor recompensa', 'Valor'],
    'duration': ['Día más largo', 'Tiempo'],
    'robot': ['Robot ayudante', 'Automatización'],
    'robot_speed': ['Velocidad del robot', 'Automatización'],
    'combo': ['Racha de capturas', 'Valor'],
    'capture_all': ['Captura total', 'Control'],
    'capture_recharge': ['Recarga de captura total', 'Control'],
    'boost': ['Aceleración especial', 'Producción'],
    'boost_power': ['Potencia de aceleración', 'Producción'],
    'boost_duration': ['Duración de aceleración', 'Producción'],
    'boost_recharge': ['Recarga de aceleración', 'Producción'],
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
      if (!value.isFinite ||
          (value <= 0 &&
              !(cells[0] == 'base' &&
                  (cells[4] == 'gravity_probability' ||
                      cells[4] == 'black_hole_probability' ||
                      cells[4] == 'closing_duration') &&
                  value == 0))) {
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
      'reward_delay',
      'reward_visual_limit',
      'reward_ledger_limit',
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
      'hand_capacity',
      'balls_per_spawn',
      'wall_restitution',
      'ball_speed_limit',
      'bat_half_length',
      'bat_thickness',
      'bat_restitution',
      'bat_manual_gain',
      'bat_move_speed',
      'bat_angular_speed',
      'gravity_probability',
      'gravity_duration',
      'gravity_object_speed',
      'gravity_acceleration',
      'gravity_response',
      'gravity_ball_damping',
      'gravity_tool_damping',
      'feeding_quota_initial',
      'feeding_quota_step',
      'launcher_interval',
      'launcher_speed',
      'launcher_body_radius',
      'launcher_barrel_length',
      'launcher_barrel_radius',
      'launcher_pressure_threshold',
      'launcher_contact_pressure_limit',
      'launcher_pressure_stiffness',
      'launcher_pressure_response',
      'launcher_mass',
      'launcher_damping',
      'launcher_pressure_speed',
      'launcher_restitution',
      'launcher_obstruction_force',
      'launcher_move_speed',
      'launcher_angular_speed',
      'black_hole_probability',
      'black_hole_interval',
      'black_hole_duration',
      'black_hole_radius',
      'black_hole_acceleration',
      'black_hole_curve',
      'black_hole_object_speed',
    ]) {
      if (!base.containsKey(key)) throw FormatException('Falta $key');
    }
    if (base['gravity_probability']! > 1 || base['gravity_duration']! > 10) {
      throw const FormatException('Límites de Gravedad inválidos');
    }
    if (base['black_hole_probability']! > 1 ||
        base['black_hole_interval']! < .25 ||
        base['black_hole_duration']! > 10 ||
        base['black_hole_radius']! <= base['hole_capture_radius']! + 15) {
      throw const FormatException('Límites de Agujero negro inválidos');
    }
    if (base['launcher_pressure_threshold']! <=
            3 * base['launcher_contact_pressure_limit']! ||
        base['launcher_speed']! > base['ball_speed_limit']! ||
        base['launcher_interval']! < .25 ||
        base['launcher_body_radius']! * 2 >= 140 ||
        2 *
                (base['launcher_barrel_length']! +
                    base['launcher_barrel_radius']!) >=
            140) {
      throw const FormatException('Límites del lanzador inválidos');
    }
    var previousLauncherInterval = base['launcher_interval']!;
    for (final level
        in definitions.firstWhere((d) => d.id == 'launcher_rate').levels) {
      if (level.value < .25 || level.value >= previousLauncherInterval) {
        throw const FormatException('Frecuencia del lanzador inválida');
      }
      previousLauncherInterval = level.value;
    }
    for (final key in [
      'feeding_quota_initial',
      'feeding_quota_step',
      'reward_visual_limit',
      'reward_ledger_limit',
    ]) {
      if (base[key]! != base[key]!.roundToDouble()) {
        throw const FormatException('Cuota de prueba no entera');
      }
    }
    return UpgradeCatalog._(base, definitions);
  }

  bool requirementsMet(UpgradeLevel level, Map<String, int> owned) {
    return level.requirements.every((item) {
      final parts = item.split(':');
      return (owned[parts[0]] ?? 0) >= int.parse(parts[1]);
    });
  }

  DaySettings settings(Map<String, int> owned, {int balanceVersion = 16}) {
    final values = balanceVersion <= 15 ? <String, double>{} : Map.of(base);
    if (balanceVersion <= 15) {
      final historicalCsv = balanceVersion == 15
          ? balanceV15Csv
          : balanceVersion == 14
          ? balanceV14Csv
          : balanceVersion == 13
          ? balanceV13Csv
          : balanceVersion == 12
          ? balanceV12Csv
          : balanceVersion == 11
          ? balanceV11Csv
          : balanceVersion == 10
          ? balanceV10Csv
          : balanceVersion == 9
          ? balanceV9Csv
          : balanceVersion == 8
          ? balanceV8Csv
          : balanceVersion == 7
          ? balanceV7Csv
          : balanceVersion == 6
          ? balanceV6Csv
          : balanceVersion == 5
          ? balanceV5Csv
          : balanceVersion == 4
          ? balanceV4Csv
          : legacyBalanceCsv;
      for (final line in historicalCsv.trim().split('\n').skip(1)) {
        final cells = line.split(',');
        if (cells[0] == 'base' ||
            (cells[0] == 'upgrade' &&
                (owned[cells[1]] ?? 0) == int.parse(cells[2]))) {
          values[cells[4]] = double.parse(cells[5]);
        }
      }
    } else {
      for (final definition in definitions) {
        final level = owned[definition.id] ?? 0;
        if (level > 0) {
          values[definition.effect] = definition.levels[level - 1].value;
        }
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
    if (balanceVersion == 2) {
      values['spawn_interval'] = const [
        3.0,
        2.6,
        2.2,
        1.8,
      ][owned['generator'] ?? 0];
    }
    return DaySettings(values, balanceVersion: balanceVersion);
  }

  static const retiredIds = {'sweep', 'collection', 'magnet', 'attraction'};
  static UpgradeDefinition? retiredDefinition(String id) {
    if (!retiredIds.contains(id)) return null;
    final rows = balanceV14Csv
        .trim()
        .split('\n')
        .skip(1)
        .map((s) => s.split(','))
        .where((r) => r[0] == 'upgrade' && r[1] == id)
        .toList();
    return UpgradeDefinition(id, id, '', rows.first[4], rows.first[6], [
      for (final row in rows)
        UpgradeLevel(int.parse(row[3]), double.parse(row[5]), row[7]),
    ]);
  }

  void validateLevels(
    Map<String, int> levels, {
    Map<String, int> grandfathered = const {},
    bool legacy = false,
    bool retiredRemoved = false,
    Map<String, int> previousTree = const {},
    int balanceVersion = 16,
  }) {
    bool met(UpgradeLevel level) => level.requirements.every(
      (requirement) =>
          (retiredRemoved &&
              retiredIds.contains(requirement.split(':').first)) ||
          requirementsMet(UpgradeLevel(0, 1, requirement), levels),
    );
    if (previousTree.isNotEmpty) {
      validateLevels(
        previousTree,
        grandfathered: grandfathered,
        balanceVersion: 5,
        retiredRemoved: retiredRemoved,
      );
      for (final entry in previousTree.entries) {
        if (entry.value < 0 || entry.value > (levels[entry.key] ?? 0)) {
          throw const FormatException('Compras del árbol anterior inválidas');
        }
      }
    }
    if (!legacy && grandfathered.isNotEmpty) {
      validateLevels(
        grandfathered,
        legacy: true,
        retiredRemoved: retiredRemoved,
      );
    }
    for (final entry in grandfathered.entries) {
      if (entry.value < 0 || entry.value > (levels[entry.key] ?? 0)) {
        throw const FormatException('Compras anteriores inválidas');
      }
    }
    for (final entry in levels.entries) {
      final definition =
          definitions.where((d) => d.id == entry.key).firstOrNull ??
          (balanceVersion <= 14 || legacy
              ? retiredDefinition(entry.key)
              : null);
      if (definition == null ||
          entry.value < 0 ||
          entry.value > definition.levels.length) {
        throw const FormatException('Mejoras guardadas inválidas');
      }
      if (legacy) {
        final oldRows = legacyBalanceCsv
            .trim()
            .split('\n')
            .skip(1)
            .map((line) => line.split(','));
        final row = oldRows
            .where(
              (r) =>
                  r[0] == 'upgrade' &&
                  r[1] == entry.key &&
                  int.parse(r[2]) == entry.value,
            )
            .firstOrNull;
        if (entry.value > 0 &&
            (row == null || !met(UpgradeLevel(0, 1, row[7])))) {
          throw const FormatException('Compra anterior inválida');
        }
      } else if (entry.value > (grandfathered[entry.key] ?? 0) &&
          entry.value > (previousTree[entry.key] ?? 0)) {
        var next = definition.levels[entry.value - 1];
        if (balanceVersion == 5) {
          final row = balanceV5Csv
              .trim()
              .split('\n')
              .skip(1)
              .map((line) => line.split(','))
              .firstWhere(
                (r) =>
                    r[0] == 'upgrade' &&
                    r[1] == entry.key &&
                    int.parse(r[2]) == entry.value,
              );
          next = UpgradeLevel(0, 1, row[7]);
        }
        if (!met(next)) {
          throw const FormatException('Requisito guardado incumplido');
        }
      }
    }
  }
}
