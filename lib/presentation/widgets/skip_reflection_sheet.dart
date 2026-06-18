import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/habit_log.dart';

/// The result of the skip-reflection bottom sheet.
class SkipReflection {
  const SkipReflection({
    required this.reason,
    this.customReason,
    this.mood,
    this.notes,
  });

  final SkipReason reason;
  final String? customReason;
  final int? mood;
  final String? notes;
}

/// Prompts the user for *why* they're skipping — the reflection that powers
/// HabitView's skip-pattern insights. Returns null if dismissed.
Future<SkipReflection?> showSkipReflectionSheet(
  BuildContext context, {
  required String habitName,
}) {
  return showModalBottomSheet<SkipReflection>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SkipReflectionSheet(habitName: habitName),
  );
}

class _SkipReflectionSheet extends StatefulWidget {
  const _SkipReflectionSheet({required this.habitName});
  final String habitName;

  @override
  State<_SkipReflectionSheet> createState() => _SkipReflectionSheetState();
}

class _SkipReflectionSheetState extends State<_SkipReflectionSheet> {
  SkipReason _reason = SkipReason.tooBusy;
  final _customController = TextEditingController();
  final _notesController = TextEditingController();
  int? _mood;

  static const _labels = {
    SkipReason.tooBusy: 'Too busy',
    SkipReason.tooTired: 'Too tired',
    SkipReason.forgot: 'Forgot',
    SkipReason.lowMotivation: 'Low motivation',
    SkipReason.custom: 'Something else',
  };

  @override
  void dispose() {
    _customController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Why are you skipping?',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Logging the reason helps HabitView spot patterns for "${widget.habitName}".',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in _labels.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _reason == entry.key,
                    onSelected: (_) => setState(() => _reason = entry.key),
                  ),
              ],
            ),
            if (_reason == SkipReason.custom) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customController,
                decoration: const InputDecoration(labelText: 'Tell us more'),
                maxLength: 80,
              ),
            ],
            const SizedBox(height: 12),
            Text('How are you feeling? (optional)',
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var m = AppConstants.minMood; m <= AppConstants.maxMood; m++)
                  IconButton(
                    onPressed: () => setState(() => _mood = m),
                    icon: Icon(
                      _mood != null && m <= _mood!
                          ? Icons.sentiment_satisfied
                          : Icons.sentiment_satisfied_outlined,
                      color: _mood != null && m <= _mood!
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLength: AppConstants.maxNotesLength,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _submit,
              child: const Text('Save reflection'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    Navigator.of(context).pop(
      SkipReflection(
        reason: _reason,
        customReason:
            _reason == SkipReason.custom ? _customController.text.trim() : null,
        mood: _mood,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
  }
}
