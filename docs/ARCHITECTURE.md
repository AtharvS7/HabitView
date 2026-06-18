# Architecture

## Overview

HabitView is a **local-first**, offline-first Flutter app following a layered
("clean architecture") design with a strict, inward-pointing dependency rule:

```
presentation  ─────▶  application  ─────▶  domain  ◀─────  data
   (UI,                (services,            (models,        (Isar local DB,
    go_router)          Riverpod state)       interfaces)     Firebase auth/backup)
```

- **domain** depends on nothing. It defines models, enums, and the repository
  interfaces every other layer talks to.
- **application** depends only on domain. Pure business logic + Riverpod state.
- **data** depends on domain — it *implements* the repository interfaces. The
  primary implementation is **Isar** (on-device); Firebase implementations exist
  only for authentication and optional cloud backup.
- **presentation** depends on application (and domain models for display).

This keeps business rules testable in isolation (no Flutter, no Isar, no
Firebase) — the unit tests under `test/application/` exercise the services with
plain objects.

> **Source of truth = Isar.** All habit, log, insight, progress, and settings
> data is read from and written to a local Isar database. The app is fully usable
> with no network. Firebase is an *edge* concern (auth + opt-in backup) hidden
> behind repository interfaces.

## Layer map

| Path | Responsibility | Status |
|------|----------------|--------|
| `lib/core/` | Theme, constants, date utils, sealed `AppException`, encryption + notification services | ✅ |
| `lib/domain/models/` | `Habit`, `HabitLog`, `Insight`/`InsightAction`, `UserProgress` (freezed); `AppUser`, `AppSettings` (+ `AppThemeMode`) plain models | ✅ |
| `lib/domain/repositories/` | Repository interfaces: auth, habit, habit_log, insight, user_progress, settings, backup | ✅ |
| `lib/application/services/` | Consistency, streak, productivity, analytics, insight, premium, progressive-disclosure, schedule utils | ✅ |
| `lib/application/providers/` | Riverpod providers + `AsyncNotifier` controllers (DI + state) | ✅ |
| `lib/data/local/` | Isar `IsarService`, entities, mappers, repository impls (the source of truth) | ✅ (needs `build_runner`) |
| `lib/data/auth/` | `FirebaseAuthRepository` (email/password + Google) | ✅ |
| `lib/data/backup/` | `BackupRepositoryImpl` (local export/import + optional encrypted cloud snapshot) | ✅ |
| `lib/data/firebase/` | `TimestampMapper` (backup path only) | ✅ |
| `lib/presentation/router/` | `go_router` config (`StatefulShellRoute.indexedStack` + redirect) | ✅ |
| `lib/presentation/screens/` | 17 screens: splash, auth (3), onboarding, home shell, today, dashboard, insights, habits (3), settings (5) | ✅ |
| `lib/presentation/widgets/` | metric/habit/insight cards, skip-reflection sheet, async-value view, habit form, category visuals | ✅ |
| `lib/app.dart` | Composition root (`MaterialApp.router` + theme mode) | ✅ |
| `lib/main.dart` | Boots Firebase, opens Isar, inits notifications, sets `ProviderScope` overrides | ✅ |

## The Isar data model

Isar is the primary database. Each domain aggregate has a matching `@collection`
entity in `lib/data/local/entities/`, and a mapper in `lib/data/local/mappers/`
translates entity ⇄ domain model.

```
HabitEntity          ⇄  Habit
HabitLogEntity       ⇄  HabitLog   (composite unique index habitId + date 'YYYY-MM-DD')
InsightEntity        ⇄  Insight
UserProgressEntity   ⇄  UserProgress   (per-user)
SettingsEntity       ⇄  AppSettings    (singleton, fixed id; device-local)
```

Design rules baked into the data layer:

- **Enums are stored as `.name` strings.** Entities never reference domain enum
  types directly; the enum↔domain conversion lives in
  `data/local/mappers/enum_mapping.dart` (null-safe `enumByName` helpers). This
  keeps the Isar generator ignorant of domain enums and keeps on-disk and backup
  data **stable across enum reordering** (no ordinal coupling).
- **Settings are device-local**, not per-user — a single `SettingsEntity` row
  with a fixed id holds theme, onboarding flag, premium entitlement, reminders.
- **Per-user scoping** is by a `userId` field on entities (uid from Firebase
  Auth), so the local DB can hold data for whichever account is signed in.
- **Generated accessors:** repository impls assume default Isar codegen
  pluralisation (e.g. `_isar.habitEntitys`, `.filter().userIdEqualTo(...)`,
  `sortByConfidenceDesc`, `watchObject`). **Confirm these after `build_runner`** —
  if the generated collection accessor name differs, adjust the repo impls.

## Local-first data flow

```
UI (screen)
  → reads a Riverpod provider/controller          (application/providers)
     → calls a repository interface                (domain/repositories)
        → Isar repository impl                     (data/local/repositories)
           → Isar query / watch* stream            (on-device DB)
  ← reactive stream pushes changes back to the UI
```

Writes follow the same path in reverse and persist immediately to Isar. There is
**no network round-trip on the read/write path** — reactivity comes from Isar's
`watch*` streams surfaced through Riverpod. Providers expose sane defaults while
streams are loading (e.g. `currentSettingsProvider` returns `AppSettings()`
defaults), and screens render the loading window via `AsyncValueView`.

## Where Firebase fits (auth + optional backup only)

Firebase is deliberately minimal:

1. **Authentication** — `data/auth/firebase_auth_repository.dart` wraps
   `firebase_auth` (email/password + Google sign-in). It is the source of the
   `uid` used to scope local data. Auth errors are translated to a typed
   `AuthException` (`core/error/app_exception.dart`). It is the only place that
   imports `firebase_auth`.
2. **Optional encrypted cloud backup** — `data/backup/backup_repository_impl.dart`
   can write a **single snapshot document** per user to `backups/{uid}` in Cloud
   Firestore, and restore from it. This is **opt-in and disabled by default**.
   There are **no per-habit Firestore writes**, which keeps Firestore usage to at
   most one document per user (Firebase cost ~0). The payload is an opaque,
   optionally AES-256-CBC-encrypted JSON blob.

`firestore.rules` reflects this: the only collection the shipping client touches
at runtime is `backups/{uid}` (owner-only). Legacy per-collection rules for
`habits`/`habit_logs`/`insights`/`user_progress` are retained for a possible
future server-sync mode but are **unused by the local-first client**.

`lib/firebase_options.dart` has real project ids but the **Android `apiKey` is a
placeholder** (`REPLACE_WITH_ANDROID_API_KEY`) — set it via `flutterfire
configure` before any real auth/build run (see [SETUP.md](SETUP.md)).

## Core business logic

All services are pure Dart (no Flutter/Isar/Firebase) and unit-tested.

### Consistency scoring (`consistency_calculator.dart`)
Over a rolling window (default 14 days) it blends:
- **Raw ratio** (60%): completed ÷ expected scheduled days.
- **Recency-weighted ratio** (40%): recent days weighted more heavily (weight
  decays with age, floored).

It also derives a **trend** by comparing the completion rate of the window's
first half vs second half, and reports the real percentage-point delta.

### Streaks (`streak_calculator.dart`)
Current and longest streaks over scheduled days, with a **"today grace"** rule:
an unlogged *today* does not break the current streak (only a missed *past*
scheduled day does).

### Productivity score (`productivity_calculator.dart`)
A **difficulty-weighted completion ratio** over the window — harder habits
(higher `difficulty`) contribute more, so finishing tough habits scores higher
than easy ones.

### Analytics aggregation (`analytics_service.dart`)
Aggregates the calculators into a single `DashboardStats` (consistency, streaks,
productivity, completion rates) over the active analytics window — the dashboard
screen renders directly from this.

### Insight engine (`insight_engine.dart`)
Four independent heuristic rules, each returning at most one `Insight` above a
confidence floor. The engine sorts by confidence and returns the **top 3**:
1. **Time preference** — which part of day has the best completion rate.
2. **Difficulty mismatch** — a hard habit with low recent completion.
3. **Skip pattern** — a dominant skip reason.
4. **Recovery strength** — completion rate immediately after a skip.

Logs are sorted chronologically before rules run so order-dependent rules
(recovery, "recent N") are deterministic.

### Premium gating (`premium_service.dart`)
`PremiumService(isPremium)` gates features and limits, sourced from a local
`AppSettings.premiumUnlocked` flag — **payment-provider-agnostic** by design
(wiring RevenueCat / Play Billing later just flips the flag from a verified
receipt; no call sites change). Free tier = **10 active habits + 30-day analytics
window**; premium = **unlimited + 365-day window** (plus advanced
insights/reports, custom categories, cloud backup).

### Progressive disclosure (`progressive_disclosure_service.dart`)
Maps `UserProgress` to a phase: `trackingOnly` → `basicStats` → `insightsEnabled`
(gated on days tracked *and* number of logs). The UI reveals stats/insights only
once they are meaningful.

## Navigation

`presentation/router/app_router.dart` builds a `GoRouter` with:

- A **`StatefulShellRoute.indexedStack`** bottom-nav shell with four branches:
  **Today → Dashboard → Insights → Settings** (each keeps its own navigation
  state). `HomeShell` hosts the `StatefulNavigationShell`.
- **Full-screen routes outside the shell** for habit create/edit/detail and the
  settings sub-screens (account, backup, notifications, premium).
- A **redirect** driven by auth state + the `onboardingCompleted` settings flag:
  while the first auth event resolves → **splash**; signed out → **login**
  (allowing register/forgot); signed in but not onboarded → **onboarding**;
  signed in + onboarded → **today**. The router refreshes whenever auth state or
  settings change (a `ValueNotifier` bumped by `ref.listen`).

## Timestamp handling (backup only)

In the local-first design, dates round-trip through Isar natively — **no
`Timestamp` conversion is needed on the primary read/write path**, and raw
Firestore maps never reach `fromJson`.

The one place `Timestamp` matters is the **optional cloud-backup path**. Generated
JSON (de)serialises `DateTime` as ISO-8601 strings, but Cloud Firestore stores
dates as `Timestamp`. The backup repository converts at the Firestore boundary
using `data/firebase/timestamp_mapper.dart`:

```dart
// writing a backup snapshot field
final json = model.toJson();
await ref.set({
  ...json,
  'createdAt': TimestampMapper.toFirestore(model.createdAt),
});

// reading a backup snapshot field
final raw = doc.data()!;
final model = Habit.fromJson({
  ...raw,
  'createdAt': TimestampMapper.fromFirestore(raw['createdAt'])?.toIso8601String(),
});
```

Because the backup payload is typically a single encrypted blob, most fields are
serialised as JSON strings inside the blob rather than as native `Timestamp`s;
the mapper covers any fields stored as top-level Firestore values.

## Dependencies

| Package | Role |
|---------|------|
| `isar` + `isar_flutter_libs` (3.1.x) | Local-first on-device database (source of truth) |
| `flutter_riverpod` (2.5.x) | State management + dependency injection |
| `go_router` (14.x) | Declarative navigation + auth/onboarding redirect |
| `firebase_core` / `firebase_auth` (3.x / 5.x) | Initialisation + authentication |
| `cloud_firestore` (5.x) | Optional single-doc encrypted backup only |
| `google_sign_in` | Google auth provider |
| `flutter_local_notifications` (17.x) + `timezone` | Habit reminders |
| `share_plus` (10.x) / `file_picker` (8.x) | Local backup export / import |
| `encrypt` + `crypto` | AES-256-CBC backup encryption (SHA-256 KDF) |
| `freezed` + `json_serializable` | Immutable models + JSON codegen |
