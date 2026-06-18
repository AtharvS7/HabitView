/// App-wide constants for HabitView's local-first architecture.
///
/// In the local-first design these "collection" names are the Isar collection
/// identifiers (and the optional cloud-backup document paths), not Firestore
/// collections used for primary reads/writes. They are kept centralised to
/// avoid stringly-typed drift between the data layer and the optional backup
/// serializer.
class AppConstants {
  AppConstants._();

  static const String appName = 'HabitView';

  // Logical collection names (Isar collections + optional backup paths).
  static const String habitsCollection = 'habits';
  static const String habitLogsCollection = 'habit_logs';
  static const String insightsCollection = 'insights';
  static const String userProgressCollection = 'user_progress';

  // Domain limits.
  static const int minDifficulty = 1;
  static const int maxDifficulty = 5;
  static const int minMood = 1;
  static const int maxMood = 5;
  static const int maxHabitNameLength = 80;
  static const int maxNotesLength = 500;

  // Consistency scoring.
  static const int defaultConsistencyWindowDays = 14;

  // Progressive disclosure thresholds.
  static const int insightsMinLogs = 10;
  static const int insightsMinDays = 8;

  // Premium / feature gating (free-tier limits). Counts are gentle so the free
  // tier is genuinely useful while leaving room for an upsell. Documented in
  // final_audit/feature_completion_report.md.
  static const int freeMaxActiveHabits = 10;
  static const int freeMaxCustomCategories = 0; // built-in categories only
  static const int freeAnalyticsWindowDays = 30;
  static const int premiumAnalyticsWindowDays = 365;

  // Local backup file.
  static const String backupFileExtension = 'habitview';
  static const int backupSchemaVersion = 1;

  // Notifications.
  static const String reminderChannelId = 'habit_reminders';
  static const String reminderChannelName = 'Habit reminders';
}
