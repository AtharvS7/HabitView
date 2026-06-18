import '../../../domain/models/habit.dart';
import '../entities/habit_entity.dart';
import 'enum_mapping.dart';

/// Maps between [Habit] (domain) and [HabitEntity] (Isar).
class HabitMapper {
  const HabitMapper._();

  static Habit toDomain(HabitEntity e) {
    return Habit(
      id: e.uid,
      userId: e.userId,
      name: e.name,
      category: enumByName(HabitCategory.values, e.category, HabitCategory.other),
      scheduleType:
          enumByName(ScheduleType.values, e.scheduleType, ScheduleType.daily),
      daysOfWeek: e.daysOfWeek.isEmpty ? null : List<int>.from(e.daysOfWeek),
      timeWindowStart: e.timeWindowStart,
      timeWindowEnd: e.timeWindowEnd,
      difficulty: e.difficulty,
      trigger: e.trigger,
      isActive: e.isActive,
      createdAt: e.createdAt,
      pausedAt: e.pausedAt,
    );
  }

  static HabitEntity toEntity(Habit h, {HabitEntity? existing}) {
    final e = existing ?? HabitEntity();
    e.uid = h.id;
    e.userId = h.userId;
    e.name = h.name;
    e.category = h.category.name;
    e.scheduleType = h.scheduleType.name;
    e.daysOfWeek = h.daysOfWeek == null ? const [] : List<int>.from(h.daysOfWeek!);
    e.timeWindowStart = h.timeWindowStart;
    e.timeWindowEnd = h.timeWindowEnd;
    e.difficulty = h.difficulty;
    e.trigger = h.trigger;
    e.isActive = h.isActive;
    e.createdAt = h.createdAt;
    e.pausedAt = h.pausedAt;
    return e;
  }
}
