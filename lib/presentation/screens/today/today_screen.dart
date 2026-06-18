import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/habit_log_providers.dart';
import '../../../application/providers/habit_providers.dart';
import '../../../application/services/schedule_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_log.dart';
import '../../router/app_routes.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/habit_card.dart';
import '../../widgets/skip_reflection_sheet.dart';

/// The home surface: today's scheduled habits with one-tap done/skip.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final logsByHabit = ref.watch(todayLogsByHabitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        centerTitle: false,
      ),
      body: AsyncValueView<List<Habit>>(
        value: habitsAsync,
        onRetry: () => ref.invalidate(habitsProvider),
        data: (habits) {
          final today = DateTime.now();
          final scheduled =
              habits.where((h) => isHabitScheduledOn(h, today)).toList();

          if (habits.isEmpty) {
            return EmptyState(
              icon: Icons.spa_outlined,
              title: 'Start your first habit',
              message:
                  'Add a habit and HabitView will track it — and start spotting '
                  'patterns as you go.',
              action: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.habitCreate),
                icon: const Icon(Icons.add),
                label: const Text('New habit'),
              ),
            );
          }

          if (scheduled.isEmpty) {
            return const EmptyState(
              icon: Icons.beach_access_outlined,
              title: 'Nothing scheduled today',
              message: 'Enjoy the breather — your habits resume on their next '
                  'scheduled day.',
            );
          }

          final doneCount = scheduled
              .where((h) => logsByHabit[h.id]?.status == LogStatus.done)
              .length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            children: [
              _ProgressHeader(done: doneCount, total: scheduled.length),
              const SizedBox(height: 8),
              for (final habit in scheduled)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: HabitCard(
                    habit: habit,
                    todayLog: logsByHabit[habit.id],
                    onToggleDone: () => _toggleDone(
                      ref,
                      habit,
                      logsByHabit[habit.id],
                    ),
                    onSkip: () => _skip(context, ref, habit),
                    onTap: () =>
                        context.push(AppRoutes.habitDetail(habit.id)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleDone(
    WidgetRef ref,
    Habit habit,
    HabitLog? current,
  ) async {
    final controller = ref.read(logControllerProvider.notifier);
    if (current?.status == LogStatus.done) {
      await controller.deleteLog(current!.id);
    } else {
      await controller.markDone(habit);
    }
  }

  Future<void> _skip(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
  ) async {
    final reflection =
        await showSkipReflectionSheet(context, habitName: habit.name);
    if (reflection == null) return;
    await ref.read(logControllerProvider.notifier).markSkipped(
          habit,
          reason: reflection.reason,
          customReason: reflection.customReason,
          mood: reflection.mood,
          notes: reflection.notes,
        );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total == 0 ? 0.0 : done / total;
    final allDone = done == total && total > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              allDone ? 'All done for today 🎉' : _greeting(),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '$done of $total complete',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}
