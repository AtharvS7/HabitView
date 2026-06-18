import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/analytics_providers.dart';
import '../../../application/providers/habit_log_providers.dart';
import '../../../application/providers/habit_providers.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_log.dart';
import '../../router/app_routes.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/category_visuals.dart';
import '../../widgets/metric_card.dart';

/// Read-only detail for a single habit: headline metrics, recent activity, and
/// edit / archive / delete actions.
class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitAsync = ref.watch(habitByIdProvider(habitId));

    return Scaffold(
      body: AsyncValueView<Habit?>(
        value: habitAsync,
        onRetry: () => ref.invalidate(habitByIdProvider(habitId)),
        data: (habit) {
          if (habit == null) {
            return const Scaffold(
              body: EmptyState(
                icon: Icons.search_off_outlined,
                title: 'Habit not found',
                message: 'This habit may have been deleted.',
              ),
            );
          }
          return _DetailBody(habit: habit);
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = CategoryVisuals.color(habit.category);
    final analytics = ref.watch(habitAnalyticsProvider(habit.id));
    final logsAsync = ref.watch(logsForHabitProvider(habit.id));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(habit.name),
          actions: [
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(AppRoutes.habitEdit(habit.id)),
            ),
            PopupMenuButton<String>(
              onSelected: (v) => _onMenu(context, ref, v),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'archive',
                  child: Text(habit.isActive ? 'Archive' : 'Restore'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        SliverList.list(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: accent.withValues(alpha: 0.15),
                  foregroundColor: accent,
                  child: Icon(CategoryVisuals.icon(habit.category)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(CategoryVisuals.label(habit.category),
                          style: theme.textTheme.labelLarge),
                      Text(
                        _scheduleLabel(habit),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (habit.trigger != null && habit.trigger!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Trigger: ${habit.trigger}',
                              style: theme.textTheme.bodySmall),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (analytics != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.6,
                children: [
                  MetricCard(
                    label: 'Consistency',
                    value: '${analytics.consistency.score}%',
                    caption: analytics.consistency.trendText,
                    icon: Icons.show_chart,
                  ),
                  MetricCard(
                    label: 'Current streak',
                    value: '${analytics.streak.current}',
                    caption: 'longest ${analytics.streak.longest}',
                    icon: Icons.local_fire_department_outlined,
                    accent: Colors.deepOrange,
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Recent activity', style: theme.textTheme.titleMedium),
          ),
        ]),
        ...logsAsync.when(
          loading: () => [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
          error: (e, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text('$e')),
              ),
            ),
          ],
          data: (logs) {
            if (logs.isEmpty) {
              return [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No activity logged yet.')),
                  ),
                ),
              ];
            }
            final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));
            final recent = sorted.take(30).toList();
            return [
              SliverList.builder(
                itemCount: recent.length,
                itemBuilder: (_, i) => _LogTile(log: recent[i]),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ];
          },
        ),
      ],
    );
  }

  String _scheduleLabel(Habit habit) {
    if (habit.scheduleType == ScheduleType.daily) return 'Every day';
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final days = (habit.daysOfWeek ?? const [])..sort();
    if (days.isEmpty) return 'Specific days';
    return days.map((d) => names[d]).join(', ');
  }

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final controller = ref.read(habitControllerProvider.notifier);
    if (action == 'archive') {
      if (habit.isActive) {
        await controller.archive(habit.id);
      } else {
        await controller.restore(habit.id);
      }
      if (context.mounted) context.pop();
      return;
    }
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete habit?'),
          content: Text(
            'This permanently deletes "${habit.name}" and its logs. '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await controller.delete(habit.id);
        if (context.mounted) context.pop();
      }
    }
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final HabitLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = log.status == LogStatus.done;
    return ListTile(
      dense: true,
      leading: Icon(
        done ? Icons.check_circle : Icons.fast_forward,
        color: done ? Colors.green : theme.colorScheme.error,
      ),
      title: Text(log.date),
      subtitle: done
          ? (log.notes != null ? Text(log.notes!) : null)
          : Text(_skipLabel(log)),
    );
  }

  String _skipLabel(HabitLog log) {
    final reason = switch (log.skipReason) {
      SkipReason.tooTired => 'Too tired',
      SkipReason.tooBusy => 'Too busy',
      SkipReason.forgot => 'Forgot',
      SkipReason.lowMotivation => 'Low motivation',
      SkipReason.custom => log.skipReasonCustom ?? 'Other',
      null => 'Skipped',
    };
    return 'Skipped — $reason';
  }
}
