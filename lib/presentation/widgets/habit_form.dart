import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/habit.dart';
import 'category_visuals.dart';

/// Editable habit fields collected by the create/edit forms.
class HabitFormData {
  HabitFormData({
    required this.name,
    required this.category,
    required this.scheduleType,
    required this.daysOfWeek,
    required this.difficulty,
    required this.reminderTime,
    required this.trigger,
  });

  String name;
  HabitCategory category;
  ScheduleType scheduleType;
  Set<int> daysOfWeek; // 0=Sun..6=Sat
  int difficulty;
  String? reminderTime; // 'HH:mm'
  String? trigger;

  factory HabitFormData.initial() => HabitFormData(
        name: '',
        category: HabitCategory.productivity,
        scheduleType: ScheduleType.daily,
        daysOfWeek: {1, 2, 3, 4, 5},
        difficulty: 3,
        reminderTime: null,
        trigger: null,
      );

  factory HabitFormData.fromHabit(Habit habit) => HabitFormData(
        name: habit.name,
        category: habit.category,
        scheduleType: habit.scheduleType,
        daysOfWeek: {...?habit.daysOfWeek},
        difficulty: habit.difficulty,
        reminderTime: habit.timeWindowStart,
        trigger: habit.trigger,
      );
}

/// Shared form for creating and editing a habit. Owns its own controllers and
/// validation; the parent supplies the submit handler.
class HabitForm extends StatefulWidget {
  const HabitForm({
    super.key,
    required this.initial,
    required this.submitLabel,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  final HabitFormData initial;
  final String submitLabel;
  final void Function(HabitFormData data) onSubmit;
  final bool isSubmitting;

  @override
  State<HabitForm> createState() => _HabitFormState();
}

class _HabitFormState extends State<HabitForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _triggerController;
  late HabitFormData _data;

  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    _data = widget.initial;
    _nameController = TextEditingController(text: _data.name);
    _triggerController = TextEditingController(text: _data.trigger ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _triggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Habit name',
              hintText: 'e.g. Read for 20 minutes',
            ),
            maxLength: AppConstants.maxHabitNameLength,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Give your habit a name' : null,
          ),
          const SizedBox(height: 8),
          Text('Category', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in HabitCategory.values)
                ChoiceChip(
                  avatar: Icon(CategoryVisuals.icon(c), size: 18),
                  label: Text(CategoryVisuals.label(c)),
                  selected: _data.category == c,
                  onSelected: (_) => setState(() => _data.category = c),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Schedule', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<ScheduleType>(
            segments: const [
              ButtonSegment(
                value: ScheduleType.daily,
                label: Text('Every day'),
                icon: Icon(Icons.today_outlined),
              ),
              ButtonSegment(
                value: ScheduleType.specificDays,
                label: Text('Specific days'),
                icon: Icon(Icons.date_range_outlined),
              ),
            ],
            selected: {_data.scheduleType},
            onSelectionChanged: (s) =>
                setState(() => _data.scheduleType = s.first),
          ),
          if (_data.scheduleType == ScheduleType.specificDays) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var day = 0; day < 7; day++)
                  _DayToggle(
                    label: _dayLabels[day],
                    selected: _data.daysOfWeek.contains(day),
                    onTap: () => setState(() {
                      if (!_data.daysOfWeek.remove(day)) {
                        _data.daysOfWeek.add(day);
                      }
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Text('Difficulty', style: theme.textTheme.labelLarge),
          Text(
            'Harder habits count for more in your productivity score.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Slider(
            value: _data.difficulty.toDouble(),
            min: AppConstants.minDifficulty.toDouble(),
            max: AppConstants.maxDifficulty.toDouble(),
            divisions: AppConstants.maxDifficulty - AppConstants.minDifficulty,
            label: '${_data.difficulty}',
            onChanged: (v) => setState(() => _data.difficulty = v.round()),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.alarm_outlined),
            title: const Text('Reminder'),
            subtitle: Text(_data.reminderTime ?? 'No reminder'),
            trailing: _data.reminderTime == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _data.reminderTime = null),
                  ),
            onTap: _pickReminderTime,
          ),
          TextFormField(
            controller: _triggerController,
            decoration: const InputDecoration(
              labelText: 'Trigger (optional)',
              hintText: 'After my morning coffee…',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: widget.isSubmitting ? null : _submit,
            child: widget.isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _pickReminderTime() async {
    final now = TimeOfDay.now();
    final initial = _parseTime(_data.reminderTime) ?? now;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() => _data.reminderTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  TimeOfDay? _parseTime(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_data.scheduleType == ScheduleType.specificDays &&
        _data.daysOfWeek.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one day.')),
      );
      return;
    }
    _data.name = _nameController.text.trim();
    final trigger = _triggerController.text.trim();
    _data.trigger = trigger.isEmpty ? null : trigger;
    widget.onSubmit(_data);
  }
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        foregroundColor: selected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurfaceVariant,
        child: Text(label),
      ),
    );
  }
}
