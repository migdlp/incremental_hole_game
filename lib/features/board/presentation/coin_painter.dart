import 'package:flutter/painting.dart';
import '../domain/coin_denomination.dart';

Color coinColor(CoinDenomination denomination) => switch (denomination) {
  CoinDenomination.one => const Color(0xffc88b58),
  CoinDenomination.ten => const Color(0xffc8d2df),
  CoinDenomination.fifty => const Color(0xffedc64c),
  CoinDenomination.hundred => const Color(0xff45bd87),
  CoinDenomination.fiveHundred => const Color(0xffdf6070),
};

final _coinStamp = Path()
  ..moveTo(0, -.38)
  ..lineTo(.25, 0)
  ..lineTo(0, .38)
  ..lineTo(-.25, 0)
  ..close();

/// Flat minted disc with a milled edge and stamped face, shared by HUD and pool.
/// Reuses the caller's paint during flight; geometry never determines its value.
void paintCoin(
  Canvas canvas,
  Offset center,
  CoinDenomination denomination, {
  double radius = 10,
  Paint? paint,
}) {
  final brush = paint ?? Paint();
  final color = coinColor(denomination);
  final outer = Rect.fromCenter(
    center: center,
    width: radius * 2,
    height: radius * 1.6,
  );
  brush
    ..style = PaintingStyle.fill
    ..color = const Color(0xff674a12);
  canvas.drawOval(outer.shift(Offset(0, radius * .22)), brush);
  brush
    ..style = PaintingStyle.stroke
    ..strokeWidth = radius * .10
    ..color = const Color(0xffb3842e);
  for (var i = -2; i <= 2; i++) {
    final x = center.dx + i * radius * .28;
    canvas.drawLine(
      Offset(x, center.dy + radius * .64),
      Offset(x, center.dy + radius * .86),
      brush,
    );
  }
  brush
    ..style = PaintingStyle.fill
    ..color = color;
  canvas.drawOval(outer, brush);
  brush
    ..style = PaintingStyle.stroke
    ..strokeWidth = radius * .12
    ..color = const Color(0xff6e511d);
  canvas.drawOval(outer.deflate(radius * .08), brush);
  brush
    ..strokeWidth = radius * .08
    ..color = const Color(0xffffedab);
  canvas.drawOval(outer.deflate(radius * .25), brush);
  // A simple engraved lozenge reads as a minted face at seven logical pixels.
  brush
    ..style = PaintingStyle.fill
    ..color = const Color(0xff795516);
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(radius);
  canvas.drawPath(_coinStamp, brush);
  canvas.restore();
}
