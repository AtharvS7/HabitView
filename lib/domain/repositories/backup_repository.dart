/// Backup/restore boundary.
///
/// Local export/import is always available and fully offline. Cloud backup is
/// optional, opt-in, and (when enabled) writes a single encrypted snapshot
/// document per user — never per-habit documents — to keep Firebase costs near
/// zero.
abstract interface class BackupRepository {
  /// Serializes all of a user's local data to a JSON string.
  Future<String> exportToJson(String userId);

  /// Writes a `.habitview` backup file to a temp location and returns its path.
  Future<String> exportToFile(String userId);

  /// Imports data from a JSON string. When [merge] is false, existing local
  /// data for the user is replaced; when true, records are upserted.
  Future<BackupImportResult> importFromJson(
    String userId,
    String json, {
    bool merge = true,
  });

  /// Uploads an (optionally encrypted) snapshot to the cloud. No-op-friendly:
  /// throws [BackupException] if cloud backup is disabled or unconfigured.
  Future<void> backupToCloud(String userId, {String? passphrase});

  /// Restores the latest cloud snapshot into local storage.
  Future<BackupImportResult> restoreFromCloud(
    String userId, {
    String? passphrase,
    bool merge = false,
  });

  Future<DateTime?> lastCloudBackupAt(String userId);
}

/// Summary of an import/restore operation.
class BackupImportResult {
  const BackupImportResult({
    required this.habits,
    required this.logs,
    required this.insights,
  });

  final int habits;
  final int logs;
  final int insights;

  int get total => habits + logs + insights;
}
