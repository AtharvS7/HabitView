import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/app_exception.dart';
import '../../domain/models/habit_log.dart';
import '../../domain/repositories/habit_log_repository.dart';
import '../local/entities/habit_log_entity.dart';
import '../local/mappers/habit_log_mapper.dart';

class HabitLogRepositoryImpl implements HabitLogRepository {
  HabitLogRepositoryImpl(this._isar, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final Isar _isar;
  final Uuid _uuid;

  @override
  Stream<List<HabitLog>> watchLogsForHabit(String habitId) {
    return _isar.habitLogEntitys
        .filter()
        .habitIdEqualTo(habitId)
        .sortByDate()
        .build()
        .watch(fireImmediately: true)
        .map((rows) => rows.map(HabitLogMapper.toDomain).toList());
  }

  @override
  Stream<List<HabitLog>> watchLogsForUser(String userId) {
    return _isar.habitLogEntitys
        .filter()
        .userIdEqualTo(userId)
        .sortByDate()
        .build()
        .watch(fireImmediately: true)
        .map((rows) => rows.map(HabitLogMapper.toDomain).toList());
  }

  @override
  Future<List<HabitLog>> getLogsForUser(String userId) async {
    final rows = await _isar.habitLogEntitys
        .filter()
        .userIdEqualTo(userId)
        .sortByDate()
        .findAll();
    return rows.map(HabitLogMapper.toDomain).toList();
  }

  @override
  Future<List<HabitLog>> getLogsForHabit(String habitId) async {
    final rows = await _isar.habitLogEntitys
        .filter()
        .habitIdEqualTo(habitId)
        .sortByDate()
        .findAll();
    return rows.map(HabitLogMapper.toDomain).toList();
  }

  @override
  Future<HabitLog?> getLogForDate(String habitId, String date) async {
    final row = await _isar.habitLogEntitys
        .filter()
        .habitIdEqualTo(habitId)
        .dateEqualTo(date)
        .findFirst();
    return row == null ? null : HabitLogMapper.toDomain(row);
  }

  @override
  Stream<List<HabitLog>> watchLogsForDate(String userId, String date) {
    return _isar.habitLogEntitys
        .filter()
        .userIdEqualTo(userId)
        .dateEqualTo(date)
        .build()
        .watch(fireImmediately: true)
        .map((rows) => rows.map(HabitLogMapper.toDomain).toList());
  }

  @override
  Future<HabitLog> upsertLog(HabitLog log) async {
    final stored = log.id.isEmpty
        ? log.copyWith(id: _uuid.v4())
        : log;
    try {
      await _isar.writeTxn(() async {
        // Preserve isarId when a log already exists for this (habit, date).
        final existing = await _isar.habitLogEntitys
            .filter()
            .habitIdEqualTo(stored.habitId)
            .dateEqualTo(stored.date)
            .findFirst();
        await _isar.habitLogEntitys
            .put(HabitLogMapper.toEntity(stored, existing: existing));
      });
    } catch (e) {
      throw StorageException('Could not save log.', cause: e);
    }
    return stored;
  }

  @override
  Future<void> deleteLog(String id) async {
    await _isar.writeTxn(() async {
      await _isar.habitLogEntitys.filter().uidEqualTo(id).deleteAll();
    });
  }

  @override
  Future<void> deleteLogsForHabit(String habitId) async {
    await _isar.writeTxn(() async {
      await _isar.habitLogEntitys.filter().habitIdEqualTo(habitId).deleteAll();
    });
  }
}
