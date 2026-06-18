import '../models/habit.dart';

/// Local-first habit store. All reads/writes hit Isar; there are no network
/// calls on this path.
abstract interface class HabitRepository {
  /// Reactive list of a user's habits, ordered by creation time.
  Stream<List<Habit>> watchHabits(String userId, {bool includeArchived = false});

  Future<List<Habit>> getHabits(String userId, {bool includeArchived = false});

  Future<Habit?> getHabit(String id);

  /// Persists a new habit. If [habit.id] is empty, an id is generated.
  /// Returns the stored habit (with id + createdAt populated).
  Future<Habit> createHabit(Habit habit);

  Future<void> updateHabit(Habit habit);

  /// Archives (soft-deletes) a habit by clearing [Habit.isActive].
  Future<void> archiveHabit(String id);

  Future<void> restoreHabit(String id);

  /// Hard-deletes a habit and all its logs.
  Future<void> deleteHabit(String id);

  Future<int> activeHabitCount(String userId);
}
