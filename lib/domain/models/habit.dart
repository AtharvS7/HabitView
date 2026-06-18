import 'package:freezed_annotation/freezed_annotation.dart';

part 'habit.freezed.dart';
part 'habit.g.dart';

@freezed
class Habit with _$Habit {
  const factory Habit({
    required String id,
    required String userId,
    required String name,
    required HabitCategory category,
    required ScheduleType scheduleType,
    List<int>? daysOfWeek, // 0=Sun, 1=Mon, ..., 6=Sat
    String? timeWindowStart, // 'HH:mm'
    String? timeWindowEnd, // 'HH:mm'
    required int difficulty, // 1-5
    String? trigger,
    required bool isActive,
    DateTime? createdAt,
    DateTime? pausedAt,
  }) = _Habit;

  factory Habit.fromJson(Map<String, dynamic> json) => _$HabitFromJson(json);
}

enum HabitCategory {
  productivity,
  fitness,
  mindfulness,
  learning,
  other,
}

enum ScheduleType {
  daily,
  specificDays,
}
