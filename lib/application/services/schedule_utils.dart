import '../../domain/models/habit.dart';

/// Shared scheduling helper: whether a habit is "due" on a given calendar day.
///
/// `daysOfWeek` uses 0=Sun..6=Sat; Dart's `weekday` is 1=Mon..7=Sun, so we map
/// with `weekday % 7` (Sunday 7 -> 0). Kept in one place so the consistency,
/// streak and productivity calculators agree.
bool isHabitScheduledOn(Habit habit, DateTime day) {
  switch (habit.scheduleType) {
    case ScheduleType.daily:
      return true;
    case ScheduleType.specificDays:
      return habit.daysOfWeek?.contains(day.weekday % 7) ?? false;
  }
}
