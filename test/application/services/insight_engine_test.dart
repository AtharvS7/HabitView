import 'package:flutter_test/flutter_test.dart';
import 'package:habitview/application/services/insight_engine.dart';
import 'package:habitview/core/utils/date_utils.dart';
import 'package:habitview/domain/models/habit.dart';
import 'package:habitview/domain/models/habit_log.dart';

Habit _hardHabit() => const Habit(
      id: 'h1',
      userId: 'u1',
      name: 'Run 10k',
      category: HabitCategory.fitness,
      scheduleType: ScheduleType.daily,
      difficulty: 5,
      isActive: true,
    );

HabitLog _log(int daysAgo, LogStatus status, {SkipReason? reason}) {
  return HabitLog(
    id: 'l$daysAgo',
    habitId: 'h1',
    userId: 'u1',
    date: DateUtils.toDateKey(DateTime.now().subtract(Duration(days: daysAgo))),
    status: status,
    skipReason: reason,
  );
}

void main() {
  final engine = InsightEngine();

  group('InsightEngine', () {
    test('skips habits with fewer than 7 logs', () async {
      final insights = await engine.generateWeeklyInsights(
        userId: 'u1',
        habits: [_hardHabit()],
        habitLogs: {
          'h1': [for (var d = 1; d <= 5; d++) _log(d, LogStatus.done)],
        },
      );
      expect(insights, isEmpty);
    });

    test('flags a high-difficulty habit with low completion', () async {
      // 14 logs: 4 oldest done, 10 newest skipped (no skipReason) => ~29%.
      // Done-before-skip ordering keeps the recovery rule from firing.
      final logs = <HabitLog>[
        for (var d = 14; d >= 11; d--) _log(d, LogStatus.done),
        for (var d = 10; d >= 1; d--) _log(d, LogStatus.skipped),
      ];

      final insights = await engine.generateWeeklyInsights(
        userId: 'u1',
        habits: [_hardHabit()],
        habitLogs: {'h1': logs},
      );

      expect(insights.any((i) => i.type == 'difficulty_mismatch'), isTrue);
      final difficulty =
          insights.firstWhere((i) => i.type == 'difficulty_mismatch');
      expect(difficulty.confidence, inInclusiveRange(0.0, 1.0));
      expect(difficulty.actionable?.action, 'reduce_difficulty');
    });

    test('all confidences stay within 0..0.95', () async {
      final logs = <HabitLog>[
        for (var d = 14; d >= 1; d--)
          _log(d, LogStatus.skipped, reason: SkipReason.tooBusy),
      ];
      final insights = await engine.generateWeeklyInsights(
        userId: 'u1',
        habits: [_hardHabit()],
        habitLogs: {'h1': logs},
      );
      for (final i in insights) {
        expect(i.confidence, lessThanOrEqualTo(0.95));
        expect(i.confidence, greaterThanOrEqualTo(0.0));
        expect(i.title, isNot(contains('null')));
      }
    });

    test('returns at most three insights', () async {
      final logs = <HabitLog>[
        for (var d = 30; d >= 1; d--) _log(d, LogStatus.done),
      ];
      final insights = await engine.generateWeeklyInsights(
        userId: 'u1',
        habits: [_hardHabit()],
        habitLogs: {'h1': logs},
      );
      expect(insights.length, lessThanOrEqualTo(3));
    });
  });
}
