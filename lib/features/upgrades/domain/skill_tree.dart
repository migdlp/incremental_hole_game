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
    const routes = {
      'generator': [(700.0, 1150.0), (950.0, 950.0), (1110.0, 740.0)],
      'broom': [(470.0, 980.0)],
      'paddle': [(300.0, 800.0), (160.0, 640.0), (160.0, 440.0)],
      'broom_v': [(430.0, 620.0)],
      'sweep': [(920.0, 1140.0)],
      'collection': [(700.0, 940.0), (640.0, 730.0), (620.0, 520.0)],
      'magnet': [(820.0, 730.0)],
      'reward': [(1120.0, 1100.0), (1280.0, 940.0), (1360.0, 740.0)],
      'duration': [(940.0, 1330.0), (1110.0, 1460.0), (1320.0, 1460.0)],
      'robot': [(240.0, 1000.0)],
      'robot_speed': [(120.0, 1160.0), (120.0, 1340.0), (300.0, 1440.0)],
    };
    for (final definition in catalog.definitions) {
      for (var i = 0; i < definition.levels.length; i++) {
        final requirement = definition.levels[i].requirement;
        final parents = <String>{
          if (i > 0) '${definition.id}:$i',
          if (requirement.isNotEmpty) requirement,
          if (i == 0 && requirement.isEmpty && definition.id != 'generator')
            definition.id == 'reward' ? 'generator:2' : 'generator:1',
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
  SkillNode get root => nodes.firstWhere((n) => n.id == 'generator:1');

  bool unlocked(SkillNode node, Map<String, int> levels) =>
      node.parents.every((id) => byId(id).owned(levels));
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
