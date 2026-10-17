enum SyncStatus {
  synced,
  pendingSync,
  pending,
  failed,
  offlineOnly;

  String toDbString() => name;
  static SyncStatus fromDbString(String? val) {
    return SyncStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => SyncStatus.synced,
    );
  }
}
