/// The only physical coin values. Splitting preserves the exact payout.
enum CoinDenomination {
  one(1),
  ten(10),
  fifty(50),
  hundred(100),
  fiveHundred(500);

  const CoinDenomination(this.amount);
  final int amount;

  static Map<int, int> readCounts(dynamic json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Recuento de monedas inválido');
    }
    final counts = <int, int>{};
    for (final entry in json.entries) {
      final denomination = int.tryParse(entry.key);
      if (entry.key != '$denomination' ||
          !values.any((d) => d.amount == denomination) ||
          entry.value is! int ||
          (entry.value as int) < 0) {
        throw const FormatException('Denominación o cantidad inválida');
      }
      counts[denomination!] = entry.value as int;
    }
    return counts;
  }

  static List<({CoinDenomination denomination, int count})> split(int value) {
    final stacks = <({CoinDenomination denomination, int count})>[];
    for (final denomination in values.reversed) {
      final count = value ~/ denomination.amount;
      if (count > 0) stacks.add((denomination: denomination, count: count));
      value %= denomination.amount;
    }
    return stacks;
  }
}
