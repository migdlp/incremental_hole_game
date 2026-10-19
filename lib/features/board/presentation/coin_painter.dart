import 'package:flutter/painting.dart';
import '../domain/coin_denomination.dart';

Color coinColor(CoinDenomination denomination) => switch (denomination) {
  CoinDenomination.one => const Color(0xffeab308),
  CoinDenomination.ten => const Color(0xff10b981),
  CoinDenomination.fifty => const Color(0xff3b82f6),
  CoinDenomination.hundred => const Color(0xffa855f7),
  CoinDenomination.fiveHundred => const Color(0xfff43f5e),
};

/// Every denomination has exactly the same geometry and no face text.
void paintCoin(Canvas canvas, Offset center, CoinDenomination denomination) {
  final color = coinColor(denomination);
  canvas.drawCircle(
    center + const Offset(0, 3),
    10,
    Paint()..color = const Color(0x40644c2d),
  );
  canvas.drawCircle(
    center,
    10,
    Paint()..color = Color.lerp(color, const Color(0xff172333), .35)!,
  );
  canvas.drawCircle(center - const Offset(0, 1), 8.5, Paint()..color = color);
  canvas.drawCircle(
    center - const Offset(0, 1),
    5.5,
    Paint()
      ..color = const Color(0x66ffffff)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );
}
