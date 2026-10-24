import '../../board/domain/coin_denomination.dart';
import '../../feeding/domain/feeding_progress.dart';
import '../../progression/domain/progress.dart';

class ResultStack {
  ResultStack(this.denomination, this.count);
  final CoinDenomination denomination;
  final int count;
  int get amount => denomination.amount * count;
  int get visualCount => count.clamp(0, 6);
  // Each bounded visual packet represents an exact, possibly large quantity.
  int countThrough(int packet) => (count * (packet + 1)) ~/ visualCount;
}

/// Immutable presentation snapshot. It has no access to payment or save APIs.
class ResultsData {
  ResultsData({
    required DayResult result,
    required FeedingProgress feeding,
    required this.balance,
  }) : income = result.income,
       captured = result.captured,
       foodAfter = feeding.points,
       foodBefore = feeding.points >= feeding.runBalls
           ? feeding.points - feeding.runBalls
           : BigInt.zero,
       quotaLevel = feeding.period,
       target = feeding.target,
       stacks = _stacks(result) {
    if (stacks.fold<int>(0, (sum, s) => sum + s.amount) != income) {
      throw ArgumentError('Desglose distinto del ingreso real');
    }
  }
  final int income, balance, captured, quotaLevel;
  final BigInt foodBefore, foodAfter;
  final BigInt? target;
  final List<ResultStack> stacks;
  // A reopened historical result may follow spending in the shop.
  int get startingBalance => balance < income ? balance : balance - income;
  static List<ResultStack> _stacks(DayResult result) {
    final counts =
        result.collectedCoins ??
        {
          for (final stack in CoinDenomination.split(result.income))
            stack.denomination.amount: stack.count,
        };
    return List.unmodifiable([
      for (final denomination in CoinDenomination.values)
        if ((counts[denomination.amount] ?? 0) > 0)
          ResultStack(denomination, counts[denomination.amount]!),
    ]);
  }
}

final _grouping = RegExp(r'\B(?=(\d{3})+(?!\d))');

String resultNumber(int value) {
  if (value < 1000000) {
    return '$value'.replaceAllMapped(_grouping, (_) => '.');
  }
  final divisor = value >= 1000000000000
      ? 1e12
      : value >= 1000000000
      ? 1e9
      : 1e6;
  final suffix = divisor == 1e12
      ? ' B'
      : divisor == 1e9
      ? ' mil M'
      : ' M';
  return '${(value / divisor).toStringAsFixed(2).replaceAll('.', ',')}$suffix';
}
