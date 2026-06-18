import 'package:isar/isar.dart';

import '../../domain/models/user_progress.dart';
import '../../domain/repositories/user_progress_repository.dart';
import '../local/entities/user_progress_entity.dart';
import '../local/mappers/user_progress_mapper.dart';

class UserProgressRepositoryImpl implements UserProgressRepository {
  UserProgressRepositoryImpl(this._isar);

  final Isar _isar;

  @override
  Future<UserProgress> getOrCreate(String userId) async {
    final existing = await _findEntity(userId);
    if (existing != null) return UserProgressMapper.toDomain(existing);

    final created = UserProgressEntity()..userId = userId;
    await _isar.writeTxn(() async {
      await _isar.userProgressEntitys.put(created);
    });
    return UserProgressMapper.toDomain(created);
  }

  @override
  Stream<UserProgress> watch(String userId) {
    return _isar.userProgressEntitys
        .filter()
        .userIdEqualTo(userId)
        .build()
        .watch(fireImmediately: true)
        .map((rows) => rows.isEmpty
            ? UserProgress(userId: userId)
            : UserProgressMapper.toDomain(rows.first));
  }

  @override
  Future<void> save(UserProgress progress) async {
    await _isar.writeTxn(() async {
      final existing = await _findEntity(progress.userId);
      await _isar.userProgressEntitys
          .put(UserProgressMapper.toEntity(progress, existing: existing));
    });
  }

  @override
  Future<void> recordHabitCreated(String userId) async {
    await _isar.writeTxn(() async {
      final e = await _findEntity(userId) ?? (UserProgressEntity()..userId = userId);
      e.habitsCreated += 1;
      e.firstHabitCreatedAt ??= DateTime.now();
      await _isar.userProgressEntitys.put(e);
    });
  }

  @override
  Future<void> recordLog(String userId) async {
    await _isar.writeTxn(() async {
      final e = await _findEntity(userId) ?? (UserProgressEntity()..userId = userId);
      e.totalLogsCount += 1;
      e.firstLogAt ??= DateTime.now();
      await _isar.userProgressEntitys.put(e);
    });
  }

  @override
  Future<void> completeOnboarding(String userId) async {
    await _isar.writeTxn(() async {
      final e = await _findEntity(userId) ?? (UserProgressEntity()..userId = userId);
      e.onboardingCompleted = true;
      await _isar.userProgressEntitys.put(e);
    });
  }

  Future<UserProgressEntity?> _findEntity(String userId) {
    return _isar.userProgressEntitys.filter().userIdEqualTo(userId).findFirst();
  }
}
