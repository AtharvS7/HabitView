// File generated/maintained for HabitView's Firebase Authentication integration.
//
// IMPORTANT: The Android `apiKey` and `storageBucket` below are placeholders.
// HabitView is local-first and Firebase is used ONLY for authentication, so the
// project identifiers (project id, app id, sender id) are real and sufficient
// to wire auth, but the Android API key is a per-project secret that is NOT
// committed here. Before building in Codespaces / CI, run:
//
//     flutterfire configure --project=habitview-1574c
//
// which regenerates this file with the correct `apiKey`, or paste the Android
// API key from the Firebase console (Project settings → General → Your apps).
//
// This is Android-first: other platforms intentionally throw.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  /// Placeholder Android API key. Replace via `flutterfire configure` or by
  /// pasting the real key from the Firebase console before a release build.
  static const String _androidApiKey = 'REPLACE_WITH_ANDROID_API_KEY';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'HabitView is Android-first; web is not configured.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for '
          '$defaultTargetPlatform. Run `flutterfire configure` to add it.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _androidApiKey,
    appId: '1:76750004118:android:ca67c39f31130aca6187b7',
    messagingSenderId: '76750004118',
    projectId: 'habitview-1574c',
    storageBucket: 'habitview-1574c.appspot.com',
  );
}
