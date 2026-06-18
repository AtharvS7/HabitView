import '../../../domain/models/app_settings.dart';
import '../entities/settings_entity.dart';
import 'enum_mapping.dart';

/// Maps between [AppSettings] (domain) and [SettingsEntity] (Isar).
class SettingsMapper {
  const SettingsMapper._();

  static AppSettings toDomain(SettingsEntity e) {
    return AppSettings(
      themeMode: enumByName(AppThemeMode.values, e.themeMode, AppThemeMode.system),
      notificationsEnabled: e.notificationsEnabled,
      defaultReminderTime: e.defaultReminderTime,
      cloudBackupEnabled: e.cloudBackupEnabled,
      autoBackupOnChange: e.autoBackupOnChange,
      lastCloudBackupAt: e.lastCloudBackupAt,
      premiumUnlocked: e.premiumUnlocked,
      onboardingCompleted: e.onboardingCompleted,
    );
  }

  static SettingsEntity toEntity(AppSettings s, {SettingsEntity? existing}) {
    final e = existing ?? SettingsEntity();
    e.isarId = SettingsEntity.singletonId;
    e.themeMode = s.themeMode.name;
    e.notificationsEnabled = s.notificationsEnabled;
    e.defaultReminderTime = s.defaultReminderTime;
    e.cloudBackupEnabled = s.cloudBackupEnabled;
    e.autoBackupOnChange = s.autoBackupOnChange;
    e.lastCloudBackupAt = s.lastCloudBackupAt;
    e.premiumUnlocked = s.premiumUnlocked;
    e.onboardingCompleted = s.onboardingCompleted;
    return e;
  }
}
