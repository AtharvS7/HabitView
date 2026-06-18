import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/premium_service.dart';
import 'settings_providers.dart';

/// Premium entitlement derived from local settings. Swapping in a real billing
/// provider later means setting `premiumUnlocked` from a verified receipt.
final premiumServiceProvider = Provider<PremiumService>(
  (ref) => PremiumService(ref.watch(currentSettingsProvider).premiumUnlocked),
);

final isPremiumProvider =
    Provider<bool>((ref) => ref.watch(premiumServiceProvider).isPremium);
