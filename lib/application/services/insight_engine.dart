import '../../domain/models/habit.dart';
import '../../domain/models/habit_log.dart';
import '../../domain/models/insight.dart';

/// Generates rule-based behavioural insights from a user's habits and logs.
///
/// Each rule is a pure heuristic that returns at most one [Insight]. Rules only
/// fire above a confidence threshold, and the engine surfaces the top three by
/// confidence to avoid overwhelming the user.
class InsightEngine {
  Future<List<Insight>> generateWeeklyInsights({
    required String userId,
    required List<Habit> habits,
    required Map<String, List<HabitLog>> habitLogs,
  }) async {
    final allInsights = <Insight>[];

    for (final habit in habits) {
      final logs = habitLogs[habit.id] ?? [];
      if (logs.length < 7) continue; // Need a minimum amount of data.

      allInsights.addAll(_runInsightRules(habit, logs));
    }

    allInsights.sort((a, b) => b.confidence.compareTo(a.confidence));
    return allInsights.take(3).toList();
  }

  List<Insight> _runInsightRules(Habit habit, List<HabitLog> logs) {
    // Sort chronologically once so rules that depend on order (recovery,
    // "recent N") behave deterministically regardless of source ordering
    // (BUG-10).
    final sorted = [...logs]..sort((a, b) => a.date.compareTo(b.date));

    final candidates = <Insight?>[
      _checkTimePreference(habit, sorted),
      _checkDifficultyMismatch(habit, sorted),
      _analyzeSkipPattern(habit, sorted),
      _checkRecoveryStrength(habit, sorted),
    ];

    return candidates
        .whereType<Insight>()
        .where((i) => i.confidence >= 0.6)
        .toList();
  }

  Insight? _checkTimePreference(Habit habit, List<HabitLog> logs) {
    final logsWithTime = logs.where((l) => l.completedAt != null).toList();
    if (logsWithTime.length < 10) return null;

    final timeSlots = {'morning': 0.0, 'afternoon': 0.0, 'evening': 0.0};
    final counts = {'morning': 0, 'afternoon': 0, 'evening': 0};

    for (final log in logsWithTime) {
      final hour = log.completedAt!.hour;
      final slot = hour < 12
          ? 'morning'
          : hour < 17
              ? 'afternoon'
              : 'evening';

      counts[slot] = counts[slot]! + 1;
      if (log.status == LogStatus.done) {
        timeSlots[slot] = timeSlots[slot]! + 1;
      }
    }

    final rates = timeSlots
        .map((k, v) => MapEntry(k, counts[k]! > 0 ? v / counts[k]! : 0.0));

    final bestEntry = rates.entries.reduce((a, b) => b.value > a.value ? b : a);
    final avgRate = rates.values.reduce((a, b) => a + b) / 3;

    if (bestEntry.value < avgRate + 0.2) return null;

    final improvement = ((bestEntry.value - avgRate) * 100).round();

    return Insight(
      id: '${habit.id}_time_${DateTime.now().millisecondsSinceEpoch}',
      userId: habit.userId,
      habitId: habit.id,
      type: 'time_preference',
      title: 'You\'re $improvement% more consistent in the ${bestEntry.key}',
      description:
          'Consider scheduling "${habit.name}" during ${bestEntry.key} hours.',
      confidence:
          (0.6 + (logsWithTime.length / 30) * 0.3).clamp(0.0, 0.95).toDouble(),
      generatedAt: DateTime.now(),
    );
  }

  Insight? _checkDifficultyMismatch(Habit habit, List<HabitLog> logs) {
    if (habit.difficulty < 4) return null;

    // Most recent 14 logs (list is sorted ascending).
    final recentLogs =
        logs.length <= 14 ? logs : logs.sublist(logs.length - 14);
    if (recentLogs.length < 7) return null;

    final completionRate =
        recentLogs.where((l) => l.status == LogStatus.done).length /
            recentLogs.length;

    if (completionRate < 0.5) {
      return Insight(
        id: '${habit.id}_difficulty_${DateTime.now().millisecondsSinceEpoch}',
        userId: habit.userId,
        habitId: habit.id,
        type: 'difficulty_mismatch',
        title: 'This habit might be too ambitious',
        description:
            'With ${(completionRate * 100).round()}% completion, consider breaking "${habit.name}" into smaller steps.',
        confidence: 0.8,
        actionable: InsightAction(
          label: 'Reduce difficulty',
          action: 'reduce_difficulty',
          params: {'newDifficulty': (habit.difficulty - 2).clamp(1, 5)},
        ),
        generatedAt: DateTime.now(),
      );
    }

    return null;
  }

  Insight? _analyzeSkipPattern(Habit habit, List<HabitLog> logs) {
    final skippedLogs = logs
        .where((l) => l.status == LogStatus.skipped && l.skipReason != null)
        .toList();
    if (skippedLogs.length < 5) return null;

    final reasonCounts = <SkipReason, int>{};
    for (final log in skippedLogs) {
      reasonCounts[log.skipReason!] = (reasonCounts[log.skipReason] ?? 0) + 1;
    }

    final topEntry =
        reasonCounts.entries.reduce((a, b) => b.value > a.value ? b : a);
    final percentage = (topEntry.value / skippedLogs.length * 100).round();

    if (percentage < 40) return null;

    const reasonLabels = {
      SkipReason.tooBusy: 'lack of time',
      SkipReason.tooTired: 'low energy',
      SkipReason.forgot: 'forgetting',
      SkipReason.lowMotivation: 'low motivation',
      SkipReason.custom: 'other reasons', // BUG-07: avoid "due to null".
    };

    const suggestions = {
      SkipReason.tooBusy: 'Try reducing time commitment or moving to a less busy time.',
      SkipReason.tooTired: 'Consider scheduling earlier when energy is higher.',
      SkipReason.forgot: 'Set a reminder or attach to an existing routine.',
      SkipReason.lowMotivation: 'Reduce difficulty or pair with something enjoyable.',
      SkipReason.custom: 'Review your skip notes to spot what gets in the way.',
    };

    return Insight(
      id: '${habit.id}_skip_${DateTime.now().millisecondsSinceEpoch}',
      userId: habit.userId,
      habitId: habit.id,
      type: 'skip_pattern',
      title: '$percentage% of skips are due to ${reasonLabels[topEntry.key]}',
      description:
          suggestions[topEntry.key] ?? 'Consider what might make this easier.',
      // BUG-06: clamp so confidence never exceeds the documented 0..0.95 range.
      confidence: (0.7 + (percentage - 40) / 100).clamp(0.0, 0.95).toDouble(),
      generatedAt: DateTime.now(),
    );
  }

  Insight? _checkRecoveryStrength(Habit habit, List<HabitLog> logs) {
    if (logs.length < 10) return null;

    int recoveryCount = 0;
    int skipCount = 0;

    // logs is sorted ascending, so logs[i] immediately follows logs[i-1].
    for (int i = 1; i < logs.length; i++) {
      if (logs[i - 1].status == LogStatus.skipped) {
        skipCount++;
        if (logs[i].status == LogStatus.done) {
          recoveryCount++;
        }
      }
    }

    if (skipCount == 0) return null;

    final recoveryRate = recoveryCount / skipCount;
    if (recoveryRate < 0.75) return null;

    return Insight(
      id: '${habit.id}_recovery_${DateTime.now().millisecondsSinceEpoch}',
      userId: habit.userId,
      habitId: habit.id,
      type: 'recovery_strength',
      title: 'You bounce back well from missed days',
      description:
          'You complete this habit ${(recoveryRate * 100).round()}% of the time after skipping. One miss doesn\'t derail you.',
      confidence: 0.85,
      generatedAt: DateTime.now(),
    );
  }
}
