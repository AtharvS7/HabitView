import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/app_exception.dart';
import '../../domain/models/habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../local/entities/habit_entity.dart';
import '../local/entities/habit_log_entity.dart';
import '../local/mappers/habit_mapper.dart';

class HabitRepositoryImpl implements HabitRepository {
  HabitRepositoryImpl(this._isar, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Isar _isar;
  final Uuid _uuid;

  @override
  Stream<List<Habit>> watchHabits(String userId,
      {bool includeArchived = false}) {
    final query = includeArchived
        ? _isar.habitEntitys
            .filter()
            .userIdEqualTo(userId)
            .sortByCreatedAt()
            .build()
        : _isar.habitEntitys
            .filter()
            .userIdEqualTo(userId)
            .isActiveEqualTo(true)
            .sortByCreatedAt()
            .build();
    return query
        .watch(fireImmediately: true)
        .map((rows) => rows.map(HabitMapper.toDomain).toList());
  }

  @override
  Future<List<Habit>> getHabits(String userId,
      {bool includeArchived = false}) async {
    final rows = includeArchived
        ? await _isar.habitEntitys
            .filter()
            .userIdEqualTo(userId)
            .sortByCreatedAt()
            .findAll()
        : await _isar.habitEntitys
            .filter()
            .userIdEqualTo(userId)
            .isActiveEqualTo(true)
            .sortByCreatedAt()
            .findAll();
    return rows.map(HabitMapper.toDomain).toList();
  }

  @override
  Future<Habit?> getHabit(String id) async {
    final row = await _isar.habitEntitys.filter().uidEqualTo(id).findFirst();
    return row == null ? null : HabitMapper.toDomain(row);
  }

  @override
  Future<Habit> createHabit(Habit habit) async {
    final stored = habit.copyWith(
      id: habit.id.isEmpty ? _uuid.v4() : habit.id,
      createdAt: habit.createdAt ?? DateTime.now(),
    );
    try {
      await _isar.writeTxn(() async {
        await _isar.habitEntitys.put(HabitMapper.toEntity(stored));
      });
    } catch (e) {
      throw StorageException('Could not save habit.', cause: e);
    }
    return stored;
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    try {
      await _isar.writeTxn(() async {
        final existing =
            await _isar.habitEntitys.filter().uidEqualTo(habit.id).findFirst();
        await _isar.habitEntitys
            .put(HabitMapper.toEntity(habit, existing: existing));
      });
    } catch (e) {
      throw StorageException('Could not update habit.', cause: e);
    }
  }

  @override
  Future<void> archiveHabit(String id) => _setActive(id, false);

  @override
  Future<void> restoreHabit(String id) => _setActive(id, true);

  Future<void> _setActive(String id, bool active) async {
    await _isar.writeTxn(() async {
      final existing =
          await _isar.habitEntitys.filter().uidEqualTo(id).findFirst();
      if (existing == null) return;
      existing.isActive = active;
      existing.pausedAt = active ? null : DateTime.now();
      await _isar.habitEntitys.put(existing);
    });
  }

  @override
  Future<void> deleteHabit(String id) async {
    await _isar.writeTxn(() async {
      await _isar.habitEntitys.filter().uidEqualTo(id).deleteAll();
      await _isar.habitLogEntitys.filter().habitIdEqualTo(id).deleteAll();
    });
  }

  @override
  Future<int> activeHabitCount(String userId) {
    return _isar.habitEntitys
        .filter()
        .userIdEqualTo(userId)
        .isActiveEqualTo(true)
        .count();
  }
}
