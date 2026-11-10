import '../../board/domain/coin_denomination.dart';

class CollectionCoin {
  CollectionCoin(this.denomination, this.quantity, {this.ready = false});
  final CoinDenomination denomination;
  int quantity;
  bool ready;
}

/// Presentation only. Each emitted visual packet has one stable logical slot.
class DailyCoinCollection {
  String day = '';
  final coins = <CollectionCoin>[];
  int placed = 0, revision = 0, generation = 0;
  void begin(String identity) {
    day = identity;
    generation++;
    coins.clear();
    placed = 0;
    revision++;
  }

  int reserve(CoinDenomination type, int quantity) {
    coins.add(CollectionCoin(type, quantity));
    return coins.length - 1;
  }

  void addQuantity(int slot, int quantity) {
    coins[slot].quantity += quantity;
  }

  int arrive(int slot, String identity) {
    if (identity != day || slot < placed || slot >= coins.length) return 0;
    coins[slot].ready = true;
    var quantity = 0;
    while (placed < coins.length && coins[placed].ready) {
      quantity += coins[placed++].quantity;
      revision++;
    }
    return quantity;
  }

  void resolve() {
    for (final coin in coins) {
      coin.ready = true;
    }
    placed = coins.length;
    revision++;
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'placed': placed,
    'coins': [
      for (final c in coins) [c.denomination.amount, c.quantity],
    ],
  };
  void restore(
    dynamic raw, {
    required String identity,
    required Map<int, int> planned,
  }) {
    if (raw is! Map<String, dynamic> ||
        raw['day'] is! String ||
        raw['coins'] is! List ||
        raw['placed'] is! int) {
      throw const FormatException('Colección visual inválida');
    }
    final records = raw['coins'] as List;
    if (raw['day'] != identity && records.isNotEmpty) {
      throw const FormatException('Colección de otra jornada');
    }
    if (records.length > 100000 ||
        raw['placed'] < 0 ||
        raw['placed'] > records.length) {
      throw const FormatException('Tamaño de colección inválido');
    }
    final parsed = <CollectionCoin>[], used = <int, int>{};
    for (final record in records) {
      if (record is! List ||
          record.length != 2 ||
          record[0] is! int ||
          record[1] is! int ||
          record[1] <= 0) {
        throw const FormatException('Moneda de colección inválida');
      }
      final amount = record[0] as int, quantity = record[1] as int;
      final types = CoinDenomination.values.where((d) => d.amount == amount);
      if (types.isEmpty || quantity > (planned[amount] ?? 0)) {
        throw const FormatException('Denominación o cantidad inválida');
      }
      used.update(amount, (n) => n + quantity, ifAbsent: () => quantity);
      if (used[amount]! > (planned[amount] ?? 0)) {
        throw const FormatException('Colección excede recompensas');
      }
      parsed.add(CollectionCoin(types.single, quantity, ready: true));
    }
    begin(identity);
    coins.addAll(parsed);
    // The economic restore settles its ledger independently. Resolve existing
    // reservations visually, without replaying receipts or inventing packets.
    placed = coins.length;
    revision++;
  }
}

/// Stable device-independent grid, expressed in Flutter logical pixels.
class CollectionGrid {
  CollectionGrid(double width, double availableHeight) {
    final desired = (availableHeight * .18).clamp(18.0, 52.0);
    rows = (1 + (desired - 8 - faceHeight) / layerStep).floor().clamp(1, 10);
    height = 8 + faceHeight + (rows - 1) * layerStep;
    columns = ((width - 8) / columnPitch).floor().clamp(1, 10000);
  }
  static const diameter = 16.0, faceScaleY = .55;
  static const faceHeight = diameter * faceScaleY;
  static const layerStep = 2.5, columnPitch = diameter + 1;
  late final int rows, columns;
  late final double height;
  int get capacity => rows * columns;
  double x(int slot) => 4 + diameter / 2 + (slot ~/ rows) * columnPitch;
  double y(int slot) => height - 4 - faceHeight / 2 - (slot % rows) * layerStep;
}
