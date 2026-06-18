import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/insight_providers.dart';
import '../../../application/providers/user_progress_provider.dart';
import '../../../core/error/app_exception.dart';
import '../../../domain/models/insight.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/insight_card.dart';

/// The "Insights" branch: confidence-ranked behavioural insights, regenerated
/// on demand. Locked until the insights disclosure phase is reached.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(insightsUnlockedProvider);
    final insightsAsync = ref.watch(insightsProvider);
    final regenerating = ref.watch(insightControllerProvider).isLoading;

    ref.listen(insightControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        final message = next.error is AppException
            ? (next.error as AppException).message
            : 'Could not generate insights.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          if (unlocked)
            IconButton(
              tooltip: 'Regenerate',
              onPressed: regenerating
                  ? null
                  : () =>
                      ref.read(insightControllerProvider.notifier).regenerate(),
              icon: regenerating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
        ],
      ),
      body: !unlocked
          ? const EmptyState(
              icon: Icons.auto_awesome_outlined,
              title: 'Insights are warming up',
              message:
                  'Once you have about a week of logs, HabitView starts spotting '
                  'patterns — your best days, skip triggers and momentum.',
            )
          : AsyncValueView<List<Insight>>(
              value: insightsAsync,
              onRetry: () => ref.invalidate(insightsProvider),
              data: (insights) {
                if (insights.isEmpty) {
                  return EmptyState(
                    icon: Icons.lightbulb_outline,
                    title: 'No insights yet',
                    message:
                        'Tap regenerate to analyse your recent activity.',
                    action: FilledButton.icon(
                      onPressed: regenerating
                          ? null
                          : () => ref
                              .read(insightControllerProvider.notifier)
                              .regenerate(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Generate insights'),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final insight in insights)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: InsightCard(insight: insight),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
