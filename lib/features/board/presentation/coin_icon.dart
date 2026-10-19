import 'package:flutter/widgets.dart';
import '../domain/coin_denomination.dart';
import 'coin_painter.dart';

/// Same coin face and dimensions for every denomination throughout the UI.
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.denomination = CoinDenomination.one});
  final CoinDenomination denomination;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Moneda de ${denomination.amount}',
    image: true,
    child: SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _CoinIconPainter(denomination)),
    ),
  );
}

class _CoinIconPainter extends CustomPainter {
  const _CoinIconPainter(this.denomination);
  final CoinDenomination denomination;
  @override
  void paint(Canvas canvas, Size size) =>
      paintCoin(canvas, const Offset(12, 10), denomination);
  @override
  bool shouldRepaint(_CoinIconPainter oldDelegate) =>
      oldDelegate.denomination != denomination;
}
