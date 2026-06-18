import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/premium_providers.dart';
import '../../../application/providers/settings_providers.dart';

/// Premium upsell. Entitlement is a local flag today ([AppSettings.premiumUnlocked]);
/// a real billing integration would set it from a verified receipt without
/// changing this screen's structure.
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  static const _benefits = [
    (Icons.all_inclusive, 'Unlimited habits',
        'Track as many habits as you like — no 10-habit cap.'),
    (Icons.insights, 'Deeper insights',
        'A full year of history powers richer pattern detection.'),
    (Icons.category_outlined, 'Custom categories',
        'Organise habits your way beyond the built-in set.'),
    (Icons.cloud_done_outlined, 'Encrypted cloud backup',
        'Opt-in, end-to-end encrypted snapshots you control.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(isPremiumProvider);
    final controller = ref.read(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('HabitView Premium')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.workspace_premium,
              size: 64, color: Colors.amber.shade700),
          const SizedBox(height: 12),
          Text(
            isPremium ? "You're a Premium member" : 'Go further with Premium',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            isPremium
                ? 'Thanks for supporting HabitView. All features are unlocked.'
                : 'Unlock everything HabitView has to offer.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          for (final (icon, title, body) in _benefits)
            Card(
              child: ListTile(
                leading: Icon(icon, color: theme.colorScheme.primary),
                title: Text(title),
                subtitle: Text(body),
                trailing: isPremium
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
            ),
          const SizedBox(height: 24),
          if (isPremium)
            OutlinedButton(
              onPressed: () => controller.setPremiumUnlocked(false),
              child: const Text('Deactivate (test)'),
            )
          else
            FilledButton.icon(
              onPressed: () => controller.setPremiumUnlocked(true),
              icon: const Icon(Icons.lock_open),
              label: const Text('Unlock Premium'),
            ),
          const SizedBox(height: 8),
          Text(
            'Note: this build uses a local entitlement flag for demonstration. '
            'Wiring a store/billing provider sets the same flag from a verified '
            'receipt — no UI changes required.',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
