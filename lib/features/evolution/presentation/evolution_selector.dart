import 'package:flutter/material.dart';
import '../../../app/game_session.dart';
import '../domain/evolution.dart';

class EvolutionSelector extends StatelessWidget {
  const EvolutionSelector({super.key, required this.session});
  final GameSession session;

  Widget _card(String id, int serial) {
    final skill = EvolutionSkill.find(id)!;
    final current = session.evolution.level(skill.kind);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('evolution-card-$id-$serial'),
          onTap: session.evolutionChoiceReady
              ? () => session.chooseEvolution(id, serial: serial)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(skill.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(skill.description),
                const SizedBox(height: 10),
                Text('Nivel $current → ${current + 1}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final run = session.evolution;
    return PopScope(
      canPop: false,
      child: Material(
        color: const Color(0xc9000000),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('¡ELIGE UNA MEJORA!', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 18),
                    for (final id in run.options) _card(id, run.serial),
                    if (!session.evolutionChoiceReady)
                      const Padding(padding: EdgeInsets.all(12), child: Text('Guardando…')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
