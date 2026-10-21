import 'package:flutter/material.dart';
import '../../../app/game_session.dart';

class FeedingSummary extends StatelessWidget {
  const FeedingSummary({
    super.key,
    required this.session,
    this.compact = false,
  });
  final GameSession session;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final feed = session.feeding;
    final title = feed.missed
        ? 'Cuota no alcanzada'
        : feed.met
        ? 'Cuota completada'
        : 'Alimenta al agujero';
    final amount = feed.target == null
        ? '${feed.points}'
        : '${feed.points} / ${feed.target}';
    final remaining = feed.remainingDays == 1
        ? '1 jornada restante'
        : '${feed.remainingDays} jornadas restantes';
    return Semantics(
      key: ValueKey(compact ? 'feeding-store-summary' : 'feeding-summary'),
      container: true,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 0,
          vertical: compact ? 4 : 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$title · $amount',
              style: TextStyle(
                fontSize: compact ? 13 : 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xff8dd4b2),
              ),
            ),
            Text(remaining, style: TextStyle(fontSize: compact ? 12 : 14)),
            if (!compact &&
                feed.due &&
                feed.target != null &&
                !session.debugFeedingFailed)
              Text('Próximo objetivo: ${feed.nextTarget}'),
            if (!compact && session.debugFeedingFailed) ...[
              const Text('Fin de la prueba de cuota.'),
              TextButton(
                onPressed: session.debugRestartFeedingPeriod,
                child: const Text('Reiniciar período de prueba'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
