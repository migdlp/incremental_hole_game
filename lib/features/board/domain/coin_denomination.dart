/// Currency units within a pile. Decomposition never changes its total value.
enum CoinDenomination {
  one(1),
  ten(10),
  fifty(50),
  hundred(100),
  fiveHundred(500);

  const CoinDenomination(this.amount);
  final int amount;

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
