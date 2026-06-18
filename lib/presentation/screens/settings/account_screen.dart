import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/auth_providers.dart';
import '../../../core/error/app_exception.dart';
import '../../../domain/models/app_user.dart';

/// Account management: display name, linked providers, sign out, delete.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final busy = ref.watch(authControllerProvider).isLoading;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: Text(
                _initial(user),
                style: theme.textTheme.headlineMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(user.displayLabel, style: theme.textTheme.titleLarge),
          ),
          if (user.email != null)
            Center(
              child: Text(
                user.email!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Center(
            child: Wrap(
              spacing: 8,
              children: [
                if (user.isPasswordLinked) const Chip(label: Text('Email')),
                if (user.isGoogleLinked) const Chip(label: Text('Google')),
                Chip(
                  label: Text(
                    user.isEmailVerified ? 'Verified' : 'Unverified',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Display name'),
            subtitle: Text(user.displayName ?? 'Not set'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: busy ? null : () => _editName(user),
          ),
          const Divider(height: 32),
          FilledButton.tonalIcon(
            onPressed: busy ? null : _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : _deleteAccount,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Delete account'),
          ),
        ],
      ),
    );
  }

  String _initial(AppUser user) {
    final label = user.displayLabel.trim();
    return label.isEmpty ? '?' : label.characters.first.toUpperCase();
  }

  Future<void> _editName(AppUser user) async {
    final controller = TextEditingController(text: user.displayName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Display name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final ok =
        await ref.read(authControllerProvider.notifier).updateDisplayName(name);
    if (!mounted) return;
    _toast(ok ? 'Name updated' : _errorMessage('Could not update name.'));
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    // The auth stream change triggers the router redirect back to login.
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account. Your local habit data stays '
          'on this device unless you remove the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref.read(authControllerProvider.notifier).deleteAccount();
    if (!mounted) return;
    if (!ok) _toast(_errorMessage('Could not delete the account.'));
  }

  String _errorMessage(String fallback) {
    final error = ref.read(authControllerProvider).error;
    return error is AppException ? error.message : fallback;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
