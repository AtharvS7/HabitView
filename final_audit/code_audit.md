# Code Audit

_Per-layer review of HabitView as written. Not compile-verified (no SDK in the
authoring environment)._

## Method

Static review of `lib/` against the architecture in `docs/ARCHITECTURE.md` and
the dependency rule `presentation → application → domain ← data`. Risks are
labelled by likelihood of biting during the first real build.

## Layer-by-layer

### Domain (`lib/domain/`)
- Freezed models (`Habit`, `HabitLog`, `Insight`, `UserProgress`) + hand-written
  plain models (`AppUser`, `AppSettings`). Repository interfaces are clean and
  free of data-layer types. ✅
- **Risk (low):** freezed `copyWith(field: null)` cannot clear a nullable field
  (keeps the old value). The habit edit flow must use an explicit clear path for
  optional fields (e.g. reminder time). Verify in `habit_edit_screen` /
  `habit_form` once compiled.

### Data (`lib/data/`)
- Isar entities store enums as `.name` strings; enum↔domain mapping isolated in
  `data/local/mappers/`. Good for on-disk/backup stability. ✅
- **Risk (high — the main fixup): generated Isar accessors.** Repo impls assume
  default codegen pluralisation: `_isar.habitEntitys`,
  `.filter().userIdEqualTo(...)`, `sortByConfidenceDesc`, `watchObject`. If
  build_runner emits different symbols, `flutter analyze` will flag undefined
  getters — adjust the impls. **Check this first after build_runner.**
- `BackupRepositoryImpl`: local JSON export/import + file export + optional
  single-doc Firestore backup with optional encryption. Boundary is clean.
- `FirebaseAuthRepository`: errors mapped to typed `AuthException`. ✅
- `timestamp_mapper.dart` only relevant to the optional Firestore backup path.

### Application (`lib/application/`)
- Services are pure and unit-tested (consistency, insights, progressive
  disclosure, streak, productivity, analytics, premium). ✅
- Providers: `app_providers.dart` is the DI root; `isarProvider` /
  `notificationServiceProvider` overridden in `main()`. AsyncNotifier
  controllers for auth/habits/logs/insights.
- **Risk (low):** providers returning defaults while streams load
  (`currentSettingsProvider` → `AppSettings()`, anonymous `userProgress`). Screens
  handle the loading window via `AsyncValueView`; confirm no flash-of-default on
  first frame.

### Presentation (`lib/presentation/`)
- go_router with `StatefulShellRoute.indexedStack` + redirect on auth +
  onboarding flag (`app_router.dart`). All 17 screens present; full-screen routes
  pinned to `_rootKey`, tab routes under the shell. Router imports match screen
  files. ✅
- Widgets: `habit_card`, `metric_card`, `insight_card`, `skip_reflection_sheet`,
  `async_value_view` (+ `EmptyState`), `habit_form`, `category_visuals`.
- **Risk (low):** `test/widget_test.dart` must boot the real router +
  ProviderScope with overrides; confirm it doesn't reference the old counter
  shell.

### Core (`lib/core/`)
- `app_theme` (M3), `app_constants` (Isar collection names + premium limits),
  `date_utils` (`'YYYY-MM-DD'` keys), sealed `AppException`,
  `encryption_service`, `notification_service`. ✅

## Cross-cutting findings

| ID | Sev | Finding | Action |
|----|-----|---------|--------|
| C-1 | High | Isar generated-accessor names unverified | Run build_runner, then analyze; fix repo impls if symbols differ. |
| C-2 | Med | freezed nullable-clear semantics | Use explicit clear path for optional fields. |
| C-3 | Med | `firebase_options.dart` Android API key placeholder | `flutterfire configure` before any auth run. |
| C-4 | Med | App id `com.example.habitview` | Change before Firebase reg / store. |
| C-5 | Low | `widget_test.dart` may reference old shell | Update for new router. |
| C-6 | Low | Backup screen `share_plus`/`file_picker` wiring | Smoke-test export/import on device. |

## Post-build_runner checklist (do in order)

1. `dart run build_runner build --delete-conflicting-outputs`
2. `flutter analyze` → fix C-1 first (Isar accessors), then any freezed/null issues.
3. `flutter test` → expect the 11 suites to pass; fix `widget_test.dart` if it
   references the old launch shell.
4. Resolve C-3/C-4 before a device/auth run.

## Overall

Architecture is clean and the dependency rule holds. The dominant risk is
generated-symbol drift in the Isar layer (C-1) — mechanical to fix once the
generator has run. No structural rework anticipated.
