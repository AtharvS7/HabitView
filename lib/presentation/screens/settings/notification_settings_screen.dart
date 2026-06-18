import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../application/providers/settings_providers.dart';

/// Notification preferences: master toggle + default reminder time. Reminders
/// are scheduled per-habit when a habit defines a time; this sets the fallback.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    final controller = ref.read(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Habit reminders'),
            subtitle: const Text('Daily nudges for your scheduled habits'),
            value: settings.notificationsEnabled,
            onChanged: (enabled) async {
              await controller.setNotificationsEnabled(enabled);
              if (enabled) {
                await ref
                    .read(notificationServiceProvider)
                    .requestPermissions();
              }
            },
          ),
          const Divider(),
          ListTile(
            enabled: settings.notificationsEnabled,
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Default reminder time'),
            subtitle: Text(settings.defaultReminderTime),
            trailing: const Icon(Icons.edit_outlined),
            onTap: settings.notificationsEnabled
                ? () => _pickTime(context, controller, settings.defaultReminderTime)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Habits without their own reminder time use this default. '
              'Reminders are scheduled entirely on-device.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    SettingsController controller,
    String current,
  ) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final hhmm =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await controller.setDefaultReminderTime(hhmm);
    }
  }
}
