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
      for (var i = 0; i < count; i++) (x, y + 96 * i),
    ];
    final routes = {
      'hand': [(352.0, 64.0), ...column(616, 168, 4)],
      'generator': column(88, 168, 5),
      'duration': column(176, 360, 5),
      'double_spawn': [(88.0, 744.0)],
      'reward': column(264, 168, 5),
      'sweep': [(440.0, 168.0)],
      'collection': column(440, 264, 5),
      'magnet': [(528.0, 360.0)],
      'attraction': column(528, 456, 3),
      'broom': [(704.0, 264.0)],
      'paddle': column(704, 360, 5),
      'broom_v': [(792.0, 456.0)],
      'robot': [(792.0, 552.0)],
      'robot_speed': column(792, 648, 5),
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
