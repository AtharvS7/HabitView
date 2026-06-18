import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/habit_providers.dart';
import '../../../core/error/app_exception.dart';
import '../../../domain/models/habit.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/habit_form.dart';

/// Edit an existing habit. Loads the habit by id, then reuses [HabitForm].
class HabitEditScreen extends ConsumerStatefulWidget {
  const HabitEditScreen({super.key, required this.habitId});

  final String habitId;

  @override
  ConsumerState<HabitEditScreen> createState() => _HabitEditScreenState();
}

class _HabitEditScreenState extends ConsumerState<HabitEditScreen> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final habitAsync = ref.watch(habitByIdProvider(widget.habitId));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit habit')),
      body: AsyncValueView<Habit?>(
        value: habitAsync,
        onRetry: () => ref.invalidate(habitByIdProvider(widget.habitId)),
        data: (habit) {
          if (habit == null) {
            return const EmptyState(
              icon: Icons.search_off_outlined,
              title: 'Habit not found',
              message: 'This habit may have been deleted.',
            );
          }
          return HabitForm(
            initial: HabitFormData.fromHabit(habit),
            submitLabel: 'Save changes',
            isSubmitting: _submitting,
            onSubmit: (data) => _save(habit, data),
          );
        },
      ),
    );
  }

  Future<void> _save(Habit original, HabitFormData data) async {
    setState(() => _submitting = true);
    final updated = original.copyWith(
      name: data.name,
      category: data.category,
      scheduleType: data.scheduleType,
      daysOfWeek: data.scheduleType == ScheduleType.specificDays
          ? (data.daysOfWeek.toList()..sort())
          : null,
      timeWindowStart: data.reminderTime,
      difficulty: data.difficulty,
      trigger: data.trigger,
    );

    final ok = await ref
        .read(habitControllerProvider.notifier)
        .updateHabit(updated);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      ref.invalidate(habitByIdProvider(widget.habitId));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Habit updated')));
      context.pop();
    } else {
      final error = ref.read(habitControllerProvider).error;
      final message = error is AppException
          ? error.message
          : 'Could not save changes.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
