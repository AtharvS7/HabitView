import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/user_progress.dart';
import 'app_providers.dart';
import 'auth_providers.dart';

final userProgressProvider = StreamProvider<UserProgress>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value(const UserProgress(userId: 'anonymous'));
  }
  return ref.watch(userProgressRepositoryProvider).watch(uid);
});

/// The current progressive-disclosure phase, derived from progress counters.
final disclosurePhaseProvider = Provider<OnboardingPhase>((ref) {
  final progress = ref.watch(userProgressProvider).valueOrNull;
  if (progress == null) return OnboardingPhase.trackingOnly;
  return ref
      .watch(progressiveDisclosureServiceProvider)
      .determinePhase(progress);
});

/// Whether the insights surface should be shown yet.
final insightsUnlockedProvider = Provider<bool>((ref) {
  final progress = ref.watch(userProgressProvider).valueOrNull;
  if (progress == null) return false;
  return ref
      .watch(progressiveDisclosureServiceProvider)
      .shouldShowInsights(progress);
});

final statsUnlockedProvider = Provider<bool>((ref) {
  final progress = ref.watch(userProgressProvider).valueOrNull;
  if (progress == null) return false;
  return ref
      .watch(progressiveDisclosureServiceProvider)
      .shouldShowStats(progress);
});
