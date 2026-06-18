import '../../core/constants/app_constants.dart';
import '../../core/error/app_exception.dart';

/// Feature-gating boundary. Entitlement is a single boolean today
/// ([isPremium]) sourced from local settings, but the API is intentionally
/// payment-provider-agnostic: wiring RevenueCat / Play Billing later means
/// flipping [isPremium] from a verified receipt — no call sites change.
class PremiumService {
  const PremiumService(this.isPremium);

  final bool isPremium;

  bool canAccess(PremiumFeature feature) =>
      isPremium || _freeFeatures.contains(feature);

  /// Free tier may create up to [AppConstants.freeMaxActiveHabits] active
  /// habits; premium is unlimited.
  bool canCreateHabit(int currentActiveCount) =>
      isPremium || currentActiveCount < AppConstants.freeMaxActiveHabits;

  int get analyticsWindowDays => isPremium
      ? AppConstants.premiumAnalyticsWindowDays
      : AppConstants.freeAnalyticsWindowDays;

  /// Throws [PremiumRequiredException] when a gated feature is used on free.
  void ensure(PremiumFeature feature) {
    if (!canAccess(feature)) {
      throw PremiumRequiredException(
        '${feature.displayName} requires HabitView Premium.',
      );
    }
  }

  // Everything that is genuinely free for all users.
  static const Set<PremiumFeature> _freeFeatures = {
    PremiumFeature.basicAnalytics,
    PremiumFeature.localBackup,
  };
}

enum PremiumFeature {
  basicAnalytics,
  localBackup,
  advancedAnalytics,
  advancedInsights,
  unlimitedHabits,
  unlimitedCategories,
  enhancedReports,
  cloudBackup;

  String get displayName => switch (this) {
        PremiumFeature.basicAnalytics => 'Basic analytics',
        PremiumFeature.localBackup => 'Local backup',
        PremiumFeature.advancedAnalytics => 'Advanced analytics',
        PremiumFeature.advancedInsights => 'Advanced insights',
        PremiumFeature.unlimitedHabits => 'Unlimited habits',
        PremiumFeature.unlimitedCategories => 'Custom categories',
        PremiumFeature.enhancedReports => 'Enhanced reports',
        PremiumFeature.cloudBackup => 'Encrypted cloud backup',
      };
}
