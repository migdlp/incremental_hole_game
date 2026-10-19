import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/coin_denomination.dart';

Color coinColor(CoinDenomination denomination) => switch (denomination) {
  CoinDenomination.one => const Color(0xffeab308),
  CoinDenomination.ten => const Color(0xff10b981),
  CoinDenomination.fifty => const Color(0xff3b82f6),
  CoinDenomination.hundred => const Color(0xffa855f7),
  CoinDenomination.fiveHundred => const Color(0xfff43f5e),
};

/// Piles show overlapping colored coins, never numbers or currency symbols.
/// At most three layers per denomination keep rendering bounded for large saves.
void paintCoinPile(Canvas canvas, Offset center, int value) {
  final stacks = CoinDenomination.split(value).reversed.toList();
  for (var index = 0; index < stacks.length; index++) {
    final stack = stacks[index];
    final color = coinColor(stack.denomination);
    final offset = Offset((index - (stacks.length - 1) / 2) * 5, -index * 2);
    for (var layer = 0; layer < math.min(stack.count, 3); layer++) {
      final p = center + offset - Offset(0, layer * 2.5);
      canvas.drawCircle(
        p + const Offset(0, 3),
        10,
        Paint()..color = const Color(0x40644c2d),
      );
      canvas.drawCircle(
        p,
        10,
        Paint()..color = Color.lerp(color, const Color(0xff172333), .35)!,
      );
      canvas.drawCircle(p - const Offset(0, 1), 8.5, Paint()..color = color);
      canvas.drawCircle(
        p - const Offset(0, 1),
        5.5,
        Paint()
          ..color = const Color(0x66ffffff)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }
}
