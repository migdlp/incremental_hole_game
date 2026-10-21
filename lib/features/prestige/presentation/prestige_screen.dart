import 'package:flutter/material.dart';
import '../../../app/game_session.dart';
import '../domain/meta_progress.dart';

class PrestigeScreen extends StatelessWidget {
  const PrestigeScreen({super.key, required this.session});
  final GameSession session;
  @override
  Widget build(BuildContext context) {
    final defeated = session.meta.phase == PrestigePhase.defeat;
    return PopScope(
      canPop: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (defeated) ...[
                const Text(
                  'DERROTA',
                  key: ValueKey('prestige-defeat'),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 36),
                FilledButton(
                  key: const ValueKey('prestige-continue'),
                  onPressed: session.prestigeReady
                      ? session.continueToPrestigeShop
                      : null,
                  child: const Text('Continuar'),
                ),
              ] else ...[
                const Text(
                  'Prestigio',
                  key: ValueKey('prestige-shop'),
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xfff5b83d),
                      size: 32,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${session.meta.stars}',
                      key: const ValueKey('prestige-star-balance'),
                      style: const TextStyle(fontSize: 30),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('Un nuevo comienzo'),
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('prestige-new-run'),
                  onPressed: session.prestigeReady ? session.beginNewRun : null,
                  child: const Text('Nueva partida'),
                ),
              ],
              if (!session.prestigeReady) ...[
                const SizedBox(height: 20),
                Text(
                  session.saveError == null
                      ? 'Guardando…'
                      : 'Guarda la partida para continuar.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
