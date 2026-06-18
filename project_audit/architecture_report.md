# Architecture Report — HabitView

_Audit date: 2026-06-17 · Scope: full repository, read-only_

## 1. Summary

HabitView is intended to be a habit-tracking app built on a layered ("clean
architecture") structure with Firebase/Firestore as the backend. In its current
state the project is a **scaffold**: the folder structure and a handful of
domain/business-logic files exist, but the data layer, presentation layer,
state management, dependency injection, and app composition root are **empty
placeholder files**. The app that actually runs is still the default Flutter
counter template (`lib/main.dart`).

Roughly **22 of 41 Dart source files are 0-byte stubs**.

## 2. Intended layering

The directory layout (created by `scripts/init_structure.sh`) follows a clean
layered design:

```
lib/
  core/           cross-cutting (theme, constants, utils)      [EMPTY]
  domain/         models + enums                                [IMPLEMENTED]
  data/           repositories + firebase access                [EMPTY]
  application/    services + providers (state)                  [PARTIAL]
  presentation/   screens + widgets                             [EMPTY]
  app.dart        composition root / MaterialApp                [EMPTY]
  main.dart       entry point                                   [DEFAULT TEMPLATE]
```

The dependency direction implied is `presentation → application → domain ← data`,
which is sound. The problem is that only `domain` and part of `application`
contain code.

## 3. Layer-by-layer status

### 3.1 Entry point / composition root
- `lib/main.dart:1` — still the generated counter app (`MyApp` / `MyHomePage`
  with `_incrementCounter`). It does not reference `app.dart`, Firebase, or any
  HabitView screen.
- `lib/app.dart` — **empty (0 bytes)**. There is no `MaterialApp`, router,
  theme wiring, or provider scope.
- Consequence: none of the implemented domain/service code is reachable from a
  running app.

### 3.2 Core
- `core/theme/app_theme.dart`, `core/constants/app_constants.dart`,
  `core/utils/date_utils.dart` — **all empty**. Theme is currently inline in
  `main.dart` (deep-purple seed). No central design tokens, spacing, or color
  system.

### 3.3 Domain — IMPLEMENTED
Real, generated code exists for four models:
- `domain/models/habit.dart:53` — `Habit` (+ `HabitCategory`, `ScheduleType`).
- `domain/models/habit_log.dart:51` — `HabitLog` (+ `LogStatus`, `SkipReason`).
- `domain/models/insight.dart:47` — `Insight` + `InsightAction`.
- `domain/models/user_progress.dart:47` — `UserProgress` (+ `OnboardingPhase`).

All use `freezed` + `json_serializable` and have committed `.freezed.dart` /
`.g.dart` files. Each source file retains a large commented-out earlier version
of itself above the active code — dead scaffolding noise that should be removed.

### 3.4 Data — EMPTY
- `data/firebase/firestore_service.dart` — **empty**. No central Firestore
  accessor.
- `data/repositories/habit_repository.dart`,
  `habit_log_repository.dart`, `insight_repository.dart` — **all empty**.
- `data/firebase/timestamp_mapper.dart:3` — the **only** implemented data-layer
  file: a `TimestampMapper` with `fromFirestore`/`toFirestore`. It is never
  imported or used anywhere (see Bug Report).

There is no persistence, no queries, no streams — the domain models cannot be
loaded or saved.

### 3.5 Application — PARTIAL
Services:
- `application/services/consistency_calculator.dart:4` — `ConsistencyCalculator`
  (scoring, trend). **Does not compile**: references `Habit`, `HabitLog`,
  `LogStatus`, `ScheduleType` with no `import` statements.
- `application/services/insight_engine.dart:3` — `InsightEngine` (4 rule
  heuristics). **Does not compile**: references domain types with no imports.
- `application/services/progressive_disclosure_service.dart:92` —
  `ProgressiveDisclosureService`. Compiles (imports `user_progress.dart`). Note:
  an earlier Firestore-backed version is commented out above; the active version
  is pure logic only.

Providers (state management):
- `application/providers/habit_providers.dart`,
  `insight_providers.dart`, `user_progress_provider.dart` — **all empty**.

### 3.6 Presentation — EMPTY
All screens and widgets are 0-byte stubs:
- `screens/auth/login_screen.dart`, `register_screen.dart`
- `screens/today/today_screen.dart`
- `screens/habits/habit_create_screen.dart`, `habit_edit_screen.dart`
- `screens/insights/insights_screen.dart`
- `screens/onboarding/onboarding_screen.dart`
- `widgets/habit_card.dart`, `metric_card.dart`, `insight_card.dart`,
  `skip_reflection_sheet.dart`

There is no UI for HabitView at all.

## 4. State management

**None present.** The `application/providers/` folder name implies Riverpod or
`provider`, but `pubspec.yaml` declares no state-management package
(`flutter_riverpod`, `provider`, `bloc`, `get_it`, `injectable` are all absent),
and all three provider files are empty. There is no DI container, no
`ProviderScope`/`MultiProvider`, and no app-level state wiring. This is a
foundational decision that has not yet been made or implemented.

## 5. Repositories & services

- **Repositories:** intended (3 files) but entirely unimplemented. There is no
  abstraction over Firestore, so services would have to talk to Firestore
  directly (as the commented-out `ProgressiveDisclosureService` once did).
- **Services:** business logic exists and is reasonably structured, but is
  (a) not compilable in two of three files, and (b) disconnected from any data
  source and any UI.

## 6. Cross-cutting observations

- **Naming drift:** `scripts/init_structure.sh:3` calls the project
  "HabitVault"; `pubspec.yaml` name is `habitview`; description is still
  "A new Flutter project." README is the default template.
- **Generated code committed:** `.freezed.dart`/`.g.dart` are committed (fine),
  but the models also carry large commented dead blocks.
- **Platform identifiers are defaults:** `com.example.habitview` on Android
  (`android/app/build.gradle.kts`) and iOS (`ios/Runner.xcodeproj`).

## 7. Architectural risks / recommendations

1. Pick and add a state-management/DI approach (Riverpod recommended given the
   `providers/` layout) before building UI.
2. Implement `data/` (a single `FirestoreService` + repositories) so the domain
   models have a source of truth; route services through repositories rather
   than touching Firestore directly.
3. Build a real composition root in `app.dart` and call it from `main.dart`
   after `Firebase.initializeApp`.
4. Remove dead commented code from the model files and the scaffold noise.
5. Establish the dependency rule explicitly (domain depends on nothing;
   application depends on domain; data implements domain-facing interfaces;
   presentation depends on application).

See `missing_features.md` for the implementation gap inventory and
`production_readiness.md` for deployment blockers.
