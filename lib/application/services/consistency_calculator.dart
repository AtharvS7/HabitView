import '../../domain/models/habit.dart';
import '../../domain/models/habit_log.dart';

/// Computes a habit's consistency score over a rolling window.
///
/// The score blends a raw completion ratio (60%) with a recency-weighted
/// ratio (40%) so that recent behaviour matters more than older behaviour.
class ConsistencyCalculator {
  ConsistencyResult calculate({
    required Habit habit,
    required List<HabitLog> logs,
    int windowDays = 14,
  }) {
    final today = DateTime.now();
    final startDate = today.subtract(Duration(days: windowDays));

    // Inclusive lower bound so the window's first day is counted consistently
    // with _getExpectedDays (BUG-11).
    final recentLogs = logs.where((log) {
      final logDate = DateTime.parse(log.date);
      return !logDate.isBefore(startDate) &&
          logDate.isBefore(today.add(const Duration(days: 1)));
    }).toList();

    final expectedDays = _getExpectedDays(habit, startDate, today);
    final completedDays =
        recentLogs.where((l) => l.status == LogStatus.done).length;

    final rawScore =
        expectedDays > 0 ? (completedDays / expectedDays) * 100 : 0.0;
    final recentScore =
        _calculateRecentWeightedScore(recentLogs, today, windowDays);

    final finalScore = (rawScore * 0.6 + recentScore * 0.4).round();

    final (firstRate, secondRate) =
        _calculateHalfRates(logs, startDate, windowDays);
    final trend = _trendFromRates(firstRate, secondRate);

    return ConsistencyResult(
      score: finalScore,
      completedCount: completedDays,
      expectedCount: expectedDays,
      trendDirection: trend,
      weeklyDeltaPercent: (secondRate - firstRate).round(),
    );
  }

  int _getExpectedDays(Habit habit, DateTime start, DateTime end) {
    int count = 0;
    DateTime current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (habit.scheduleType == ScheduleType.daily) {
        count++;
      } else if (habit.scheduleType == ScheduleType.specificDays) {
        // daysOfWeek uses 0=Sun..6=Sat; Dart weekday is 1=Mon..7=Sun.
        if (habit.daysOfWeek?.contains(current.weekday % 7) ?? false) {
          count++;
        }
      }
      current = current.add(const Duration(days: 1));
    }

    return count;
  }

  double _calculateRecentWeightedScore(
    List<HabitLog> logs,
    DateTime today,
    int windowDays,
  ) {
    double weightedSum = 0;
    double weightSum = 0;

    for (final log in logs) {
      final logDate = DateTime.parse(log.date);
      final daysAgo = today.difference(logDate).inDays;
      final weight = (1 - (daysAgo / windowDays) * 0.7).clamp(0.3, 1.0);

      weightedSum += (log.status == LogStatus.done ? 1 : 0) * weight;
      weightSum += weight;
    }

    return weightSum > 0 ? (weightedSum / weightSum) * 100 : 0;
  }

  /// Returns `(firstHalfRate, secondHalfRate)` as completion percentages for the
  /// two halves of the window, used to derive both the trend direction and the
  /// real week-over-week delta (BUG-09).
  (double, double) _calculateHalfRates(
    List<HabitLog> logs,
    DateTime startDate,
    int windowDays,
  ) {
    final midpoint = startDate.add(Duration(days: windowDays ~/ 2));
    final end = startDate.add(Duration(days: windowDays));

    final firstHalf = logs.where((l) {
      final date = DateTime.parse(l.date);
      return !date.isBefore(startDate) && date.isBefore(midpoint);
    }).toList();

    final secondHalf = logs.where((l) {
      final date = DateTime.parse(l.date);
      return !date.isBefore(midpoint) && date.isBefore(end);
    }).toList();

    final firstRate = firstHalf.isEmpty
        ? 0.0
        : firstHalf.where((l) => l.status == LogStatus.done).length /
            firstHalf.length *
            100;
    final secondRate = secondHalf.isEmpty
        ? 0.0
        : secondHalf.where((l) => l.status == LogStatus.done).length /
            secondHalf.length *
            100;

    return (firstRate, secondRate);
  }

  TrendDirection _trendFromRates(double firstRate, double secondRate) {
    if (secondRate > firstRate + 15) return TrendDirection.improving;
    if (secondRate < firstRate - 15) return TrendDirection.declining;
    return TrendDirection.stable;
  }
}

class ConsistencyResult {
  final int score;
  final int completedCount;
  final int expectedCount;
  final TrendDirection trendDirection;

  /// Real second-half-minus-first-half completion delta (percentage points).
  /// Negative when declining.
  final int weeklyDeltaPercent;

  ConsistencyResult({
    required this.score,
    required this.completedCount,
    required this.expectedCount,
    required this.trendDirection,
    required this.weeklyDeltaPercent,
  });

  String get message {
    if (score >= 85) return "Excellent consistency! 🎯";
    if (score >= 70) return "Strong habit formation 💪";
    if (score >= 50) return "Building momentum 📈";
    if (score >= 30) return "Keep experimenting 🔄";
    return "Early days—be patient 🌱";
  }

  String get trendText {
    switch (trendDirection) {
      case TrendDirection.improving:
        return "+$weeklyDeltaPercent% from last week";
      case TrendDirection.declining:
        return "$weeklyDeltaPercent% from last week";
      case TrendDirection.stable:
        return "Steady progress";
    }
  }
}

enum TrendDirection {
  improving,
  stable,
  declining,
}
