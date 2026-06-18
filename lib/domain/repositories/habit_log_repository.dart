import '../models/habit_log.dart';

/// Local-first log store. Logs are keyed by `(habitId, date)` where `date` is a
/// `'YYYY-MM-DD'` day key.
abstract interface class HabitLogRepository {
  Stream<List<HabitLog>> watchLogsForHabit(String habitId);

  /// Reactive view of every log for a user (drives analytics/insights).
  Stream<List<HabitLog>> watchLogsForUser(String userId);

  /// All logs for a user across every habit (used by analytics/insights).
  Future<List<HabitLog>> getLogsForUser(String userId);

  Future<List<HabitLog>> getLogsForHabit(String habitId);

  /// The log for a given habit on a given `'YYYY-MM-DD'` day, if it exists.
  Future<HabitLog?> getLogForDate(String habitId, String date);

  /// Reactive view of all logs for a user on a specific day.
  Stream<List<HabitLog>> watchLogsForDate(String userId, String date);

  /// Inserts or updates a log (one log per habit per day). Returns the stored
  /// log with id populated.
  Future<HabitLog> upsertLog(HabitLog log);

  Future<void> deleteLog(String id);

  /// Deletes every log belonging to a habit (used when hard-deleting a habit).
  Future<void> deleteLogsForHabit(String habitId);
}
