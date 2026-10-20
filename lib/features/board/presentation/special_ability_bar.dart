import 'package:flutter/material.dart';
import '../../../app/game_session.dart';
import '../../day_cycle/domain/day_cycle.dart';
import '../domain/special_abilities.dart';

class SpecialAbilityBar extends StatelessWidget {
  const SpecialAbilityBar({super.key, required this.session});
  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final board = session.board;
    if (board == null) return const SizedBox.shrink();
    final abilities = SpecialAbility.values
        .where(board.specials.unlocked)
        .toList();
    if (abilities.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < abilities.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _button(abilities[i])),
          ],
        ],
      ),
    );
  }

  Widget _button(SpecialAbility ability) {
    final state = session.board!.specials;
    final boost = ability == SpecialAbility.boost;
    final active = boost && state.boostRemaining > 0;
    final production = session.phase == DayPhase.production;
    final ready = state.ready(ability);
    final usable =
        ready &&
        !session.paused &&
        production &&
        (boost || session.board!.balls.isNotEmpty);
    final title = boost ? 'Turbo' : 'Captura';
    final accessibleTitle = boost ? 'Acelerar generador' : 'Captura total';
    final status = !production
        ? 'Fin'
        : active
        ? '×${state.generationMultiplier.toInt()} · ${state.boostRemaining.ceil()}s'
        : ready
        ? 'Lista'
        : '${(state.cooldown(ability) - state.charge(ability)).ceil()} s';
    return Semantics(
      label: '$accessibleTitle, $status',
      button: true,
      enabled: usable,
      child: FilledButton(
        key: ValueKey('special-${ability.name}'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          backgroundColor: active ? const Color(0xff356d38) : null,
        ),
        onPressed: usable ? () => session.activateSpecial(ability) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5,
              children: [
                Icon(boost ? Icons.speed : Icons.blur_circular, size: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              key: ValueKey('special-charge-${ability.name}'),
              value: active
                  ? state.boostRemaining / state.settings['boost_duration']
                  : state.progress(ability),
              minHeight: 3,
            ),
          ],
        ),
      ),
    );
  }
}
