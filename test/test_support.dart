import 'dart:io';
import 'package:incremental_hole_game/features/upgrades/domain/catalog.dart';
import 'package:incremental_hole_game/persistence/save_store.dart';

UpgradeCatalog testCatalog() =>
    UpgradeCatalog.fromCsv(File('docs/balance.csv').readAsStringSync());

class MemoryStore implements SaveStore, PrestigeStore {
  List<String> candidates = [];
  List<String> writes = [];
  bool fail = false;
  List<String> prestigeCandidates = [];
  @override
  Future<List<String>> loadPrestigeCandidates() async => prestigeCandidates;
  @override
  Future<void> savePrestige(String contents) async {
    if (fail) throw const FileSystemException('Disk unavailable');
    prestigeCandidates = [contents, contents];
  }

  @override
  Future<List<String>> loadCandidates() async => candidates;
  @override
  Future<void> save(String contents, {String? previous}) async {
    if (fail) throw const FileSystemException('Disk unavailable');
    writes.add(contents);
    candidates = [contents, if (previous != null) previous];
  }
}
