import '../../core/utils/date_utils.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/habit_log.dart';
import 'schedule_utils.dart';

/// Computes current and longest streaks for a habit over its scheduled days.
///
/// A "streak" counts consecutive *scheduled* occurrences that were completed.
/// For the current streak, today is given grace: if today is scheduled but not
/// yet logged, the streak is measured up to the most recent prior scheduled day
/// rather than being broken.
class StreakCalculator {
  StreakResult calculate({
    required Habit habit,
    required List<HabitLog> logs,
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    final todayKey = DateUtils.toDateKey(now);

    final completed = <String>{
      for (final l in logs)
        if (l.status == LogStatus.done) l.date,
    };

    final start = _startDay(habit, logs, now);

    // Longest streak across the whole history.
    int longest = 0;
    int running = 0;
    String? lastCompleted;
    for (var day = start;
        !day.isAfter(now);
        day = day.add(const Duration(days: 1))) {
      if (!isHabitScheduledOn(habit, day)) continue;
      final key = DateUtils.toDateKey(day);
      if (completed.contains(key)) {
        running++;
        lastCompleted = key;
        if (running > longest) longest = running;
      } else {
        running = 0;
      }
    }

    // Current streak: walk backwards from today over scheduled days.
    int current = 0;
    var cursor = now;
    var grantedTodayGrace = false;
    while (!cursor.isBefore(start)) {
      if (isHabitScheduledOn(habit, cursor)) {
        final key = DateUtils.toDateKey(cursor);
        if (completed.contains(key)) {
          current++;
        } else if (key == todayKey && !grantedTodayGrace) {
          // Today not logged yet — don't break the streak.
          grantedTodayGrace = true;
        } else {
          break;
        }
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return StreakResult(
      current: current,
      longest: longest,
      lastCompletedDate: lastCompleted,
    );
  }

  DateTime _startDay(Habit habit, List<HabitLog> logs, DateTime now) {
    DateTime? earliest = habit.createdAt;
    for (final l in logs) {
      final d = DateUtils.fromDateKey(l.date);
      if (earliest == null || d.isBefore(earliest)) earliest = d;
    }
    final fallback = now.subtract(const Duration(days: 365));
    final start = earliest ?? fallback;
    return start.isBefore(fallback) ? fallback : start;
  }
}

class StreakResult {
  const StreakResult({
    required this.current,
    required this.longest,
    this.lastCompletedDate,
  });

  final int current;
  final int longest;
  final String? lastCompletedDate;

  String get badge {
    if (current >= 30) return '🔥 $current-day streak';
    if (current >= 7) return '🔥 $current days';
    if (current > 0) return '$current-day streak';
    return 'No active streak';
  }
}
