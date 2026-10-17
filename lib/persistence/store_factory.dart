import 'save_store.dart';
import 'store_native.dart' if (dart.library.html) 'store_web.dart' as platform;

Future<SaveStore> createSaveStore() => platform.createStore();
