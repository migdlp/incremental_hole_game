import 'package:flutter/material.dart';
import '../domain/capture_combo.dart';

class StreakIndicator extends StatelessWidget {
  const StreakIndicator({
    super.key,
    required this.combo,
    required this.closing,
  });
  final CaptureCombo combo;
  final bool closing;

  @override
  Widget build(BuildContext context) {
    if (!combo.enabled) return const SizedBox.shrink();
    final active = !closing && combo.streak > 0;
    final color = combo.multiplier == 3
        ? const Color(0xffc084fc)
        : const Color(0xff4ade80);
    return Semantics(
      label: active
          ? 'Racha de ${combo.streak} capturas, multiplicador ${combo.multiplier}'
          : closing
          ? 'Racha terminada'
          : 'Racha desbloqueada, encadena capturas',
      child: ExcludeSemantics(
        child: Container(
          key: const ValueKey('streak-indicator'),
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: active ? .14 : .05),
            border: Border.all(
              color: color.withValues(alpha: active ? .8 : .25),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.local_fire_department, size: 20, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      active
                          ? 'RACHA · ${combo.streak}'
                          : closing
                          ? 'Racha terminada'
                          : 'Racha lista',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (active)
                    Text(
                      '×${combo.multiplier}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              if (active) ...[
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  key: const ValueKey('streak-window'),
                  value: (combo.remaining / CaptureCombo.window).clamp(
                    0.0,
                    1.0,
                  ),
                  color: color,
                  backgroundColor: const Color(0xff23334b),
                  minHeight: 4,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
