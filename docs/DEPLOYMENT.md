# Deployment Guide

This guide covers producing release builds and the store-readiness checklist.
Several steps require credentials/accounts you must supply (see the bottom).

## 0. Pre-flight

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze        # must be clean
flutter test           # must pass
```

## 1. Firebase backend

```bash
firebase login
flutterfire configure                 # if not already done (see SETUP.md)
firebase deploy --only firestore:rules,firestore:indexes
```

- Verify rules in the console's Rules Playground.
- Enable **App Check** (Play Integrity / DeviceCheck / reCAPTCHA) before public
  launch to stop off-app use of your public API key.
- Enable the Auth providers you ship with.

## 2. Application identifiers (one-time)

Replace the placeholder `com.example.habitview` **before** registering Firebase
apps (the id is baked into the Firebase registration):
- Android: `applicationId` + `namespace` in `android/app/build.gradle.kts`.
- iOS: bundle id in Xcode.

## 3. Android release

1. Create a keystore and configure signing in `android/app/build.gradle.kts`
   (via a `key.properties` file kept out of version control).
2. Set `minSdk`/`targetSdk` appropriate for your Firebase packages.
3. Build:
   ```bash
   flutter build appbundle --release      # Play Store (.aab)
   flutter build apk --release            # sideload/testing
   ```
4. Upload the `.aab` to the Play Console.

## 4. iOS release

1. Set the team/signing in Xcode; create the App Store Connect record.
2. Build & archive:
   ```bash
   flutter build ipa --release
   ```
3. Upload via Xcode Organizer or `xcrun altool`/Transporter.

## 5. Web (optional)

```bash
flutter build web --release
firebase deploy --only hosting        # if you add Firebase Hosting config
```

## Store-readiness checklist

- [ ] Real bundle/application id (not `com.example.*`)
- [ ] App icons + splash for every platform (currently default Flutter assets)
- [ ] Versioned, deployed Firestore rules + indexes
- [ ] App Check enabled
- [ ] Auth providers enabled and tested
- [ ] Release signing configured (Android keystore, iOS provisioning)
- [ ] `flutter analyze` clean, `flutter test` green
- [ ] Crash reporting (Crashlytics) + a global error handler
- [ ] Privacy policy + data-safety/App-Privacy forms (the app stores personal
      habit data + auth)
- [ ] Store listing assets (screenshots, description)

## Things only you can provide

- Firebase project + credentials (`firebase login`, generated config files).
- Apple Developer + Google Play Console accounts and signing material.
- Final application identifiers and branding assets.
- Privacy policy URL and store metadata.
