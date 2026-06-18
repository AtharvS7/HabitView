import 'package:flutter_test/flutter_test.dart';
import 'package:habitview/application/services/premium_service.dart';
import 'package:habitview/core/constants/app_constants.dart';
import 'package:habitview/core/error/app_exception.dart';

void main() {
  group('PremiumService (free tier)', () {
    const free = PremiumService(false);

    test('allows creating habits up to the free cap, then blocks', () {
      expect(free.canCreateHabit(0), isTrue);
      expect(free.canCreateHabit(AppConstants.freeMaxActiveHabits - 1), isTrue);
      expect(free.canCreateHabit(AppConstants.freeMaxActiveHabits), isFalse);
    });

    test('uses the free analytics window', () {
      expect(free.analyticsWindowDays, AppConstants.freeAnalyticsWindowDays);
    });

    test('grants genuinely-free features but gates premium ones', () {
      expect(free.canAccess(PremiumFeature.basicAnalytics), isTrue);
      expect(free.canAccess(PremiumFeature.localBackup), isTrue);
      expect(free.canAccess(PremiumFeature.advancedInsights), isFalse);
      expect(free.canAccess(PremiumFeature.cloudBackup), isFalse);
    });

    test('ensure throws PremiumRequiredException for gated features', () {
      expect(
        () => free.ensure(PremiumFeature.unlimitedHabits),
        throwsA(isA<PremiumRequiredException>()),
      );
      // A free feature does not throw.
      expect(() => free.ensure(PremiumFeature.localBackup), returnsNormally);
    });
  });

  group('PremiumService (premium)', () {
    const premium = PremiumService(true);

    test('lifts the habit cap', () {
      expect(premium.canCreateHabit(9999), isTrue);
    });

    test('uses the larger analytics window', () {
      expect(
        premium.analyticsWindowDays,
        AppConstants.premiumAnalyticsWindowDays,
      );
    });

    test('can access every feature', () {
      for (final feature in PremiumFeature.values) {
        expect(premium.canAccess(feature), isTrue, reason: feature.name);
      }
    });
  });
}
