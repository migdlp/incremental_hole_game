import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/game_app.dart';
import 'app/game_session.dart';
import 'features/motion/android_motion_input.dart';
import 'features/upgrades/domain/catalog.dart';
import 'persistence/store_factory.dart';
import 'persistence/save_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const Bootstrap());
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  GameSession? session;
  String? error;
  bool canReset = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool fresh = false}) async {
    setState(() {
      error = null;
      canReset = false;
    });
    try {
      final catalog = UpgradeCatalog.fromCsv(
        await rootBundle.loadString('docs/balance.csv'),
      );
      final store = await createSaveStore();
      final motion = AndroidMotionInput();
      await motion.initialize();
      final next = GameSession(catalog, store, motion: motion);
      try {
        if (!fresh) {
          await next.load();
        } else {
          if (store is PrestigeStore &&
              (await (store as PrestigeStore).loadPrestigeCandidates())
                  .isNotEmpty) {
            throw const FormatException(
              'Hay datos permanentes de prestigio. No se ha creado un perfil vacío sobre ellos.',
            );
          }
          await next.save();
        }
      } on FormatException {
        next.dispose();
        canReset =
            store is! PrestigeStore ||
            (await (store as PrestigeStore).loadPrestigeCandidates()).isEmpty;
        rethrow;
      }
      if (!mounted) {
        next.dispose();
        return;
      }
      setState(() {
        session = next;
      });
    } on Object catch (failure) {
      if (mounted) {
        setState(() {
          error = failure is FormatException
              ? failure.message.toString()
              : 'No se pudo iniciar el juego o acceder al guardado local. Vuelve a intentarlo.';
        });
      }
    }
  }

  @override
  void dispose() {
    session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (session != null) return GardenApp(session: session!);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Builder(
        builder: (context) => Scaffold(
          backgroundColor: ink,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: error == null
                  ? const CircularProgressIndicator(color: gold)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No pudimos abrir Feed the Hole',
                          style: TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 16),
                        Text(error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Reintentar'),
                        ),
                        if (canReset)
                          TextButton(
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('¿Empezar de nuevo?'),
                                content: const Text(
                                  'Se sustituirá el progreso local que no se pudo recuperar.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      _load(fresh: true);
                                    },
                                    child: const Text('Crear nueva partida'),
                                  ),
                                ],
                              ),
                            ),
                            child: const Text('Crear nueva partida'),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
