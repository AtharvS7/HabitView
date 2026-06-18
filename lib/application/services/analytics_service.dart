import '../../core/utils/date_utils.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/habit_log.dart';
import 'consistency_calculator.dart';
import 'productivity_calculator.dart';
import 'schedule_utils.dart';
import 'streak_calculator.dart';

/// Aggregates the per-habit calculators into dashboard-ready statistics.
///
/// Pure: it takes habits + logs and returns a snapshot, so it is trivially
/// unit-testable and free of I/O.
class AnalyticsService {
  AnalyticsService({
    ConsistencyCalculator? consistency,
    StreakCalculator? streak,
    ProductivityCalculator? productivity,
  })  : _consistency = consistency ?? ConsistencyCalculator(),
        _streak = streak ?? StreakCalculator(),
        _productivity = productivity ?? ProductivityCalculator();

  final ConsistencyCalculator _consistency;
  final StreakCalculator _streak;
  final ProductivityCalculator _productivity;

  DashboardStats build({
    required List<Habit> habits,
    required Map<String, List<HabitLog>> logsByHabit,
    int windowDays = 30,
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    final todayKey = DateUtils.toDateKey(now);

    final perHabit = <HabitAnalytics>[];
    var scheduledToday = 0;
    var completedToday = 0;
    var consistencySum = 0;

    for (final habit in habits) {
      final logs = logsByHabit[habit.id] ?? const [];
      final consistency = _consistency.calculate(
        habit: habit,
        logs: logs,
        windowDays: windowDays.clamp(7, 60),
      );
      final streak = _streak.calculate(habit: habit, logs: logs, today: now);
      perHabit.add(HabitAnalytics(
        habit: habit,
        consistency: consistency,
        streak: streak,
      ));
      consistencySum += consistency.score;

      if (isHabitScheduledOn(habit, now)) {
        scheduledToday++;
        final isDone = logs.any(
          (l) => l.date == todayKey && l.status == LogStatus.done,
        );
        if (isDone) completedToday++;
      }
    }

    final productivity = _productivity.calculate(
      habits: habits,
      logsByHabit: logsByHabit,
      windowDays: windowDays,
      today: now,
    );

    perHabit.sort((a, b) => b.consistency.score.compareTo(a.consistency.score));

    return DashboardStats(
      activeHabits: habits.length,
      overallConsistency:
          habits.isEmpty ? 0 : (consistencySum / habits.length).round(),
      productivity: productivity,
      scheduledToday: scheduledToday,
      completedToday: completedToday,
      perHabit: perHabit,
      topStreak: perHabit.isEmpty
          ? 0
          : perHabit
              .map((h) => h.streak.current)
              .reduce((a, b) => a > b ? a : b),
    );
  }
}

class DashboardStats {
  const DashboardStats({
    required this.activeHabits,
    required this.overallConsistency,
    required this.productivity,
    required this.scheduledToday,
    required this.completedToday,
    required this.perHabit,
    required this.topStreak,
  });

  final int activeHabits;
  final int overallConsistency;
  final ProductivityResult productivity;
  final int scheduledToday;
  final int completedToday;
  final List<HabitAnalytics> perHabit;
  final int topStreak;

  double get todayCompletionRate =>
      scheduledToday == 0 ? 0 : completedToday / scheduledToday;

  HabitAnalytics? get bestHabit => perHabit.isEmpty ? null : perHabit.first;
}

class HabitAnalytics {
  const HabitAnalytics({
    required this.habit,
    required this.consistency,
    required this.streak,
  });

  final Habit habit;
  final ConsistencyResult consistency;
  final StreakResult streak;
}
