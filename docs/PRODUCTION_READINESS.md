# Production Readiness — Status

_Rewritten for the Isar local-first architecture after the end-to-end build.
Supersedes the earlier Firestore-era assessment._

## Current verdict: 🟢 Feature-complete in code · 🟡 Pending toolchain verification + native config

The full vertical is implemented across every layer (domain → data → application
→ presentation): models, business logic, the Isar data layer, Firebase auth +
optional encrypted backup, Riverpod providers, go_router navigation, and all
screens + widgets. The remaining work is **verification** (requires the
Dart/Flutter toolchain) and **native/credential configuration** (requires your
Firebase project and signing keys) — not feature work.

## What "done" means here (honest status taxonomy)

| Status | Meaning |
|--------|---------|
| **Implemented** | Code written across all relevant layers. |
| **Statically verified** | Logic reasoned through + covered by authored unit tests (tests not yet *run* here). |
| **Requires-Codespaces-verification** | Needs `build_runner` / `flutter analyze` / `flutter test` in a real toolchain. |
| **Requires native config** | Needs your Firebase keys / app id / signing — not committable blind. |

The authoring environment had **no Dart/Flutter SDK**, so nothing was compiled,
no generated code was built, and no test was executed. Claims below reflect that.

## Implemented (all layers written)

- Domain: `Habit`, `HabitLog`, `Insight`/`InsightAction`, `UserProgress`
  (freezed); `AppUser`, `AppSettings` (+ `AppThemeMode`) hand-written.
- Data: Isar entities + mappers + repository impls; `FirebaseAuthRepository`;
  `BackupRepositoryImpl` (local export/import + optional encrypted cloud doc);
  `EncryptionService`.
- Application: `ConsistencyCalculator`, `InsightEngine`,
  `ProgressiveDisclosureService`, `StreakCalculator`, `ProductivityCalculator`,
  `AnalyticsService`, `PremiumService`, `schedule_utils`; full Riverpod provider
  + AsyncNotifier controller set.
- Presentation: go_router (`StatefulShellRoute.indexedStack` + auth/onboarding
  redirect), all 17 screens, all shared widgets.
- Composition: `app.dart` (MaterialApp.router + theme), `main.dart`
  (Firebase init + Isar open + notifications init + ProviderScope overrides).

## Statically verified (tests authored)

Unit tests exist for: consistency, insight engine, progressive disclosure,
streak, productivity, analytics, premium service, enum mapping, encryption, date
utils — plus a launch widget test. **Authored, not yet run.** Run them per
`docs/CODESPACES_VALIDATION.md`.

## Requires-Codespaces-verification (the gates)

Run in `.devcontainer/` / Codespaces, in this order:

1. `flutter pub get` resolves.
2. `dart run build_runner build --delete-conflicting-outputs` succeeds and emits
   the Isar/freezed parts.
3. `flutter analyze` is clean. **Most likely fixup:** Isar generated collection
   accessor names vs the repo-impl assumptions (`habitEntitys`, etc.) — see
   `CLAUDE.md` and the validation guide.
4. `flutter test` passes.
5. `flutter build apk` / `appbundle` succeed (needs native config below).

## Requires native config (your credentials)

1. **Firebase Android API key** — replace `REPLACE_WITH_ANDROID_API_KEY` in
   `lib/firebase_options.dart` via `flutterfire configure`.
2. **Application id** — change `com.example.habitview` to the real id; add
   `google-services.json` + Google Sign-In SHA-1.
3. **Native** — Firebase Gradle plugin, notification permission/channel, minSdk
   for Isar + notifications.

## Hardening before public launch

App Check, Crashlytics + a global error handler, app icons/splash, release
signing, privacy policy + store data-safety forms, and CI (analyze + test +
coverage). The Argon2/GCM backup-encryption upgrade is documented in
`final_audit/security_audit.md`.

## Summary

There is no remaining *feature* work for a v1. The path to shippable is:
**open the dev container → run the five gates → fix the (likely small) analyzer
findings → add Firebase/native credentials → build.**
