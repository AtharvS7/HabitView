import 'package:flutter_test/flutter_test.dart';
import 'package:habitview/application/services/progressive_disclosure_service.dart';
import 'package:habitview/domain/models/user_progress.dart';

void main() {
  final service = ProgressiveDisclosureService();

  UserProgress progress({DateTime? firstHabit, int logs = 0}) => UserProgress(
        userId: 'u1',
        firstHabitCreatedAt: firstHabit,
        totalLogsCount: logs,
      );

  group('ProgressiveDisclosureService.determinePhase', () {
    test('no habit yet => trackingOnly', () {
      expect(
        service.determinePhase(progress()),
        OnboardingPhase.trackingOnly,
      );
    });

    test('first habit within 3 days => trackingOnly', () {
      final p = progress(
        firstHabit: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(service.determinePhase(p), OnboardingPhase.trackingOnly);
    });

    test('3-8 days in => basicStats', () {
      final p = progress(
        firstHabit: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(service.determinePhase(p), OnboardingPhase.basicStats);
    });

    test('8+ days and 10+ logs => insightsEnabled', () {
      final p = progress(
        firstHabit: DateTime.now().subtract(const Duration(days: 10)),
        logs: 10,
      );
      expect(service.determinePhase(p), OnboardingPhase.insightsEnabled);
    });

    test('8+ days but too few logs stays at basicStats', () {
      final p = progress(
        firstHabit: DateTime.now().subtract(const Duration(days: 10)),
        logs: 3,
      );
      expect(service.determinePhase(p), OnboardingPhase.basicStats);
    });
  });

  group('ProgressiveDisclosureService gates', () {
    test('insights only show in the insightsEnabled phase', () {
      final enabled = progress(
        firstHabit: DateTime.now().subtract(const Duration(days: 10)),
        logs: 10,
      );
      final early = progress();
      expect(service.shouldShowInsights(enabled), isTrue);
      expect(service.shouldShowInsights(early), isFalse);
    });

    test('stats show from basicStats onward', () {
      final stats = progress(
        firstHabit: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(service.shouldShowStats(stats), isTrue);
      expect(service.shouldShowStats(progress()), isFalse);
    });
  });
}
