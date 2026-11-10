import 'package:flutter/material.dart';
import '../../../app/game_session.dart';
import '../domain/meta_progress.dart';
import '../domain/permanent_skills.dart';

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
                const SizedBox(height: 12),
                const Text('No has completado la cuota.'),
                const SizedBox(height: 24),
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
                for (final skill in PermanentSkill.catalogue)
                  _SkillCard(session: session, skill: skill),
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('prestige-new-run'),
                  onPressed: session.prestigeReady ? session.beginNewRun : null,
                  child: const Text('Continuar'),
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

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.session, required this.skill});
  final GameSession session;
  final PermanentSkill skill;
  Future<void> _buy(BuildContext context) async {
    final run = session.meta.runId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Comprar ${skill.name}?'),
        content: Text(
          '${skill.price} estrellas. Compra permanente, sin devolución.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: ValueKey('permanent-confirm-${skill.id}'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true && session.meta.runId == run) {
      session.buyPermanent(skill.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final owned = session.meta.owns(skill.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              skill.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(skill.description),
            const SizedBox(height: 8),
            Text('${skill.price} ★'),
            const SizedBox(height: 8),
            FilledButton(
              key: ValueKey('permanent-buy-${skill.id}'),
              onPressed: session.canBuyPermanent(skill.id)
                  ? () => _buy(context)
                  : null,
              child: Text(
                owned
                    ? 'Adquirida'
                    : session.meta.stars < skill.price
                    ? 'Estrellas insuficientes'
                    : 'Comprar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
