import 'dart:convert';

import '../../../domain/models/insight.dart';
import '../entities/insight_entity.dart';

/// Maps between [Insight] (domain) and [InsightEntity] (Isar).
class InsightMapper {
  const InsightMapper._();

  static Insight toDomain(InsightEntity e) {
    InsightAction? action;
    if (e.actionLabel != null && e.actionAction != null) {
      Map<String, dynamic>? params;
      if (e.actionParamsJson != null && e.actionParamsJson!.isNotEmpty) {
        final decoded = jsonDecode(e.actionParamsJson!);
        if (decoded is Map<String, dynamic>) params = decoded;
      }
      action = InsightAction(
        label: e.actionLabel!,
        action: e.actionAction!,
        params: params,
      );
    }

    return Insight(
      id: e.uid,
      userId: e.userId,
      habitId: e.habitId,
      type: e.type,
      title: e.title,
      description: e.description,
      confidence: e.confidence,
      actionable: action,
      generatedAt: e.generatedAt,
    );
  }

  static InsightEntity toEntity(Insight i, {InsightEntity? existing}) {
    final e = existing ?? InsightEntity();
    e.uid = i.id;
    e.userId = i.userId;
    e.habitId = i.habitId;
    e.type = i.type;
    e.title = i.title;
    e.description = i.description;
    e.confidence = i.confidence;
    e.actionLabel = i.actionable?.label;
    e.actionAction = i.actionable?.action;
    e.actionParamsJson = i.actionable?.params == null
        ? null
        : jsonEncode(i.actionable!.params);
    e.generatedAt = i.generatedAt;
    return e;
  }
}
