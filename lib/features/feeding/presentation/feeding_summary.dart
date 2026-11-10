import 'package:flutter/material.dart';
import '../../../app/game_session.dart';
import '../domain/feeding_progress.dart';

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
              'CUOTA ${feed.period}',
              style: TextStyle(
                fontSize: compact ? 13 : 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xff8dd4b2),
              ),
            ),
            Text(
              '${ballNumber(feed.points)}${feed.target == null ? '' : ' / ${ballNumber(feed.target!)}'} bolas',
            ),
            if (feed.remaining != null)
              Text('Faltan ${ballNumber(feed.remaining!)}.'),
          ],
        ),
      ),
    );
  }
}
