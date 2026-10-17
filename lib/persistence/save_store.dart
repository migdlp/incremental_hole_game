abstract interface class SaveStore {
  Future<List<String>> loadCandidates();
  Future<void> save(String contents, {String? previous});
}
