import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../application/providers/app_providers.dart';
import '../../../application/providers/auth_providers.dart';
import '../../../application/providers/premium_providers.dart';
import '../../../application/providers/settings_providers.dart';
import '../../../core/error/app_exception.dart';
import '../../../domain/repositories/backup_repository.dart';

/// Local export/import (always available, offline) plus optional encrypted
/// cloud backup/restore (opt-in, premium).
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(currentSettingsProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & restore')),
      body: Stack(
        children: [
          ListView(
            children: [
              const _SectionHeader('Local backup'),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: const Text('Export data'),
                subtitle: const Text('Save a .habitview file you can share'),
                onTap: _busy ? null : _exportToFile,
              ),
              ListTile(
                leading: const Icon(Icons.file_open_outlined),
                title: const Text('Import data'),
                subtitle: const Text('Restore from a .habitview file'),
                onTap: _busy ? null : _importFromFile,
              ),
              const Divider(),
              const _SectionHeader('Cloud backup'),
              SwitchListTile(
                secondary: Icon(
                  Icons.cloud_outlined,
                  color: isPremium ? null : theme.colorScheme.outline,
                ),
                title: const Text('Encrypted cloud backup'),
                subtitle: Text(
                  isPremium
                      ? 'Store one encrypted snapshot in the cloud'
                      : 'Premium feature',
                ),
                value: settings.cloudBackupEnabled,
                onChanged: isPremium && !_busy
                    ? (v) => ref
                        .read(settingsControllerProvider)
                        .setCloudBackupEnabled(v)
                    : null,
              ),
              if (settings.cloudBackupEnabled) ...[
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Back up now'),
                  subtitle: Text(
                    settings.lastCloudBackupAt == null
                        ? 'Never backed up'
                        : 'Last backup: ${_formatDate(settings.lastCloudBackupAt!)}',
                  ),
                  onTap: _busy ? null : _backupToCloud,
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: const Text('Restore from cloud'),
                  subtitle: const Text('Replace local data with the snapshot'),
                  onTap: _busy ? null : _restoreFromCloud,
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Cloud backup stores a single encrypted document per user — '
                  'never per-habit writes — to keep it private and cheap. '
                  'Your passphrase never leaves the device.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (_busy)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  String? get _uid => ref.read(currentUserIdProvider);
  BackupRepository get _repo => ref.read(backupRepositoryProvider);

  Future<void> _exportToFile() async {
    final uid = _uid;
    if (uid == null) return;
    await _guard(() async {
      final path = await _repo.exportToFile(uid);
      await Share.shareXFiles([XFile(path)], subject: 'HabitView backup');
    }, success: null);
  }

  Future<void> _importFromFile() async {
    final uid = _uid;
    if (uid == null) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    final path =
        (result != null && result.files.isNotEmpty) ? result.files.first.path : null;
    if (path == null) return;
    await _guard(() async {
      final json = await File(path).readAsString();
      final summary = await _repo.importFromJson(uid, json, merge: true);
      return summary;
    }, success: (r) => 'Imported ${(r as BackupImportResult).total} records');
  }

  Future<void> _backupToCloud() async {
    final uid = _uid;
    if (uid == null) return;
    final passphrase = await _askPassphrase('Encrypt backup');
    if (passphrase == null) return;
    await _guard(() async {
      await _repo.backupToCloud(uid, passphrase: passphrase);
      await ref
          .read(settingsControllerProvider)
          .setLastCloudBackupAt(DateTime.now());
    }, success: (_) => 'Backed up to cloud');
  }

  Future<void> _restoreFromCloud() async {
    final uid = _uid;
    if (uid == null) return;
    final confirmed = await _confirmRestore();
    if (!confirmed) return;
    final passphrase = await _askPassphrase('Decrypt backup');
    if (passphrase == null) return;
    await _guard(
      () => _repo.restoreFromCloud(uid, passphrase: passphrase, merge: false),
      success: (r) => 'Restored ${(r as BackupImportResult).total} records',
    );
  }

  /// Runs [action] with the busy overlay, surfacing a success or error toast.
  Future<void> _guard(
    Future<Object?> Function() action, {
    required String? Function(Object? result)? success,
  }) async {
    setState(() => _busy = true);
    try {
      final result = await action();
      if (!mounted) return;
      final message = success?.call(result);
      if (message != null) _toast(message);
    } catch (e) {
      if (!mounted) return;
      _toast(e is AppException ? e.message : 'Operation failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askPassphrase(String title) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Passphrase',
            helperText: 'Used to encrypt/decrypt your snapshot',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(context, text.isEmpty ? null : text);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmRestore() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore from cloud?'),
        content: const Text(
          'This replaces the data on this device with the cloud snapshot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
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
