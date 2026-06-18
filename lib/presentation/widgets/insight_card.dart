import 'package:flutter/material.dart';

import '../../domain/models/insight.dart';

/// Renders a single behavioural [Insight] with its confidence and optional
/// one-tap action.
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.insight,
    this.onAction,
    this.onDismiss,
  });

  final Insight insight;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidencePct = (insight.confidence * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Dismiss',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(insight.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                _ConfidenceChip(percent: confidencePct),
                const Spacer(),
                if (insight.actionable != null && onAction != null)
                  TextButton(
                    onPressed: onAction,
                    child: Text(insight.actionable!.label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceChip extends StatelessWidget {
  const _ConfidenceChip({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$percent% confidence',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
