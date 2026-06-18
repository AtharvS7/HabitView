import 'package:isar/isar.dart';

import '../../domain/models/insight.dart';
import '../../domain/repositories/insight_repository.dart';
import '../local/entities/insight_entity.dart';
import '../local/mappers/insight_mapper.dart';

class InsightRepositoryImpl implements InsightRepository {
  InsightRepositoryImpl(this._isar);

  final Isar _isar;

  @override
  Stream<List<Insight>> watchInsights(String userId) {
    return _isar.insightEntitys
        .filter()
        .userIdEqualTo(userId)
        .sortByConfidenceDesc()
        .build()
        .watch(fireImmediately: true)
        .map((rows) => rows.map(InsightMapper.toDomain).toList());
  }

  @override
  Future<List<Insight>> getInsights(String userId) async {
    final rows = await _isar.insightEntitys
        .filter()
        .userIdEqualTo(userId)
        .sortByConfidenceDesc()
        .findAll();
    return rows.map(InsightMapper.toDomain).toList();
  }

  @override
  Future<void> replaceInsights(String userId, List<Insight> insights) async {
    await _isar.writeTxn(() async {
      await _isar.insightEntitys.filter().userIdEqualTo(userId).deleteAll();
      await _isar.insightEntitys
          .putAll(insights.map((i) => InsightMapper.toEntity(i)).toList());
    });
  }

  @override
  Future<void> deleteInsight(String id) async {
    await _isar.writeTxn(() async {
      await _isar.insightEntitys.filter().uidEqualTo(id).deleteAll();
    });
  }

  @override
  Future<void> clear(String userId) async {
    await _isar.writeTxn(() async {
      await _isar.insightEntitys.filter().userIdEqualTo(userId).deleteAll();
    });
  }
}
