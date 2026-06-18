# Next Steps — Codespaces Verification

Run these immediately after opening the repo in GitHub Codespaces (the
`.devcontainer/` boots the Flutter toolchain and runs the first two steps
automatically via `setup.sh`). Execute in order; do not skip ahead.

## The exact commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk
```

## Step-by-step: what to expect & likely fixes

### 1. `flutter pub get`
- **Expected:** resolves cleanly; `pubspec.lock` is committed.
- **Risk (low):** transitive conflict on the Firebase line.
- **Fix:** keep `firebase_core` 3.x / `firebase_auth` 5.x / `cloud_firestore` 5.x
  aligned (see `CLAUDE.md`).

### 2. `dart run build_runner build --delete-conflicting-outputs`
- **Why first:** Isar entities (`lib/data/local/entities/`) and freezed models
  (`lib/domain/models/`) declare `part '*.g.dart'` / `part '*.freezed.dart'`;
  nothing compiles until these are generated. They are gitignored, so they will
  not exist on a fresh clone.
- **Expected:** generates all `*.g.dart` / `*.freezed.dart` parts, exits 0.
- **Risk (low–med):** an annotation/schema error in an entity.
- **Fix:** read the generator's error, correct that entity, re-run.

### 3. `flutter analyze`
- **Expected:** clean, OR a focused set of "undefined getter/method" errors in
  `lib/data/local/`.
- **Highest-probability finding (R1):** Isar generated collection-accessor names
  differ from the repo-impl assumptions (`_isar.habitEntitys`,
  `.filter().userIdEqualTo`, `sortByConfidenceDesc`, `watchObject`).
- **Fix:** rename the call sites to match the symbols the generator actually
  emitted. Mechanical; no logic changes. See `COMPILATION_RISK_REPORT.md` R1.
- **Also possible:** a freezed nullable-clear behaviour issue (R2) and minor
  package API deprecations (R6) — follow the analyzer's suggestion.

### 4. `flutter test`
- **Expected:** the 11 authored suites pass.
- **Risk (med):** `test/widget_test.dart` referencing the old launch shell, or a
  missing provider override in a test harness (R3).
- **Fix:** boot the real router + `ProviderScope` with test overrides
  (temp Isar instance / fake repos).

### 5. `flutter build apk`
- **Prerequisite (not optional):** native Firebase config —
  - replace `REPLACE_WITH_ANDROID_API_KEY` in `lib/firebase_options.dart`
    (`flutterfire configure --project=habitview-1574c`),
  - change app id `com.example.habitview` → real id,
  - add `android/app/google-services.json` + Google Sign-In SHA-1,
  - add the Firebase Gradle plugin + notification permission/channel.
- **Expected without that config:** a Firebase/Gradle configuration failure —
  this is configuration, **not a code defect**.
- **Reference:** `RELEASE_CHECKLIST.md` §B/§C, `docs/DEPLOYMENT.md`.

## After running

Update `final_audit/VERIFICATION_STATUS.md`: move each gate ⏳ → ✅ **with the
command output recorded**, or file the failure. Then update
`docs/PRODUCTION_READINESS.md` accordingly.

## Realistic outcome

A single focused session should reach a clean `flutter analyze` and green
`flutter test`, dominated by the mechanical Isar-accessor fixup. The APK build is
a separate session gated on your Firebase credentials.
