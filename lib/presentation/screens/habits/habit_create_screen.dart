import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/habit_providers.dart';
import '../../../core/error/app_exception.dart';
import '../../../domain/models/habit.dart';
import '../../widgets/habit_form.dart';

/// Create a new habit. Premium limits are enforced in [HabitController.create];
/// a [PremiumRequiredException] surfaces here as a snackbar.
class HabitCreateScreen extends ConsumerStatefulWidget {
  const HabitCreateScreen({super.key});

  @override
  ConsumerState<HabitCreateScreen> createState() => _HabitCreateScreenState();
}

class _HabitCreateScreenState extends ConsumerState<HabitCreateScreen> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New habit')),
      body: HabitForm(
        initial: HabitFormData.initial(),
        submitLabel: 'Create habit',
        isSubmitting: _submitting,
        onSubmit: _create,
      ),
    );
  }

  Future<void> _create(HabitFormData data) async {
    setState(() => _submitting = true);
    final draft = Habit(
      id: '',
      userId: '',
      name: data.name,
      category: data.category,
      scheduleType: data.scheduleType,
      daysOfWeek: data.scheduleType == ScheduleType.specificDays
          ? (data.daysOfWeek.toList()..sort())
          : null,
      timeWindowStart: data.reminderTime,
      difficulty: data.difficulty,
      trigger: data.trigger,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final created = await ref.read(habitControllerProvider.notifier).create(draft);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (created != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Added "${created.name}"')));
      context.pop();
    } else {
      final error = ref.read(habitControllerProvider).error;
      final message = error is AppException
          ? error.message
          : 'Could not create the habit.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
