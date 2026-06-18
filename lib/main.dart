import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'application/providers/app_providers.dart';
import 'core/services/notification_service.dart';
import 'data/local/isar_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is used for authentication only. If platform config is missing
  // (e.g. running before `flutterfire configure`), we surface a clear error
  // rather than a cryptic crash — see docs/SETUP.md.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Open the local-first database before the app reads any data.
  final isar = await IsarService.open();

  // Prepare local notifications (reminders).
  final notifications = NotificationService();
  await notifications.init();

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const HabitViewApp(),
    ),
  );
}
