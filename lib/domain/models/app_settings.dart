/// User-controllable app settings, persisted locally (Isar).
///
/// Local-first defaults: cloud backup/sync is OFF unless the user opts in.
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.notificationsEnabled = true,
    this.defaultReminderTime = '09:00',
    this.cloudBackupEnabled = false,
    this.autoBackupOnChange = false,
    this.lastCloudBackupAt,
    this.premiumUnlocked = false,
    this.onboardingCompleted = false,
  });

  final AppThemeMode themeMode;
  final bool notificationsEnabled;

  /// 'HH:mm' default reminder time used when creating a habit reminder.
  final String defaultReminderTime;

  /// Whether optional encrypted cloud backup/sync is enabled (default false).
  final bool cloudBackupEnabled;

  /// When true, local changes trigger a cloud backup (premium + opt-in).
  final bool autoBackupOnChange;

  final DateTime? lastCloudBackupAt;

  /// Local entitlement flag. A real payment integration would set this from a
  /// verified receipt; the architecture is intentionally provider-agnostic.
  final bool premiumUnlocked;

  final bool onboardingCompleted;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? notificationsEnabled,
    String? defaultReminderTime,
    bool? cloudBackupEnabled,
    bool? autoBackupOnChange,
    DateTime? lastCloudBackupAt,
    bool? premiumUnlocked,
    bool? onboardingCompleted,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultReminderTime: defaultReminderTime ?? this.defaultReminderTime,
      cloudBackupEnabled: cloudBackupEnabled ?? this.cloudBackupEnabled,
      autoBackupOnChange: autoBackupOnChange ?? this.autoBackupOnChange,
      lastCloudBackupAt: lastCloudBackupAt ?? this.lastCloudBackupAt,
      premiumUnlocked: premiumUnlocked ?? this.premiumUnlocked,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

enum AppThemeMode { system, light, dark }
