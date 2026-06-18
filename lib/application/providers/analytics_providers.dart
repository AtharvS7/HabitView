import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/analytics_service.dart';
import 'app_providers.dart';
import 'habit_log_providers.dart';
import 'habit_providers.dart';
import 'premium_providers.dart';

/// Dashboard statistics, recomputed whenever habits or logs change. Returns
/// null until both underlying streams have produced their first value.
final dashboardStatsProvider = Provider<DashboardStats?>((ref) {
  final habits = ref.watch(habitsProvider).valueOrNull;
  final logsByHabit = ref.watch(logsByHabitProvider).valueOrNull;
  if (habits == null || logsByHabit == null) return null;

  final windowDays = ref.watch(premiumServiceProvider).analyticsWindowDays;
  return ref
      .watch(analyticsServiceProvider)
      .build(
        habits: habits,
        logsByHabit: logsByHabit,
        // Cap the consistency window; the productivity window uses the full
        // (possibly premium) range.
        windowDays: windowDays,
      );
});

/// Per-habit analytics keyed by habit id, for detail screens.
final habitAnalyticsProvider = Provider.family<HabitAnalytics?, String>((
  ref,
  habitId,
) {
  final stats = ref.watch(dashboardStatsProvider);
  if (stats == null) return null;
  for (final h in stats.perHabit) {
    if (h.habit.id == habitId) return h;
  }
  return null;
});
