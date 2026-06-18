import 'package:isar/isar.dart';

part 'user_progress_entity.g.dart';

/// Isar persistence model for per-user progressive-disclosure counters.
@collection
class UserProgressEntity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String userId;

  int schemaVersion = 1;
  DateTime? firstHabitCreatedAt;
  DateTime? firstLogAt;
  int totalLogsCount = 0;
  int habitsCreated = 0;
  bool onboardingCompleted = false;
}
