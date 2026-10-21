import 'dart:math' as math;
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
    List<(double, double)> line(int x, int y, int dx, int dy, int count) => [
      for (var i = 0; i < count; i++)
        (48.0 + (x + dx * i + 2) * spacing, 48.0 + (y + dy * i + 2) * spacing),
    ];
    final routes = {
      'hand': [...line(5, 3, 0, 0, 1), ...line(6, 4, 1, 1, 4)],
      'hand_grip': [...line(6, 3, 0, 0, 1), ...line(7, 2, 1, -1, 4)],
      'generator': line(4, 2, -1, -1, 5),
      'duration': line(2, 1, -1, 0, 5),
      'double_spawn': line(-2, 0, 0, 0, 1),
      'reward': line(5, 2, 0, -1, 5),
      'walls': line(5, 4, 0, 1, 3),
      'combo': line(6, 2, 0, 0, 1),
      'capture_all': line(7, 3, 0, 0, 1),
      'capture_recharge': line(8, 3, 1, 0, 2),
      'boost': line(3, 2, 0, 0, 1),
      'boost_power': line(2, 2, 0, 0, 1),
      'boost_duration': line(3, 4, 0, 1, 2),
      'boost_recharge': line(3, 0, 1, 0, 2),
      'sweep': line(4, 4, 0, 0, 1),
      'collection': line(4, 3, -1, 0, 5),
      'magnet': line(2, 4, 0, 0, 1),
      'attraction': line(1, 5, -1, 1, 3),
      'broom': line(6, 5, 0, 0, 1),
      'paddle': line(6, 6, 0, 1, 5),
      'broom_v': line(7, 6, 0, 0, 1),
      'robot': line(4, 7, 0, 0, 1),
      'robot_speed': line(3, 8, -1, 0, 5),
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
    for (final node in nodes) {
      for (final id in node.parents) {
        paths[(id, node.id)] = _route(byId(id), node);
      }
    }
  }
  static const spacing = 64.0;
  static const canvasSize = 864.0;
  final Map<(String, String), List<(double, double)>> paths = {};
  final List<SkillNode> nodes = [];
  SkillNode get root => nodes.firstWhere((n) => n.id == 'hand:1');

  bool unlocked(SkillNode node, Map<String, int> levels) => {
    ...node.parents,
    ...node.upgrade.requirements,
  }.every((id) => byId(id).owned(levels));
  SkillNode byId(String id) => nodes.firstWhere((node) => node.id == id);

  /// Routes stay on a half-cell lattice: only cardinal and 45-degree segments.
  /// Computed once per tree, with clearance around every unrelated node.
  List<(double, double)> _route(SkillNode parent, SkillNode child) {
    final obstacles = nodes
        .where((n) => n.id != parent.id && n.id != child.id)
        .toList();
    bool clear((double, double) a, (double, double) b) {
      final dx = b.$1 - a.$1, dy = b.$2 - a.$2;
      return obstacles.every((n) {
        final t =
            (((n.x - a.$1) * dx + (n.y - a.$2) * dy) / (dx * dx + dy * dy))
                .clamp(0.0, 1.0);
        final x = a.$1 + t * dx - n.x, y = a.$2 + t * dy - n.y;
        return x * x + y * y >= 30 * 30;
      });
    }

    final start = (parent.x, parent.y), end = (child.x, child.y);
    final dx = (end.$1 - start.$1).abs(), dy = (end.$2 - start.$2).abs();
    if ((dx == 0 || dy == 0 || dx == dy) && clear(start, end)) {
      return [start, end];
    }
    (double, double) point((int, int) cell) =>
        (48.0 + cell.$1 * 32, 48.0 + cell.$2 * 32);
    final source = (
      ((parent.x - 48) / 32).round(),
      ((parent.y - 48) / 32).round(),
    );
    final target = (
      ((child.x - 48) / 32).round(),
      ((child.y - 48) / 32).round(),
    );
    final queue = [source];
    final previous = <(int, int), (int, int)?>{source: null};
    for (
      var index = 0;
      index < queue.length && !previous.containsKey(target);
      index++
    ) {
      final cell = queue[index];
      final candidates = [
        for (var x = -1; x <= 1; x++)
          for (var y = -1; y <= 1; y++)
            if (x != 0 || y != 0) (cell.$1 + x, cell.$2 + y),
      ];
      double distance((int, int) c) =>
          math.pow(c.$1 - target.$1, 2).toDouble() +
          math.pow(c.$2 - target.$2, 2).toDouble();
      candidates.sort((a, b) => distance(a).compareTo(distance(b)));
      for (final next in candidates) {
        if (next.$1 < -1 ||
            next.$2 < -1 ||
            next.$1 > 25 ||
            next.$2 > 25 ||
            previous.containsKey(next) ||
            !clear(point(cell), point(next))) {
          continue;
        }
        previous[next] = cell;
        queue.add(next);
      }
    }
    if (!previous.containsKey(target)) {
      throw StateError('No clear route from ${parent.id} to ${child.id}');
    }
    final result = <(double, double)>[];
    for ((int, int)? cell = target; cell != null; cell = previous[cell]) {
      result.add(point(cell));
    }
    final forward = result.reversed.toList();
    final simplified = <(double, double)>[];
    for (final p in forward) {
      if (simplified.length >= 2) {
        final a = simplified[simplified.length - 2], b = simplified.last;
        if ((b.$1 - a.$1) * (p.$2 - b.$2) == (b.$2 - a.$2) * (p.$1 - b.$1)) {
          simplified.removeLast();
        }
      }
      simplified.add(p);
    }
    return simplified;
  }

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
