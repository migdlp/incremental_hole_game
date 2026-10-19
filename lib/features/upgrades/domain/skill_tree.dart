import 'catalog.dart';

/// One node per purchased level. Discovery is derived from saved levels, so old
/// saves need no migration and never lose previously bought upgrades.
class SkillNode {
  const SkillNode(this.definition, this.level, this.parents, this.x, this.y);
  final UpgradeDefinition definition;
  final int level;
  final List<String> parents;
  final double x, y;
  String get id => '${definition.id}:$level';
  UpgradeLevel get upgrade => definition.levels[level - 1];
  bool owned(Map<String, int> levels) => (levels[definition.id] ?? 0) >= level;
}

class SkillTree {
  SkillTree(UpgradeCatalog catalog) {
    List<(double, double)> column(double x, double y, int count) => [
      for (var i = 0; i < count; i++) (x, y + 180 * i),
    ];
    final routes = {
      'hand': [(1400.0, 150.0), ...column(2250, 400, 4)],
      'generator': column(200, 400, 5),
      'duration': column(520, 760, 5),
      'double_spawn': [(200.0, 1360.0)],
      'reward': column(950, 400, 5),
      'sweep': [(1400.0, 400.0)],
      'collection': column(1400, 580, 5),
      'magnet': [(1720.0, 760.0)],
      'attraction': column(1720, 940, 3),
      'broom': [(2600.0, 580.0)],
      'paddle': column(2600, 760, 5),
      'broom_v': [(2920.0, 940.0)],
      'robot': [(2920.0, 1120.0)],
      'robot_speed': column(2920, 1300, 5),
    };
    for (final definition in catalog.definitions) {
      for (var i = 0; i < definition.levels.length; i++) {
        final parents = <String>{
          if (i > 0) '${definition.id}:$i',
          ...definition.levels[i].requirements.where(
            (requirement) =>
                i == 0 ||
                !definition.levels[i - 1].requirements.contains(requirement),
          ),
        };
        final position = routes[definition.id]![i];
        nodes.add(
          SkillNode(
            definition,
            i + 1,
            parents.toList(),
            position.$1,
            position.$2,
          ),
        );
      }
    }
  }
  final List<SkillNode> nodes = [];
  SkillNode get root => nodes.firstWhere((n) => n.id == 'hand:1');

  bool unlocked(SkillNode node, Map<String, int> levels) => {
    ...node.parents,
    ...node.upgrade.requirements,
  }.every((id) => byId(id).owned(levels));
  SkillNode byId(String id) => nodes.firstWhere((node) => node.id == id);

  List<SkillNode> visible(Map<String, int> levels) {
    final ids = <String>{};
    void reveal(SkillNode node) {
      if (!ids.add(node.id)) return;
      for (final parent in node.parents) {
        reveal(byId(parent));
      }
    }

    for (final node in nodes) {
      if (node.owned(levels)) reveal(node);
      if (unlocked(node, levels)) ids.add(node.id);
    }
    return nodes.where((node) => ids.contains(node.id)).toList();
  }
}
