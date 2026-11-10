import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'save_store.dart';

Future<SaveStore> createStore() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  return FileSaveStore(directory.path);
}

class FileSaveStore implements SaveStore, PrestigeStore {
  FileSaveStore(this.directory);
  final String directory;
  @override
  Future<List<String>> loadPrestigeCandidates() async {
    final result = <String>[];
    for (final name in ['prestige.json', 'prestige.backup.json']) {
      final file = File('$directory/$name');
      if (await file.exists()) {
        result.add(utf8.decode(await file.readAsBytes(), allowMalformed: true));
      }
    }
    return result;
  }

  @override
  Future<void> savePrestige(String contents) async {
    // Both copies contain the NEW epoch, not a rollback to a previous run.
    for (final name in ['prestige', 'prestige.backup']) {
      final temp = File('$directory/$name.tmp');
      await temp.writeAsString(contents, flush: true);
      await temp.rename('$directory/$name.json');
    }
  }

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
