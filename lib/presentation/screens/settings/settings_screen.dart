import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/auth_providers.dart';
import '../../../application/providers/premium_providers.dart';
import '../../../application/providers/settings_providers.dart';
import '../../../domain/models/app_settings.dart';
import '../../router/app_routes.dart';

/// The "Settings" branch: appearance, account, notifications, backup, premium.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    final controller = ref.read(settingsControllerProvider);
    final user = ref.watch(currentUserProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(settings.themeMode)),
            trailing: DropdownButton<AppThemeMode>(
              value: settings.themeMode,
              underline: const SizedBox.shrink(),
              onChanged: (mode) {
                if (mode != null) controller.setThemeMode(mode);
              },
              items: const [
                DropdownMenuItem(
                    value: AppThemeMode.system, child: Text('System')),
                DropdownMenuItem(
                    value: AppThemeMode.light, child: Text('Light')),
                DropdownMenuItem(
                    value: AppThemeMode.dark, child: Text('Dark')),
              ],
            ),
          ),
          const Divider(),
          const _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(user?.displayLabel ?? 'Account'),
            subtitle: Text(user?.email ?? 'Manage your account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.account),
          ),
          const Divider(),
          const _SectionHeader('Preferences'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications & reminders'),
            subtitle: Text(
              settings.notificationsEnabled ? 'On' : 'Off',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.notifications),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Backup & restore'),
            subtitle: Text(
              settings.cloudBackupEnabled
                  ? 'Cloud backup on'
                  : 'Local export available',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.backup),
          ),
          ListTile(
            leading: Icon(
              isPremium ? Icons.workspace_premium : Icons.star_outline,
              color: isPremium ? Colors.amber.shade700 : null,
            ),
            title: Text(isPremium ? 'HabitView Premium' : 'Upgrade to Premium'),
            subtitle: Text(
              isPremium ? 'Active' : 'Unlimited habits, deeper insights',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.premium),
          ),
        ],
      ),
    );
  }

  String _themeLabel(AppThemeMode mode) => switch (mode) {
        AppThemeMode.system => 'Match system',
        AppThemeMode.light => 'Light',
        AppThemeMode.dark => 'Dark',
      };
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
