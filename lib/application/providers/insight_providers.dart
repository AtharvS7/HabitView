import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/app_exception.dart';
import '../../domain/models/habit_log.dart';
import '../../domain/models/insight.dart';
import 'app_providers.dart';
import 'auth_providers.dart';

/// Stored insights for the user, ordered by confidence.
final insightsProvider = StreamProvider<List<Insight>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(const <Insight>[]);
  return ref.watch(insightRepositoryProvider).watchInsights(uid);
});

final insightControllerProvider =
    AsyncNotifierProvider<InsightController, void>(InsightController.new);

class InsightController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Re-runs the [InsightEngine] over current data and persists the top results.
  Future<bool> regenerate() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      state = AsyncError(
        const AuthException('Sign in to generate insights.'),
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final habits = await ref.read(habitRepositoryProvider).getHabits(uid);
      final allLogs =
          await ref.read(habitLogRepositoryProvider).getLogsForUser(uid);

      final byHabit = <String, List<HabitLog>>{};
      for (final l in allLogs) {
        (byHabit[l.habitId] ??= []).add(l);
      }

      final insights = await ref.read(insightEngineProvider).generateWeeklyInsights(
            userId: uid,
            habits: habits,
            habitLogs: byHabit,
          );

      await ref.read(insightRepositoryProvider).replaceInsights(uid, insights);
    });
    return !state.hasError;
  }
}
