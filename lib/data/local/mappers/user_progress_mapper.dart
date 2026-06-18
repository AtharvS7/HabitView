import '../../../domain/models/user_progress.dart';
import '../entities/user_progress_entity.dart';

/// Maps between [UserProgress] (domain) and [UserProgressEntity] (Isar).
class UserProgressMapper {
  const UserProgressMapper._();

  static UserProgress toDomain(UserProgressEntity e) {
    return UserProgress(
      userId: e.userId,
      schemaVersion: e.schemaVersion,
      firstHabitCreatedAt: e.firstHabitCreatedAt,
      firstLogAt: e.firstLogAt,
      totalLogsCount: e.totalLogsCount,
      habitsCreated: e.habitsCreated,
      onboardingCompleted: e.onboardingCompleted,
    );
  }

  static UserProgressEntity toEntity(
    UserProgress p, {
    UserProgressEntity? existing,
  }) {
    final e = existing ?? UserProgressEntity();
    e.userId = p.userId;
    e.schemaVersion = p.schemaVersion;
    e.firstHabitCreatedAt = p.firstHabitCreatedAt;
    e.firstLogAt = p.firstLogAt;
    e.totalLogsCount = p.totalLogsCount;
    e.habitsCreated = p.habitsCreated;
    e.onboardingCompleted = p.onboardingCompleted;
    return e;
  }
}
