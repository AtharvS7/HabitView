import 'package:flutter_test/flutter_test.dart';
import 'package:habitview/application/services/analytics_service.dart';
import 'package:habitview/core/utils/date_utils.dart';
import 'package:habitview/domain/models/habit.dart';
import 'package:habitview/domain/models/habit_log.dart';

Habit _habit(String id, {ScheduleType schedule = ScheduleType.daily, List<int>? days}) =>
    Habit(
      id: id,
      userId: 'u1',
      name: id,
      category: HabitCategory.productivity,
      scheduleType: schedule,
      daysOfWeek: days,
      difficulty: 3,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    );

HabitLog _done(String habitId, DateTime today, int daysAgo) => HabitLog(
      id: '$habitId-$daysAgo',
      habitId: habitId,
      userId: 'u1',
      date: DateUtils.toDateKey(today.subtract(Duration(days: daysAgo))),
      status: LogStatus.done,
    );

void main() {
  final service = AnalyticsService();
  final today = DateTime(2026, 6, 18); // a Thursday

  group('AnalyticsService', () {
    test('aggregates per-habit analytics and overall counters', () {
      final habits = [_habit('a'), _habit('b')];
      final logs = {
        'a': [for (var d = 0; d < 14; d++) _done('a', today, d)],
        'b': [for (var d = 0; d < 7; d++) _done('b', today, d)],
      };

      final stats = service.build(
        habits: habits,
        logsByHabit: logs,
        windowDays: 14,
        today: today,
      );

      expect(stats.activeHabits, 2);
      expect(stats.perHabit.length, 2);
      expect(stats.overallConsistency, inInclusiveRange(0, 100));
      // Both daily habits are scheduled today; both done today.
      expect(stats.scheduledToday, 2);
      expect(stats.completedToday, 2);
      expect(stats.todayCompletionRate, 1.0);
      expect(stats.topStreak, greaterThan(0));
    });

    test('per-habit list is sorted by consistency score descending', () {
      final habits = [_habit('weak'), _habit('strong')];
      final logs = {
        'weak': [_done('weak', today, 0)],
        'strong': [for (var d = 0; d < 14; d++) _done('strong', today, d)],
      };

      final stats = service.build(
        habits: habits,
        logsByHabit: logs,
        windowDays: 14,
        today: today,
      );

      expect(stats.perHabit.first.habit.id, 'strong');
      expect(stats.bestHabit?.habit.id, 'strong');
    });

    test('empty input produces a zeroed snapshot', () {
      final stats = service.build(
        habits: const [],
        logsByHabit: const {},
        today: today,
      );
      expect(stats.activeHabits, 0);
      expect(stats.overallConsistency, 0);
      expect(stats.topStreak, 0);
      expect(stats.todayCompletionRate, 0);
      expect(stats.bestHabit, isNull);
    });
  });
}
