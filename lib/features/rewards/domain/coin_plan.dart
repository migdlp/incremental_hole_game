import 'dart:math' as math;
import '../../board/domain/coin_denomination.dart';
import 'reward_visual_config.dart';

/// Counts, not objects: even a trillion coins occupy at most one entry per type.
Map<int, int> planCoins(
  int amount,
  RewardVisualConfig config, {
  Iterable<int>? denominations,
}) {
  if (amount < 0 || amount > 0x1fffffffffffff) {
    throw ArgumentError('Importe visual inválido');
  }
  final values =
      (denominations ?? CoinDenomination.values.map((d) => d.amount))
          .toSet()
          .toList()
        ..sort();
  if (values.isEmpty || values.first != 1) {
    throw ArgumentError('Se necesita denominación unitaria');
  }
  final counts = <int, int>{};
  var remainder = amount, count = 0;
  for (final d in values.reversed) {
    final n = remainder ~/ d;
    if (n > 0) {
      counts[d] = n;
      count += n;
    }
    remainder %= d;
  }
  if (amount < config.large) return counts;
  final desired =
      (config.target * math.log(amount + 1) / math.log(config.large + 1))
          .round()
          .clamp(config.target, config.target * 3);
  Map<int, int> split(int value) {
    var left = value;
    final result = <int, int>{};
    for (final d in values.reversed.where((d) => d < value)) {
      final n = left ~/ d;
      if (n > 0) result[d] = n;
      left %= d;
    }
    return result;
  }

  void replace(int value, Map<int, int> children) {
    counts[value] = counts[value]! - 1;
    count--;
    for (final e in children.entries) {
      counts.update(e.key, (n) => n + e.value, ifAbsent: () => e.value);
      count += e.value;
    }
  }

  // One exact substitution at each scale gives variety even when greedy counts
  // already exceed the desired count (e.g. 100 coins of 500 for 50,000).
  for (final d in values.reversed.where((d) => d > 1)) {
    if ((counts[d] ?? 0) > 0) replace(d, split(d));
  }
  for (
    var iteration = 0;
    count < desired && iteration < config.target * 3;
    iteration++
  ) {
    var expanded = false;
    for (final d in values.reversed.where((d) => d > 1)) {
      if ((counts[d] ?? 0) <= 1) continue;
      final children = split(d);
      final delta = children.values.fold<int>(-1, (a, b) => a + b);
      if (count + delta > desired + 8) continue;
      replace(d, children);
      expanded = true;
      break;
    }
    if (!expanded) break;
  }
  counts.removeWhere((key, value) => value == 0);
  return counts;
}
