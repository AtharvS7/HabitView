import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_progress.freezed.dart';
part 'user_progress.g.dart';

@freezed
class UserProgress with _$UserProgress {
  const factory UserProgress({
    required String userId,
    @Default(1) int schemaVersion,
    DateTime? firstHabitCreatedAt,
    DateTime? firstLogAt,
    @Default(0) int totalLogsCount,
    @Default(0) int habitsCreated,
    @Default(false) bool onboardingCompleted,
  }) = _UserProgress;

  factory UserProgress.fromJson(Map<String, dynamic> json) =>
      _$UserProgressFromJson(json);
}

enum OnboardingPhase {
  trackingOnly,
  basicStats,
  insightsEnabled,
}
