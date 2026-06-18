import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/app_settings.dart';
import 'app_providers.dart';

final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

/// Current settings or sensible defaults while the first value loads.
final currentSettingsProvider = Provider<AppSettings>(
  (ref) => ref.watch(settingsProvider).valueOrNull ?? const AppSettings(),
);

final themeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(currentSettingsProvider).themeMode;
  return switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
});

final settingsControllerProvider =
    Provider<SettingsController>((ref) => SettingsController(ref));

class SettingsController {
  SettingsController(this._ref);
  final Ref _ref;

  Future<AppSettings> _current() => _ref.read(settingsRepositoryProvider).get();

  Future<void> _update(AppSettings Function(AppSettings) change) async {
    final current = await _current();
    await _ref.read(settingsRepositoryProvider).save(change(current));
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      _update((s) => s.copyWith(themeMode: mode));

  Future<void> setNotificationsEnabled(bool enabled) =>
      _update((s) => s.copyWith(notificationsEnabled: enabled));

  Future<void> setDefaultReminderTime(String time) =>
      _update((s) => s.copyWith(defaultReminderTime: time));

  Future<void> setCloudBackupEnabled(bool enabled) =>
      _update((s) => s.copyWith(cloudBackupEnabled: enabled));

  Future<void> setAutoBackupOnChange(bool enabled) =>
      _update((s) => s.copyWith(autoBackupOnChange: enabled));

  Future<void> setLastCloudBackupAt(DateTime when) =>
      _update((s) => s.copyWith(lastCloudBackupAt: when));

  Future<void> setPremiumUnlocked(bool unlocked) =>
      _update((s) => s.copyWith(premiumUnlocked: unlocked));

  Future<void> completeOnboarding() =>
      _update((s) => s.copyWith(onboardingCompleted: true));
}
