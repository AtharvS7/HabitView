import 'package:flutter_test/flutter_test.dart';
import 'package:habitview/application/services/streak_calculator.dart';
import 'package:habitview/core/utils/date_utils.dart';
import 'package:habitview/domain/models/habit.dart';
import 'package:habitview/domain/models/habit_log.dart';

Habit _dailyHabit({DateTime? createdAt}) => Habit(
  id: 'h1',
  userId: 'u1',
  name: 'Meditate',
  category: HabitCategory.mindfulness,
  scheduleType: ScheduleType.daily,
  difficulty: 2,
  isActive: true,
  createdAt: createdAt ?? DateTime.now(),
);

HabitLog _done(DateTime today, int daysAgo) => HabitLog(
  id: 'l$daysAgo',
  habitId: 'h1',
  userId: 'u1',
  date: DateUtils.toDateKey(today.subtract(Duration(days: daysAgo))),
  status: LogStatus.done,
);

void main() {
  final calc = StreakCalculator();
  // Fixed "today" so the tests are deterministic.
  final today = DateTime(2026, 6, 18);

  group('StreakCalculator', () {
    test('counts consecutive completed days as the current streak', () {
      final logs = [for (var d = 0; d < 5; d++) _done(today, d)];
      final result = calc.calculate(
        habit: _dailyHabit(createdAt: today.subtract(const Duration(days: 60))),
        logs: logs,
        today: today,
      );
      expect(result.current, 5);
      expect(result.longest, greaterThanOrEqualTo(5));
    });

    test('grants today grace: an unlogged today does not break the streak', () {
      // Completed the previous 4 days, but not today.
      final logs = [for (var d = 1; d <= 4; d++) _done(today, d)];
      final result = calc.calculate(
        habit: _dailyHabit(createdAt: today.subtract(const Duration(days: 60))),
        logs: logs,
        today: today,
      );
      expect(result.current, 4);
    });

    test('a gap before today breaks the current streak', () {
      // Done today and 1 day ago, then a gap at day 2, then older days.
      final logs = [
        _done(today, 0),
        _done(today, 1),
        _done(today, 3),
        _done(today, 4),
      ];
      final result = calc.calculate(
        habit: _dailyHabit(createdAt: today.subtract(const Duration(days: 60))),
        logs: logs,
        today: today,
      );
      expect(result.current, 2);
      expect(result.longest, greaterThanOrEqualTo(2));
    });

    test('no logs yields a zero streak', () {
      final result = calc.calculate(
        habit: _dailyHabit(createdAt: today.subtract(const Duration(days: 60))),
        logs: const [],
        today: today,
      );
      expect(result.current, 0);
      expect(result.longest, 0);
      expect(result.lastCompletedDate, isNull);
    });

    test('badge reflects the current streak length', () {
      final logs = [for (var d = 0; d < 8; d++) _done(today, d)];
      final result = calc.calculate(
        habit: _dailyHabit(createdAt: today.subtract(const Duration(days: 60))),
        logs: logs,
        today: today,
      );
      expect(result.badge, contains('🔥'));
    });
  });
}
