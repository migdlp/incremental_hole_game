import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'save_store.dart';

Future<SaveStore> createStore() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  return FileSaveStore(directory.path);
}

class FileSaveStore implements SaveStore {
  FileSaveStore(this.directory);
  final String directory;
  @override
  Future<List<String>> loadCandidates() async {
    final candidates = <String>[];
    for (final name in ['progress.json', 'progress.backup.json']) {
      final file = File('$directory/$name');
      if (await file.exists()) {
        candidates.add(
          utf8.decode(await file.readAsBytes(), allowMalformed: true),
        );
      }
    }
    return candidates;
  }

  @override
  Future<void> save(String contents, {String? previous}) async {
    if (previous != null) {
      final backup = File('$directory/progress.backup.tmp');
      await backup.writeAsString(previous, flush: true);
      await backup.rename('$directory/progress.backup.json');
    }
    final temporary = File('$directory/progress.tmp');
    await temporary.writeAsString(contents, flush: true);
    await temporary.rename('$directory/progress.json');
  }
}
