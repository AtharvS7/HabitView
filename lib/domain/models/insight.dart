import 'package:freezed_annotation/freezed_annotation.dart';

part 'insight.freezed.dart';
part 'insight.g.dart';

@freezed
class Insight with _$Insight {
  const factory Insight({
    required String id,
    required String userId,
    String? habitId,
    required String type,
    required String title,
    required String description,
    required double confidence,
    InsightAction? actionable,
    DateTime? generatedAt,
  }) = _Insight;

  factory Insight.fromJson(Map<String, dynamic> json) =>
      _$InsightFromJson(json);
}

@freezed
class InsightAction with _$InsightAction {
  const factory InsightAction({
    required String label,
    required String action,
    Map<String, dynamic>? params,
  }) = _InsightAction;

  factory InsightAction.fromJson(Map<String, dynamic> json) =>
      _$InsightActionFromJson(json);
}
