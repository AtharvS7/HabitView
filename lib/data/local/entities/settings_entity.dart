import 'package:isar/isar.dart';

part 'settings_entity.g.dart';

/// Isar persistence model for app settings. There is a single row pinned to
/// [singletonId]; settings are device-local, not per-user.
@collection
class SettingsEntity {
  static const int singletonId = 0;

  Id isarId = singletonId;

  String themeMode = 'system'; // AppThemeMode.name
  bool notificationsEnabled = true;
  String defaultReminderTime = '09:00';
  bool cloudBackupEnabled = false;
  bool autoBackupOnChange = false;
  DateTime? lastCloudBackupAt;
  bool premiumUnlocked = false;
  bool onboardingCompleted = false;
}
