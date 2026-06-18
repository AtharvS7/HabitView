import '../models/app_settings.dart';

/// Persists [AppSettings] locally and exposes them reactively.
abstract interface class SettingsRepository {
  Stream<AppSettings> watch();

  Future<AppSettings> get();

  Future<void> save(AppSettings settings);
}
