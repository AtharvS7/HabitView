import 'package:flutter_test/flutter_test.dart';
import 'package:habitview/application/services/consistency_calculator.dart';
import 'package:habitview/core/utils/date_utils.dart';
import 'package:habitview/domain/models/habit.dart';
import 'package:habitview/domain/models/habit_log.dart';

Habit _dailyHabit() => const Habit(
      id: 'h1',
      userId: 'u1',
      name: 'Read',
      category: HabitCategory.learning,
      scheduleType: ScheduleType.daily,
      difficulty: 2,
      isActive: true,
    );

HabitLog _log(int daysAgo, LogStatus status) {
  final date = DateUtils.toDateKey(
    DateTime.now().subtract(Duration(days: daysAgo)),
  );
  return HabitLog(
    id: 'l$daysAgo',
    habitId: 'h1',
    userId: 'u1',
    date: date,
    status: status,
  );
}

void main() {
  final calc = ConsistencyCalculator();

  group('ConsistencyCalculator', () {
    test('a 15-day daily window expects 15 days', () {
      final result = calc.calculate(habit: _dailyHabit(), logs: const []);
      expect(result.expectedCount, 15);
      expect(result.completedCount, 0);
      expect(result.score, 0);
    });

    test('counts only completed logs inside the window', () {
      // 10 consecutive recent days, all completed.
      final logs = [for (var d = 0; d < 10; d++) _log(d, LogStatus.done)];
      final result = calc.calculate(habit: _dailyHabit(), logs: logs);

      expect(result.completedCount, 10);
      expect(result.score, greaterThan(0));
      expect(result.score, lessThanOrEqualTo(100));
    });

    test('a perfect record reports stable trend and steady progress', () {
      // Days 1..12 ago, all done (avoids the exact window boundary days).
      final logs = [for (var d = 1; d <= 12; d++) _log(d, LogStatus.done)];
      final result = calc.calculate(habit: _dailyHabit(), logs: logs);

      expect(result.trendDirection, TrendDirection.stable);
      expect(result.trendText, 'Steady progress');
      expect(result.weeklyDeltaPercent, 0);
    });

    test('never divides by zero when nothing is expected/logged', () {
      final result = calc.calculate(
        habit: _dailyHabit(),
        logs: const [],
        windowDays: 0,
      );
      expect(result.score.isNaN, isFalse);
      expect(result.trendText, isNotEmpty);
    });

    test('message reflects the score band', () {
      final logs = [for (var d = 1; d <= 12; d++) _log(d, LogStatus.done)];
      final result = calc.calculate(habit: _dailyHabit(), logs: logs);
      expect(result.message, contains('consistency'));
    });
  });
}
