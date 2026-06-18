import 'package:isar/isar.dart';

part 'insight_entity.g.dart';

/// Isar persistence model for a generated insight. The optional
/// [InsightAction] is flattened into label/action/paramsJson columns.
@collection
class InsightEntity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uid;

  @Index()
  late String userId;

  String? habitId;

  late String type;
  late String title;
  late String description;
  late double confidence;

  String? actionLabel;
  String? actionAction;

  /// JSON-encoded `InsightAction.params`, or null.
  String? actionParamsJson;

  DateTime? generatedAt;
}
