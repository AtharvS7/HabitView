# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

HabitView is a **local-first** Flutter habit tracker that surfaces behavioural
insights, not just streaks. All primary data lives in a local **Isar** database;
the app is fully offline-first. **Firebase is used only for authentication**
(email/password + Google) and for an **optional, opt-in, disabled-by-default
encrypted cloud backup** (a single snapshot document per user at `backups/{uid}`,
never per-habit writes — Firebase cost stays ~0).

The full vertical is implemented end-to-end: domain models, business logic, the
Isar data layer (entities, mappers, repositories), Firebase auth + backup
repositories, Riverpod providers, go_router navigation, and the presentation
layer (screens + widgets). See `docs/PRODUCTION_READINESS.md` for the exact state
and the verification gates that still require the Flutter toolchain.

> **Authoring-environment caveat:** much of this was written in an environment
> with **no Dart/Flutter SDK and no `build_runner`**, so generated files
> (`*.g.dart` for Isar entities, `*.freezed.dart`/`*.g.dart` for models) may be
> stale or missing, and the code is **written-to-compile, not compile-verified**.
> The first thing to do in a real toolchain is run build_runner, then
> `flutter analyze` + `flutter test`. See `.devcontainer/` for a ready Codespaces
> setup.

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # REQUIRED: Isar entities + freezed models
dart run build_runner watch --delete-conflicting-outputs
flutter run
flutter analyze
flutter test
flutter test test/application/services/insight_engine_test.dart      # single file
flutter test --plain-name "returns at most three insights"           # single test
```

`build_runner` is required before the first compile: Isar entities in
`lib/data/local/entities/` and the freezed models in `lib/domain/models/` both
declare `part '*.g.dart'`. Regenerate rather than editing generated files by hand.

## Architecture

Layered, dependency rule `presentation → application → domain ← data`:

- `lib/domain/` — immutable models + enums. `Habit`, `HabitLog`, `Insight`/
  `InsightAction`, `UserProgress` are freezed; `AppUser` and `AppSettings`
  (+ `AppThemeMode`) are hand-written plain models (no codegen). Repository
  interfaces live in `domain/repositories/`.
- `lib/application/services/` — pure business logic, unit-tested:
  - `ConsistencyCalculator` — 60% raw + 40% recency-weighted + first/second-half
    trend with a real percentage delta.
  - `InsightEngine` — top-3 confidence-ranked insights from four rules.
  - `ProgressiveDisclosureService` — `trackingOnly → basicStats → insightsEnabled`.
  - `StreakCalculator`, `ProductivityCalculator`, `AnalyticsService` (aggregates
    the calculators into `DashboardStats`), `PremiumService` (feature gating),
    `schedule_utils` (shared "is this habit due today").
- `lib/application/providers/` — Riverpod providers + AsyncNotifier controllers
  (auth, habits, logs, insights, settings, premium, analytics, user progress).
  `app_providers.dart` is the DI root; `isarProvider`/`notificationServiceProvider`
  are overridden in `main()`.
- `lib/data/` — `local/` (Isar `isar_service.dart`, entities, mappers, repository
  impls), `auth/firebase_auth_repository.dart`, `backup/backup_repository_impl.dart`,
  `firebase/timestamp_mapper.dart`.
- `lib/core/` — `theme/app_theme`, `constants/app_constants` (Isar collection
  names + premium/limit constants), `utils/date_utils` (`'YYYY-MM-DD'` day keys),
  `error/app_exception` (sealed `AppException` hierarchy), `services/`
  (`encryption_service`, `notification_service`).
- `lib/presentation/` — `router/` (go_router with `StatefulShellRoute.indexedStack`
  + auth/onboarding redirect), `screens/`, `widgets/`.
- `lib/app.dart` — composition root (`MaterialApp.router` + theme). `lib/main.dart`
  boots Firebase + opens Isar + inits notifications + sets ProviderScope overrides.

## Data layer specifics

- **Isar is the source of truth.** Entities store enums as `.name` strings;
  enum↔domain mapping lives in `data/local/mappers/` so the Isar generator stays
  ignorant of domain enums and on-disk/backup data is stable across enum
  reordering. `enum_mapping.dart` has the null-safe `enumByName` helpers.
- **Settings/`user_progress`** are singletons/per-key rows; `SettingsEntity` uses
  a fixed id. Settings are **device-local** (per device, not per user).
- **Generated Isar accessors**: repo impls assume default Isar codegen
  pluralisation (e.g. `_isar.habitEntitys`, `.filter().userIdEqualTo(...)`,
  `sortByConfidenceDesc`, `watchObject`). **Confirm these after build_runner** —
  if the generated collection accessor name differs, adjust the repo impls.
- **Timestamp mapper** (`data/firebase/timestamp_mapper.dart`) is only relevant to
  the optional Firestore backup path; primary reads/writes go through Isar, not
  Firestore, so raw Firestore maps never reach `fromJson` in normal operation.

## Firebase specifics

- `lib/firebase_options.dart` has real project ids (`habitview-1574c`) but the
  **Android `apiKey` is a placeholder** (`REPLACE_WITH_ANDROID_API_KEY`); set it
  via `flutterfire configure` before a real auth/build run. Android-only today;
  other platforms throw from `DefaultFirebaseOptions.currentPlatform`.
- The only Firestore collection the shipping app touches is `backups/{uid}`
  (single encrypted snapshot doc, opt-in). `firestore.rules` documents this; the
  legacy per-collection rules are retained but unused by the local-first client.
- Backup encryption: AES-256-CBC, key = SHA-256(passphrase). Documented upgrade
  path (Argon2 KDF + GCM) is in `final_audit/security_audit.md`.
- **App identifiers are still `com.example.habitview`** — must change to the real
  id before Firebase registration / store submission (native Android/iOS config).

## Critical gotchas

- **Run build_runner first.** Nothing in `lib/data/local/entities/` or
  `lib/domain/models/` compiles until the `*.g.dart`/`*.freezed.dart` parts exist.
- **freezed `copyWith` + null**: passing `null` to a freezed `copyWith` keeps the
  existing value (it can't distinguish "set to null" from "unchanged"). The habit
  edit flow relies on this; clearing an optional field (e.g. a reminder time) may
  need an explicit path rather than `copyWith(field: null)`.
- **No state until providers resolve**: `currentSettingsProvider` returns
  `AppSettings()` defaults and `userProgressProvider` an anonymous record while
  streams load — screens already handle the loading window via `AsyncValueView`.
- When adding deps, keep the Firebase stack on the resolved line:
  `firebase_core` 3.x / `firebase_auth` 5.x / `cloud_firestore` 5.x, plus
  `isar`/`isar_flutter_libs` 3.1.x.

## Environment

Dart `^3.10.7` (`>=3.10.7 <4.0.0`), Flutter `>=3.22.0`. Primary deps: `isar` +
`isar_flutter_libs` 3.1.x, `flutter_riverpod` 2.5.x, `go_router` 14.x,
`firebase_core`/`firebase_auth`/`cloud_firestore` (3.x/5.x/5.x line),
`flutter_local_notifications` 17.x, `share_plus` 10.x, `file_picker` 8.x,
`encrypt`/`crypto`. `project_audit/` holds the original (Firestore-era) audit;
`final_audit/` holds the post-completion audit; `docs/` holds the current
setup/architecture/features/testing/deployment/readiness guides.
