import '../../core/utils/date_utils.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/habit_log.dart';
import 'schedule_utils.dart';

/// Computes a difficulty-weighted "productivity score": completing harder
/// habits contributes more than easy ones, so the score reflects effort rather
/// than raw counts.
class ProductivityCalculator {
  ProductivityResult calculate({
    required List<Habit> habits,
    required Map<String, List<HabitLog>> logsByHabit,
    int windowDays = 30,
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    final start = now.subtract(Duration(days: windowDays));

    double weightedAchieved = 0;
    double weightedExpected = 0;

    for (final habit in habits) {
      final logs = logsByHabit[habit.id] ?? const [];
      final completedKeys = <String>{
        for (final l in logs)
          if (l.status == LogStatus.done) l.date,
      };

      final weight = habit.difficulty.toDouble();
      for (var day = start;
          !day.isAfter(now);
          day = day.add(const Duration(days: 1))) {
        if (!isHabitScheduledOn(habit, day)) continue;
        weightedExpected += weight;
        if (completedKeys.contains(DateUtils.toDateKey(day))) {
          weightedAchieved += weight;
        }
      }
    }

    final score = weightedExpected > 0
        ? ((weightedAchieved / weightedExpected) * 100).round()
        : 0;

    return ProductivityResult(
      score: score,
      weightedAchieved: weightedAchieved,
      weightedExpected: weightedExpected,
      windowDays: windowDays,
    );
  }
}

class ProductivityResult {
  const ProductivityResult({
    required this.score,
    required this.weightedAchieved,
    required this.weightedExpected,
    required this.windowDays,
  });

  final int score;
  final double weightedAchieved;
  final double weightedExpected;
  final int windowDays;

  String get label {
    if (score >= 80) return 'Highly productive';
    if (score >= 60) return 'On track';
    if (score >= 40) return 'Finding rhythm';
    return 'Just getting started';
  }
}
