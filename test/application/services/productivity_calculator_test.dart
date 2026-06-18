import 'package:flutter_test/flutter_test.dart';
import 'package:habitview/application/services/productivity_calculator.dart';
import 'package:habitview/core/utils/date_utils.dart';
import 'package:habitview/domain/models/habit.dart';
import 'package:habitview/domain/models/habit_log.dart';

Habit _habit(String id, int difficulty) => Habit(
      id: id,
      userId: 'u1',
      name: id,
      category: HabitCategory.productivity,
      scheduleType: ScheduleType.daily,
      difficulty: difficulty,
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
  final calc = ProductivityCalculator();
  final today = DateTime(2026, 6, 18);

  group('ProductivityCalculator', () {
    test('full completion over the window scores 100', () {
      final habit = _habit('h1', 3);
      final logs = {
        'h1': [for (var d = 0; d <= 10; d++) _done('h1', today, d)],
      };
      final result = calc.calculate(
        habits: [habit],
        logsByHabit: logs,
        windowDays: 10,
        today: today,
      );
      expect(result.score, 100);
      expect(result.label, 'Highly productive');
    });

    test('no completions scores 0', () {
      final result = calc.calculate(
        habits: [_habit('h1', 3)],
        logsByHabit: const {},
        windowDays: 10,
        today: today,
      );
      expect(result.score, 0);
    });

    test('harder habits weigh more than easy ones', () {
      // Two habits over the same window: complete only the hard one.
      final hard = _habit('hard', 5);
      final easy = _habit('easy', 1);
      final logs = {
        'hard': [for (var d = 0; d <= 10; d++) _done('hard', today, d)],
      };
      final result = calc.calculate(
        habits: [hard, easy],
        logsByHabit: logs,
        windowDays: 10,
        today: today,
      );
      // Completing the difficulty-5 habit but not the difficulty-1 habit should
      // score well above a naive 50% count ratio.
      expect(result.score, greaterThan(50));
      expect(result.weightedExpected, greaterThan(result.weightedAchieved));
    });
  });
}
