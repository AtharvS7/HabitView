import 'package:freezed_annotation/freezed_annotation.dart';

part 'habit_log.freezed.dart';
part 'habit_log.g.dart';

@freezed
class HabitLog with _$HabitLog {
  const factory HabitLog({
    required String id,
    required String habitId,
    required String userId,
    required String date, // 'YYYY-MM-DD'
    required LogStatus status,
    SkipReason? skipReason,
    String? skipReasonCustom,
    int? mood, // 1-5
    String? notes,
    DateTime? loggedAt,
    DateTime? completedAt,
  }) = _HabitLog;

  factory HabitLog.fromJson(Map<String, dynamic> json) =>
      _$HabitLogFromJson(json);
}

enum LogStatus {
  done,
  skipped,
}

enum SkipReason {
  tooTired,
  tooBusy,
  forgot,
  lowMotivation,
  custom,
}
