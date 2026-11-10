import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/game_session.dart';
import '../platform/export_balance.dart';

class BalanceExportPanel extends StatefulWidget {
  const BalanceExportPanel({super.key, required this.session});
  final GameSession session;
  @override
  State<BalanceExportPanel> createState() => _BalanceExportPanelState();
}

class _BalanceExportPanelState extends State<BalanceExportPanel> {
  bool busy = false;
  Future<void> export(String name) async {
    setState(() => busy = true);
    try {
      await shareBalanceFile(name, widget.session.balanceExportFiles[name]!);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo compartir. Puedes copiar el JSON.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Laboratorio de balance'),
      SelectableText(
        widget.session.balanceLab.summary,
        key: const ValueKey('balance-summary'),
      ),
      const Text(
        'Las jornadas normales conservan su etiqueta. Las pruebas DEBUG se indican por separado.',
      ),
      Wrap(
        spacing: 8,
        children: [
          for (final name in ['session.json', 'days.csv', 'summary.txt'])
            TextButton(
              onPressed: busy ? null : () => export(name),
              child: Text('Exportar $name'),
            ),
          TextButton(
            key: const ValueKey('balance-copy-json'),
            onPressed: busy
                ? null
                : () => Clipboard.setData(
                    ClipboardData(
                      text: widget.session.balanceExportFiles['session.json']!,
                    ),
                  ),
            child: const Text('Copiar JSON'),
          ),
        ],
      ),
      const SizedBox(height: 12),
    ],
  );
}
