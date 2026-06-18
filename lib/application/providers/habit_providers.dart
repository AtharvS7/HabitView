import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/app_exception.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/habit.dart';
import 'app_providers.dart';
import 'auth_providers.dart';
import 'premium_providers.dart';
import 'settings_providers.dart';

/// Active habits for the signed-in user.
final habitsProvider = StreamProvider<List<Habit>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(const <Habit>[]);
  return ref.watch(habitRepositoryProvider).watchHabits(uid);
});

/// Archived habits only (for the "Archived" view).
final archivedHabitsProvider = StreamProvider<List<Habit>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(const <Habit>[]);
  return ref
      .watch(habitRepositoryProvider)
      .watchHabits(uid, includeArchived: true)
      .map((all) => all.where((h) => !h.isActive).toList());
});

final habitByIdProvider = FutureProvider.family<Habit?, String>(
  (ref, id) => ref.watch(habitRepositoryProvider).getHabit(id),
);

final habitControllerProvider = AsyncNotifierProvider<HabitController, void>(
  HabitController.new,
);

class HabitController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<Habit?> create(Habit draft) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final uid = _requireUid();
      final repo = ref.read(habitRepositoryProvider);
      final premium = ref.read(premiumServiceProvider);

      final activeCount = await repo.activeHabitCount(uid);
      if (!premium.canCreateHabit(activeCount)) {
        throw const PremiumRequiredException(
          'Free accounts can track up to 10 habits. Upgrade for unlimited.',
        );
      }

      final created = await repo.createHabit(draft.copyWith(userId: uid));
      await ref.read(userProgressRepositoryProvider).recordHabitCreated(uid);
      await _maybeScheduleReminder(created);
      return created;
    });
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return result.valueOrNull;
  }

  Future<bool> updateHabit(Habit habit) => _run(() async {
    await ref.read(habitRepositoryProvider).updateHabit(habit);
    await _maybeScheduleReminder(habit);
  });

  Future<bool> archive(String id) => _run(() async {
    await ref.read(habitRepositoryProvider).archiveHabit(id);
    await ref.read(notificationServiceProvider).cancelReminder(id);
  });

  Future<bool> restore(String id) =>
      _run(() => ref.read(habitRepositoryProvider).restoreHabit(id));

  Future<bool> delete(String id) => _run(() async {
    await ref.read(habitRepositoryProvider).deleteHabit(id);
    await ref.read(notificationServiceProvider).cancelReminder(id);
  });

  Future<void> _maybeScheduleReminder(Habit habit) async {
    final settings = ref.read(currentSettingsProvider);
    final notifications = ref.read(notificationServiceProvider);
    if (!settings.notificationsEnabled || !habit.isActive) {
      await notifications.cancelReminder(habit.id);
      return;
    }
    final time = habit.timeWindowStart ?? settings.defaultReminderTime;
    await notifications.scheduleDailyReminder(
      habitId: habit.id,
      habitName: habit.name,
      time: time,
    );
  }

  String _requireUid() {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      throw const AuthException('You need to be signed in to do that.');
    }
    return uid;
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}

/// Convenience: a habit's reminder uses [AppSettings.defaultReminderTime] unless
/// it sets its own [Habit.timeWindowStart]. Re-exported for screens.
String defaultReminderFor(Habit habit, AppSettings settings) =>
    habit.timeWindowStart ?? settings.defaultReminderTime;
