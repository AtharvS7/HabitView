import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../core/services/encryption_service.dart';
import '../../core/services/notification_service.dart';
import '../../data/auth/firebase_auth_repository.dart';
import '../../data/backup/backup_repository_impl.dart';
import '../../data/repositories/habit_log_repository_impl.dart';
import '../../data/repositories/habit_repository_impl.dart';
import '../../data/repositories/insight_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/user_progress_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../domain/repositories/habit_log_repository.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/repositories/insight_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/user_progress_repository.dart';
import '../services/analytics_service.dart';
import '../services/consistency_calculator.dart';
import '../services/insight_engine.dart';
import '../services/productivity_calculator.dart';
import '../services/progressive_disclosure_service.dart';
import '../services/streak_calculator.dart';

/// The open Isar instance. Overridden in `main()` once the database is opened
/// so the rest of the app can depend on it synchronously.
final isarProvider = Provider<Isar>(
  (ref) => throw UnimplementedError('isarProvider must be overridden in main()'),
);

/// The shared notification service. Overridden in `main()` after `init()`.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final encryptionServiceProvider =
    Provider<EncryptionService>((ref) => const EncryptionService());

// --- Repositories ----------------------------------------------------------

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => FirebaseAuthRepository());

final habitRepositoryProvider = Provider<HabitRepository>(
  (ref) => HabitRepositoryImpl(ref.watch(isarProvider)),
);

final habitLogRepositoryProvider = Provider<HabitLogRepository>(
  (ref) => HabitLogRepositoryImpl(ref.watch(isarProvider)),
);

final insightRepositoryProvider = Provider<InsightRepository>(
  (ref) => InsightRepositoryImpl(ref.watch(isarProvider)),
);

final userProgressRepositoryProvider = Provider<UserProgressRepository>(
  (ref) => UserProgressRepositoryImpl(ref.watch(isarProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(isarProvider)),
);

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => BackupRepositoryImpl(
    ref.watch(isarProvider),
    encryption: ref.watch(encryptionServiceProvider),
    firestore: FirebaseFirestore.instance,
  ),
);

// --- Stateless domain services --------------------------------------------

final consistencyCalculatorProvider =
    Provider((ref) => ConsistencyCalculator());
final streakCalculatorProvider = Provider((ref) => StreakCalculator());
final productivityCalculatorProvider =
    Provider((ref) => ProductivityCalculator());
final insightEngineProvider = Provider((ref) => InsightEngine());
final analyticsServiceProvider = Provider((ref) => AnalyticsService());
final progressiveDisclosureServiceProvider =
    Provider((ref) => ProgressiveDisclosureService());
