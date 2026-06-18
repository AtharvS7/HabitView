# Release Checklist

Ordered path from the current state (feature-complete in code, unverified) to a
store-ready Android build. Check items off as you go. See `docs/SETUP.md` and
`docs/DEPLOYMENT.md` for the long-form procedures.

## A. Toolchain verification (in `.devcontainer/` / Codespaces)

- [ ] `flutter pub get` resolves with no version conflicts
- [ ] `dart run build_runner build --delete-conflicting-outputs` succeeds
- [ ] Confirm Isar generated accessor names match repo impls (`habitEntitys`,
      `.filter().userIdEqualTo`, `sortByConfidenceDesc`, `watchObject`) — fix if
      different (`final_audit/code_audit.md` C-1)
- [ ] `flutter analyze` is clean
- [ ] `flutter test` — all 11 suites pass
- [ ] Update `final_audit/VERIFICATION_STATUS.md` with the run output

## B. Firebase configuration

- [ ] `flutterfire configure` for project `habitview-1574c`
- [ ] Replace `REPLACE_WITH_ANDROID_API_KEY` in `lib/firebase_options.dart`
- [ ] Add `android/app/google-services.json`
- [ ] Register Google Sign-In SHA-1 (debug **and** release)
- [ ] Enable Email/Password + Google providers in the Firebase console
- [ ] Enable **Firebase App Check**
- [ ] Deploy `firestore.rules` (owner-only `backups/{uid}`); add a size/shape
      guard on the backup doc

## C. Native / app identity

- [ ] Change application id `com.example.habitview` → real id (e.g.
      `com.atharvsawane.habitview`) in `android/`
- [ ] Add Firebase Gradle plugin + Google Services classpath
- [ ] Set minSdk required by Isar + `flutter_local_notifications`
- [ ] Declare notification permission + create the notification channel
- [ ] App icons + splash screen
- [ ] Bump `version:` in `pubspec.yaml` (versionName + versionCode)

## D. Release build & quality

- [ ] Configure release signing (keystore, `key.properties`, Gradle signingConfig)
- [ ] `flutter build appbundle --release` succeeds
- [ ] Smoke test on a device: register → onboarding → create habit → log/skip →
      dashboard → insights → backup export/import
- [ ] Add Crashlytics + a global `FlutterError`/zone error handler
- [ ] (Recommended) CI: analyze + test + coverage on every push

## E. Store submission

- [ ] Privacy policy (covers Firebase Auth + optional cloud backup)
- [ ] Play data-safety form (note: data is local-first; cloud backup is opt-in &
      encrypted)
- [ ] Store listing assets (screenshots, description, feature graphic)
- [ ] Internal testing track → closed → production rollout

## F. Security hardening (before public)

- [ ] Backup encryption upgrade: Argon2id KDF + AES-256-GCM + per-backup salt
      (`final_audit/security_audit.md` SEC-B1/B2/B3)
- [ ] Passphrase-strength validation in `backup_screen` (SEC-B4)
- [ ] Consider Isar at-rest encryption for privacy-sensitive users
- [ ] Decide on email-verification enforcement policy

---

**Current blocking gate:** Section A has not been run (no SDK in the authoring
environment). Everything downstream depends on it.
