import '../../../domain/models/habit_log.dart';
import '../entities/habit_log_entity.dart';
import 'enum_mapping.dart';

/// Maps between [HabitLog] (domain) and [HabitLogEntity] (Isar).
class HabitLogMapper {
  const HabitLogMapper._();

  static HabitLog toDomain(HabitLogEntity e) {
    return HabitLog(
      id: e.uid,
      habitId: e.habitId,
      userId: e.userId,
      date: e.date,
      status: enumByName(LogStatus.values, e.status, LogStatus.done),
      skipReason: enumByNameOrNull(SkipReason.values, e.skipReason),
      skipReasonCustom: e.skipReasonCustom,
      mood: e.mood,
      notes: e.notes,
      loggedAt: e.loggedAt,
      completedAt: e.completedAt,
    );
  }

  static HabitLogEntity toEntity(HabitLog l, {HabitLogEntity? existing}) {
    final e = existing ?? HabitLogEntity();
    e.uid = l.id;
    e.habitId = l.habitId;
    e.userId = l.userId;
    e.date = l.date;
    e.status = l.status.name;
    e.skipReason = l.skipReason?.name;
    e.skipReasonCustom = l.skipReasonCustom;
    e.mood = l.mood;
    e.notes = l.notes;
    e.loggedAt = l.loggedAt;
    e.completedAt = l.completedAt;
    return e;
  }
}
