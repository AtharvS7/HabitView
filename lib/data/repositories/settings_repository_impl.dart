import 'package:isar/isar.dart';

import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../local/entities/settings_entity.dart';
import '../local/mappers/settings_mapper.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._isar);

  final Isar _isar;

  @override
  Stream<AppSettings> watch() {
    return _isar.settingsEntitys
        .watchObject(SettingsEntity.singletonId, fireImmediately: true)
        .map((e) => e == null ? const AppSettings() : SettingsMapper.toDomain(e));
  }

  @override
  Future<AppSettings> get() async {
    final e = await _isar.settingsEntitys.get(SettingsEntity.singletonId);
    return e == null ? const AppSettings() : SettingsMapper.toDomain(e);
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _isar.writeTxn(() async {
      await _isar.settingsEntitys.put(SettingsMapper.toEntity(settings));
    });
  }
}
