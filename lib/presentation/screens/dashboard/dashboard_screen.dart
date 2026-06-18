import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/analytics_providers.dart';
import '../../../application/providers/user_progress_provider.dart';
import '../../../application/services/analytics_service.dart';
import '../../../application/services/consistency_calculator.dart';
import '../../router/app_routes.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/category_visuals.dart';
import '../../widgets/metric_card.dart';

/// The "Stats" branch: aggregate metrics + a per-habit consistency breakdown.
/// Locked behind the basic-stats disclosure phase.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(statsUnlockedProvider);
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: !unlocked
          ? const EmptyState(
              icon: Icons.lock_clock_outlined,
              title: 'Stats unlock soon',
              message:
                  'Keep logging for a few days and your consistency, streaks '
                  'and productivity score will appear here.',
            )
          : stats == null
              ? const Center(child: CircularProgressIndicator())
              : _DashboardBody(stats: stats),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.5,
          children: [
            MetricCard(
              label: 'Consistency',
              value: '${stats.overallConsistency}%',
              caption: 'across all habits',
              icon: Icons.show_chart,
            ),
            MetricCard(
              label: 'Productivity',
              value: '${stats.productivity.score}',
              caption: stats.productivity.label,
              icon: Icons.bolt_outlined,
              accent: theme.colorScheme.tertiary,
            ),
            MetricCard(
              label: 'Top streak',
              value: '${stats.topStreak}',
              caption: 'days in a row',
              icon: Icons.local_fire_department_outlined,
              accent: Colors.deepOrange,
            ),
            MetricCard(
              label: 'Today',
              value: '${stats.completedToday}/${stats.scheduledToday}',
              caption: 'completed',
              icon: Icons.check_circle_outline,
              accent: theme.colorScheme.secondary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('Per habit', style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        for (final h in stats.perHabit)
          _HabitConsistencyTile(analytics: h),
      ],
    );
  }
}

class _HabitConsistencyTile extends StatelessWidget {
  const _HabitConsistencyTile({required this.analytics});

  final HabitAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = analytics.habit;
    final accent = CategoryVisuals.color(habit.category);
    final consistency = analytics.consistency;

    return Card(
      child: ListTile(
        onTap: () => context.push(AppRoutes.habitDetail(habit.id)),
        leading: CircleAvatar(
          backgroundColor: accent.withValues(alpha: 0.15),
          foregroundColor: accent,
          child: Icon(CategoryVisuals.icon(habit.category)),
        ),
        title: Text(habit.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            _TrendIcon(trend: consistency.trendDirection),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                consistency.trendText,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Text(
          '${consistency.score}%',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ),
    );
  }
}

class _TrendIcon extends StatelessWidget {
  const _TrendIcon({required this.trend});

  final TrendDirection trend;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (trend) {
      TrendDirection.improving => (Icons.trending_up, Colors.green),
      TrendDirection.declining => (Icons.trending_down, Colors.red),
      TrendDirection.stable => (Icons.trending_flat, Colors.grey),
    };
    return Icon(icon, size: 16, color: color);
  }
}
