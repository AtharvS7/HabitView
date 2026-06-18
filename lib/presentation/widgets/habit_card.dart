import 'package:flutter/material.dart';

import '../../domain/models/habit.dart';
import '../../domain/models/habit_log.dart';
import 'category_visuals.dart';

/// A habit row on the Today screen with quick "done" / "skip" affordances.
class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.todayLog,
    required this.onToggleDone,
    required this.onSkip,
    required this.onTap,
  });

  final Habit habit;
  final HabitLog? todayLog;
  final VoidCallback onToggleDone;
  final VoidCallback onSkip;
  final VoidCallback onTap;

  bool get _isDone => todayLog?.status == LogStatus.done;
  bool get _isSkipped => todayLog?.status == LogStatus.skipped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = CategoryVisuals.color(habit.category);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.15),
                foregroundColor: accent,
                child: Icon(CategoryVisuals.icon(habit.category)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration:
                            _isDone ? TextDecoration.lineThrough : null,
                        color: _isDone
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusLabel(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _isSkipped
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _isDone ? 'Mark not done' : 'Mark done',
                onPressed: onToggleDone,
                icon: Icon(
                  _isDone
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: _isDone ? accent : theme.colorScheme.outline,
                  size: 30,
                ),
              ),
              if (!_isDone)
                IconButton(
                  tooltip: 'Skip with a reason',
                  onPressed: onSkip,
                  icon: Icon(
                    Icons.fast_forward_outlined,
                    color: theme.colorScheme.outline,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel() {
    if (_isDone) return 'Completed today';
    if (_isSkipped) return 'Skipped today';
    return CategoryVisuals.label(habit.category);
  }
}
