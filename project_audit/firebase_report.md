# Firebase Integration Report — HabitView

_Audit date: 2026-06-17_

## 1. Summary

Firebase integration is **declared but not configured and not initialized**.
`cloud_firestore` is in the dependency list, but there is no `firebase_core`
initialization, no generated options, no platform config files, no security
rules, and no code that actually reads or writes Firestore (the one repository
that did is commented out). In its current state, **any Firestore call will
throw at runtime**.

## 2. Dependencies

From `pubspec.yaml`:
- `cloud_firestore: ^4.15.0` — **declared directly**.
- `firebase_core` — **NOT declared directly**; present only transitively in
  `pubspec.lock` (pulled in by `cloud_firestore`).
- `firebase_auth` — **absent** (yet auth screens are scaffolded).

Observations:
- `firebase_core` should be declared explicitly since you must call
  `Firebase.initializeApp` from it.
- `cloud_firestore 4.x` is a **major version behind** the current 5.x line.
  Upgrading will also bump `firebase_core` and may change minimum platform SDKs.

## 3. Initialization — MISSING

- `Firebase.initializeApp(...)` is called **nowhere** in the codebase.
- `lib/main.dart:3` `main()` is synchronous and runs the counter template; it
  does not initialize Firebase.
- There is **no `lib/firebase_options.dart`** — `flutterfire configure` has not
  been run.

Consequence: the first Firestore access raises
`[core/no-app] No Firebase App '[DEFAULT]' has been created`.

## 4. Platform configuration — MISSING

| Platform | Required file | Present? |
|----------|---------------|----------|
| Android | `android/app/google-services.json` | ❌ |
| Android | google-services Gradle plugin in `android/**/build.gradle.kts` | ❌ |
| iOS/macOS | `GoogleService-Info.plist` | ❌ |
| Web | Firebase SDK / config in `web/index.html` | ❌ (no firebase reference) |
| All | `lib/firebase_options.dart` | ❌ |

The Android `build.gradle.kts` has no `com.google.gms.google-services` plugin
applied, and `applicationId` is still `com.example.habitview` — the Firebase app
registration depends on the final package/bundle id, so identifiers must be set
*before* configuring.

## 5. Security rules / project config — MISSING

- No `firestore.rules`, `firestore.indexes.json`, `firebase.json`, or
  `.firebaserc` in the repo. Rules are therefore unversioned and undefined here.
  See `security_report.md` SEC-01 — this is critical.

## 6. Data access layer — NOT IMPLEMENTED

- `lib/data/firebase/firestore_service.dart` — **empty**. No central Firestore
  handle/collection accessors.
- `lib/data/repositories/*.dart` — **all empty**. No CRUD, queries, or streams.
- `lib/data/firebase/timestamp_mapper.dart:3` — the only real Firebase-adjacent
  code. Correctly converts `Timestamp ↔ DateTime`, but **is never imported or
  used**, which is the root of BUG-05.

## 7. Serialization compatibility issue (critical for Firestore)

The models serialize `DateTime` as ISO-8601 strings and parse them with
`DateTime.parse(... as String)` (`habit.g.dart:23`, `habit_log.g.dart:20`,
`insight.g.dart:21`, `user_progress.g.dart:13`). Firestore natively stores dates
as `Timestamp`. Two failure paths:

1. If you write with `toJson()` (ISO strings), date fields land in Firestore as
   **strings**, losing native timestamp semantics (no range queries/ordering on
   real timestamps).
2. If anything writes a real `Timestamp` (e.g. `FieldValue.serverTimestamp()`,
   as the commented-out `ProgressiveDisclosureService` did via
   `progressive_disclosure_service.dart:25`), reading it back through `fromJson`
   throws `'Timestamp' is not a subtype of 'String'`.

**Fix:** wire `TimestampMapper` into each `DateTime?` field via `@JsonKey`
converters (the commented model versions show the intended pattern) and
regenerate, or convert at the repository boundary.

## 8. Intended Firestore data model (inferred)

From the models, the intended collections are:
- `habits` — `Habit` docs (per `userId`).
- `habit_logs` — `HabitLog` docs (per `habitId`/`userId`, dated `YYYY-MM-DD`).
- `insights` — `Insight` docs.
- `user_progress` — one `UserProgress` doc per `userId` (the commented service
  used `collection('user_progress').doc(userId)`).

No indexes are defined; per-user + date-range queries on `habit_logs` will likely
need composite indexes once implemented.

## 9. Action checklist

1. Add `firebase_core` (and `firebase_auth`) to `pubspec.yaml`; consider
   upgrading to `cloud_firestore 5.x`.
2. Set real Android `applicationId` / iOS bundle id.
3. Run `flutterfire configure` → generates `firebase_options.dart` + platform
   files; apply the google-services Gradle plugin.
4. Make `main()` async and call
   `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
5. Implement `FirestoreService` + repositories; route services through them.
6. Fix Timestamp serialization (BUG-05) using `TimestampMapper`.
7. Author and `firebase deploy` versioned `firestore.rules` + indexes.
8. Enable App Check before launch.
