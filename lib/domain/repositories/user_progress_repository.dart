import '../models/user_progress.dart';

/// Tracks the lightweight per-user counters that drive progressive disclosure.
abstract interface class UserProgressRepository {
  Future<UserProgress> getOrCreate(String userId);

  Stream<UserProgress> watch(String userId);

  Future<void> save(UserProgress progress);

  Future<void> recordHabitCreated(String userId);

  Future<void> recordLog(String userId);

  Future<void> completeOnboarding(String userId);
}
