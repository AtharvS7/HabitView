# HabitView

> A **local-first** Flutter habit tracker that surfaces **behavioural insights**, not just streaks.

HabitView records daily habits, computes a recency-weighted consistency score,
tracks streaks and a difficulty-weighted productivity score, and runs a small
rule-based engine that explains *why* a habit is or isn't sticking (best time of
day, difficulty mismatch, dominant skip reason, recovery strength). It uses a
progressive-disclosure model so new users see tracking first and analytics only
once there is enough data to be meaningful.

All primary data lives in an on-device **Isar** database — the app is fully
**offline-first** and works with no network. **Firebase is used only for
authentication** (email/password + Google) and for an **optional, opt-in,
disabled-by-default encrypted cloud backup** (a single snapshot document per user
at `backups/{uid}`, never per-habit writes — keeping Firebase cost ~0).

---

## Status

The full vertical is implemented end-to-end: domain, business logic, the Isar
data layer, Firebase auth + backup repositories, Riverpod providers, go_router
navigation, and the presentation layer (17 screens + widgets).

> **Verification caveat (honest):** this code was authored in an environment
> **without a Dart/Flutter SDK and without `build_runner`**. The code is
> **written-to-compile, not compile-verified**. Generated files (`*.g.dart` for
> Isar entities, `*.freezed.dart`/`*.g.dart` for freezed models) may be missing
> or stale. **No `flutter analyze`, `flutter test`, or `flutter build` has been
> run.** The first task in a real toolchain is to run `build_runner`, then
> analyze + test. A ready Codespaces setup lives in [`.devcontainer/`](.devcontainer/).

| Area | State |
|------|-------|
| Domain models (`freezed` + hand-written plain models) | ✅ Implemented |
| Business logic (consistency, insights, streaks, productivity, analytics, premium, progressive disclosure) | ✅ Implemented + unit tests authored |
| Isar data layer (entities, mappers, repositories) | ✅ Implemented (needs `build_runner`) |
| Firebase auth repository (email/password + Google) | ✅ Implemented |
| Optional encrypted cloud backup repository | ✅ Implemented |
| State management / DI (Riverpod) | ✅ Implemented |
| Navigation (`go_router` shell + auth/onboarding redirect) | ✅ Implemented |
| Presentation (17 screens + widgets, Material 3) | ✅ Implemented |
| Generated code (`build_runner`) | ⚠️ Must be regenerated in a real toolchain |
| Static analysis / tests / builds | ⚠️ Authored but **not run** here |
| Native Android/iOS config (package id, `google-services.json`, SHA-1, real Android `apiKey`) | ⛔ Requires your credentials |

See [`docs/PRODUCTION_READINESS.md`](docs/PRODUCTION_READINESS.md) for the exact
remaining work and [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the design.

---

## Quick start

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # REQUIRED: Isar entities + freezed models
flutter analyze
flutter test
flutter run
```

`build_runner` is required before the first compile — Isar entities and the
freezed models both declare `part '*.g.dart'`. The app boots without a network,
but **authentication and cloud backup need Firebase configured** (see below).

Full environment + Firebase setup: [`docs/SETUP.md`](docs/SETUP.md).
No-local-SDK path (GitHub Codespaces): [`.devcontainer/`](.devcontainer/).

---

## Architecture at a glance

```
lib/
  core/          theme, constants, date utils, errors, encryption + notifications
  domain/        immutable models + enums + repository interfaces (the contract)
  application/   pure business logic (services) + Riverpod providers/controllers
  data/
    local/       Isar service, entities, mappers, repository impls  ← source of truth
    auth/        Firebase Auth repository (auth only)
    backup/      optional encrypted cloud-backup repository
    firebase/    timestamp mapper (backup path only)
  presentation/  router (go_router) + 17 screens + widgets
  app.dart       composition root (MaterialApp.router + theme)
  main.dart      boots Firebase, opens Isar, inits notifications, ProviderScope
```

Dependency rule: `presentation → application → domain ← data`. The domain layer
depends on nothing; everything points inward. **Isar is the on-device source of
truth**; Firebase sits at the edges (auth + opt-in backup) behind repository
interfaces.

Key logic:

- **Consistency scoring** — `application/services/consistency_calculator.dart`
- **Streaks** — `application/services/streak_calculator.dart`
- **Productivity score** — `application/services/productivity_calculator.dart`
- **Dashboard aggregation** — `application/services/analytics_service.dart`
- **Insight rules** — `application/services/insight_engine.dart`
- **Premium gating** — `application/services/premium_service.dart`
- **Progressive disclosure** — `application/services/progressive_disclosure_service.dart`

---

## Documentation

| Doc | Purpose |
|-----|---------|
| [docs/SETUP.md](docs/SETUP.md) | Local dev, `build_runner`, Firebase (auth + optional backup) |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Layers, Isar data model, local-first data flow, navigation |
| [docs/FEATURES.md](docs/FEATURES.md) | Feature catalogue + the scoring/insight logic |
| [docs/TESTING.md](docs/TESTING.md) | Test strategy, suites, gaps, how to run |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | Release builds + store readiness |
| [docs/PRODUCTION_READINESS.md](docs/PRODUCTION_READINESS.md) | Post-completion status + remaining roadmap |
| [RESUME_SUMMARY.md](RESUME_SUMMARY.md) | Portfolio / resume summary |
| [project_audit/](project_audit/) | Original (Firestore-era) code audit |
| [final_audit/](final_audit/) | Post-completion audit reports |

---

## Tech stack

Flutter (Material 3) · Dart 3 · **Isar 3.1.x** (local-first DB) ·
`flutter_riverpod` 2.5.x (state/DI) · `go_router` 14.x (navigation) ·
`firebase_core` 3.x / `firebase_auth` 5.x / `cloud_firestore` 5.x (auth + optional
backup) · `flutter_local_notifications` 17.x · `share_plus` 10.x / `file_picker`
8.x (export/import) · `encrypt` + `crypto` (backup encryption) · `freezed` +
`json_serializable`.
