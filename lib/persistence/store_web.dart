import 'package:shared_preferences/shared_preferences.dart';
import 'save_store.dart';

Future<SaveStore> createStore() async =>
    WebSaveStore(await SharedPreferences.getInstance());

class WebSaveStore implements SaveStore {
  WebSaveStore(this.preferences);
  final SharedPreferences preferences;
  @override
  Future<List<String>> loadCandidates() async => [
    if (preferences.getString('progress') case final String data) data,
    if (preferences.getString('progress.backup') case final String data) data,
  ];
  @override
  Future<void> save(String contents, {String? previous}) async {
    if (previous != null &&
        !await preferences.setString('progress.backup', previous)) {
      throw StateError('No se pudo escribir la copia de seguridad');
    }
    if (!await preferences.setString('progress', contents)) {
      throw StateError('No se pudo guardar la partida');
    }
  }
}
