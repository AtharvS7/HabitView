import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/app_exception.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/habit_log.dart';
import 'app_providers.dart';
import 'auth_providers.dart';

/// Today's logs for the signed-in user, keyed by `habitId` in the UI layer.
final todayLogsProvider = StreamProvider<List<HabitLog>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(const <HabitLog>[]);
  return ref
      .watch(habitLogRepositoryProvider)
      .watchLogsForDate(uid, DateUtils.todayKey());
});

/// Map of today's logs by habit id, for O(1) lookups in the Today screen.
final todayLogsByHabitProvider = Provider<Map<String, HabitLog>>((ref) {
  final logs = ref.watch(todayLogsProvider).valueOrNull ?? const [];
  return {for (final l in logs) l.habitId: l};
});

final logsForHabitProvider =
    StreamProvider.family<List<HabitLog>, String>((ref, habitId) {
  return ref.watch(habitLogRepositoryProvider).watchLogsForHabit(habitId);
});

/// All logs for the user, grouped by habit id (drives analytics + insights).
final logsByHabitProvider = StreamProvider<Map<String, List<HabitLog>>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(const {});
  return ref.watch(habitLogRepositoryProvider).watchLogsForUser(uid).map((logs) {
    final grouped = <String, List<HabitLog>>{};
    for (final l in logs) {
      (grouped[l.habitId] ??= []).add(l);
    }
    return grouped;
  });
});

final logControllerProvider =
    AsyncNotifierProvider<LogController, void>(LogController.new);

class LogController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Marks [habit] done for [date] (defaults to today).
  Future<bool> markDone(
    Habit habit, {
    String? date,
    int? mood,
    String? notes,
  }) {
    final key = date ?? DateUtils.todayKey();
    return _upsert(HabitLog(
      id: '',
      habitId: habit.id,
      userId: habit.userId,
      date: key,
      status: LogStatus.done,
      mood: mood,
      notes: notes,
      loggedAt: DateTime.now(),
      completedAt: DateTime.now(),
    ));
  }

  /// Marks [habit] skipped, capturing the reflection (reason + optional note).
  Future<bool> markSkipped(
    Habit habit, {
    required SkipReason reason,
    String? customReason,
    String? date,
    int? mood,
    String? notes,
  }) {
    final key = date ?? DateUtils.todayKey();
    return _upsert(HabitLog(
      id: '',
      habitId: habit.id,
      userId: habit.userId,
      date: key,
      status: LogStatus.skipped,
      skipReason: reason,
      skipReasonCustom: reason == SkipReason.custom ? customReason : null,
      mood: mood,
      notes: notes,
      loggedAt: DateTime.now(),
    ));
  }

  Future<bool> deleteLog(String logId) =>
      _run(() => ref.read(habitLogRepositoryProvider).deleteLog(logId));

  Future<bool> _upsert(HabitLog log) => _run(() async {
        await ref.read(habitLogRepositoryProvider).upsertLog(log);
        await ref.read(userProgressRepositoryProvider).recordLog(log.userId);
      });

  Future<bool> _run(Future<void> Function() action) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      state = AsyncError(
        const AuthException('You need to be signed in to log a habit.'),
        StackTrace.current,
      );
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}
