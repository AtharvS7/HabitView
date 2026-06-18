# Setup Guide

## 1. Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | stable, providing Dart `>=3.10.7 <4.0.0` (Flutter `>=3.22`) |
| Dart | bundled with Flutter |
| Firebase CLI | latest (`npm i -g firebase-tools`) |
| FlutterFire CLI | `dart pub global activate flutterfire_cli` |

Verify:

```bash
flutter --version
flutter doctor
```

> If `flutter`/`dart` are not on your PATH, install the Flutter SDK first:
> https://docs.flutter.dev/get-started/install — the rest of this guide assumes
> they are available.

## 2. Install dependencies & generate code

The domain models use `freezed` + `json_serializable`, so generated files must be
(re)built whenever a model changes:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
# or, while developing:
dart run build_runner watch --delete-conflicting-outputs
```

## 3. Run

```bash
flutter run            # default device
flutter run -d chrome  # web
```

The app currently boots a branded launch shell. Firebase is **not** required to
run this shell, but is required for the data features once they are implemented.

## 4. Firebase configuration (required for data features)

HabitView targets Cloud Firestore. You must connect your own Firebase project.

1. Create a project at <https://console.firebase.google.com>.
2. Choose real application identifiers (do **not** ship `com.example.habitview`).
   - Android: edit `applicationId` and `namespace` in `android/app/build.gradle.kts`.
   - iOS: set the bundle id in Xcode (`ios/Runner.xcodeproj`).
3. Log in and configure:

   ```bash
   firebase login
   flutterfire configure
   ```

   This generates `lib/firebase_options.dart` and the platform config files
   (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`).
4. Add the runtime Firebase packages and initialise (see
   [ARCHITECTURE.md](ARCHITECTURE.md) §"Planned dependencies"):

   ```yaml
   # pubspec.yaml
   dependencies:
     firebase_core: ^2.27.0      # match your cloud_firestore major
     firebase_auth: ^4.17.0
     flutter_riverpod: ^2.5.0
     go_router: ^14.0.0
   ```

   ```dart
   // lib/main.dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
     runApp(const ProviderScope(child: HabitViewApp()));
   }
   ```

   > Pin versions to whatever `flutter pub get` resolves cleanly against the
   > `cloud_firestore` major already in `pubspec.yaml` (currently 4.x; consider
   > upgrading to 5.x together with `firebase_core` 3.x).
5. Deploy security rules and indexes (see [DEPLOYMENT.md](DEPLOYMENT.md)):

   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```

## 5. Enable Authentication

In the Firebase console → Authentication, enable the providers you need
(Email/Password and/or Google). The data model is per-user; `userId` must come
from `FirebaseAuth.instance.currentUser!.uid`, never from client input.

## 6. Optional: local emulators

```bash
firebase emulators:start --only firestore,auth
```

Point the app at the emulators in debug builds to develop without touching
production data.

## Troubleshooting

- **`[core/no-app] No Firebase App '[DEFAULT]'`** — `Firebase.initializeApp` was
  not awaited before a Firestore call (step 4).
- **`type 'Timestamp' is not a subtype of type 'String'`** — date fields must be
  converted with `TimestampMapper` at the repository boundary; see
  [ARCHITECTURE.md](ARCHITECTURE.md) §"Timestamp handling".
- **build_runner conflicts** — always pass `--delete-conflicting-outputs`.
