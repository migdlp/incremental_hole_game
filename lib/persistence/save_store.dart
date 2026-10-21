abstract interface class SaveStore {
  Future<List<String>> loadCandidates();
  Future<void> save(String contents, {String? previous});
}

/// Independent durable checkpoint for irreversible prestige transitions.
/// Contains a complete terminal/new-run snapshot so a torn normal save recovers.
abstract interface class PrestigeStore {
  Future<List<String>> loadPrestigeCandidates();
  Future<void> savePrestige(String contents);
}
