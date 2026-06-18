# HabitView — Session State

> Working handoff document. Read this first when resuming after a context clear.
> **Last updated 2026-06-18: Phases 1–6 complete in code.** All screens written
> (Phase 5 done), tests authored, docs rewritten for Isar local-first,
> `.devcontainer/` added, `final_audit/` + root reports generated. Remaining work
> is toolchain verification + native config only — see
> `docs/CODESPACES_VALIDATION.md` and `RELEASE_CHECKLIST.md`. Nothing has been
> compiled or test-run (no SDK here). Not git-init'd (awaiting user approval).

## Environment reality check (IMPORTANT)

- **Actual working dir:** `/d/AI/Projects/HabitView` (Git Bash on Windows; the
  CLAUDE.md `D:\AI\Projects\HabitView` path is the same place).
- **Flutter/Dart are NOT installed** on this machine (`which flutter` → not
  found). Therefore in this environment we **cannot**:
  - run `flutter pub get`
  - run `dart run build_runner build` (so `*.g.dart` for new Isar entities and
    any new freezed models **do not exist yet**)
  - run `flutter analyze` or `flutter test`
- **Not a git repo yet** (`git status` → fatal). Do NOT `git init` / push until
  the user explicitly approves at the very end.
- Consequence: all new code is **written-to-compile**, not compile-verified.
  The final report MUST separate **Implemented / Statically-verified /
  Requires-Codespaces-verification** and must NOT claim builds or tests passed.

## Two decisions the user locked in (via AskUserQuestion)

1. **Data architecture = Isar local-first** (mission spec wins over the old
   Firestore-centric docs/CLAUDE.md). Rules:
   - Isar is the primary DB; all habit/log/insight/progress/settings data local.
   - Fully offline-first.
   - Firebase = **authentication only** (email/password + Google) + **optional,
     opt-in, disabled-by-default** encrypted cloud backup/sync (single snapshot
     doc per user, never per-habit writes — keep Firebase cost ~0).
   - Update any conflicting docs/CLAUDE.md/stubs to match.
2. **Execution = full autonomous end-to-end** (all phases in one run, no review
   checkpoints), then final audit + reports. Document assumptions as we go.

## Architectural decisions made

- Clean architecture, dependency rule `presentation → application → domain ← data`.
- Riverpod (flutter_riverpod, plain providers + AsyncNotifier controllers).
- go_router with `StatefulShellRoute.indexedStack` bottom-nav shell + redirect
  driven by auth state and `onboardingCompleted` settings flag.
- Isar entities store enums as `.name` strings; enum↔domain mapping lives in
  `data/local/mappers/` (keeps Isar generator ignorant of domain enums and keeps
  on-disk/backup data stable across enum reordering).
- Domain models stay as the EXISTING committed freezed models — **not edited**.
  We rely on their generated `copyWith`/`toJson`/`fromJson`. New plain models
  (`AppUser`, `AppSettings`) are hand-written (no codegen) to avoid needing
  build_runner for them.
- All Firebase Auth confined to `data/auth/firebase_auth_repository.dart`; errors
  translated to typed `AuthException` (see `core/error/app_exception.dart`).
- Premium gating via `PremiumService(isPremium)` sourced from a local
  `AppSettings.premiumUnlocked` flag — payment-provider-agnostic by design.
- Backup encryption: AES-256-CBC, key = SHA-256(passphrase) (documented as
  upgrade-to-Argon2/GCM in security audit).

## Completed phases

- **Phase 1 — Foundation:** ✅
  - `pubspec.yaml` rewritten: added isar, isar_flutter_libs, flutter_riverpod,
    go_router, firebase_core, firebase_auth, google_sign_in, cloud_firestore
    (5.x line), flutter_local_notifications, timezone, flutter_timezone, uuid,
    intl, path_provider, crypto, encrypt, share_plus, file_picker; dev:
    isar_generator, build_runner, freezed, json_serializable. Added
    `assets/` dir + `flutter: assets:`.
  - `lib/firebase_options.dart` — real project ids (habitview-1574c, appId,
    senderId 76750004118); **Android apiKey is a placeholder**
    `REPLACE_WITH_ANDROID_API_KEY` (must be set via `flutterfire configure` or
    pasted before release). Android-only; other platforms throw.
  - `lib/core/constants/app_constants.dart` — repurposed for Isar/local +
    premium limits (freeMaxActiveHabits=10, analytics windows, backup, channel).
  - `lib/core/error/app_exception.dart` — sealed AppException + Auth/Storage/
    Backup/PremiumRequired/Validation.
  - `lib/core/theme/app_theme.dart` — expanded M3 component theming.
  - `analysis_options.yaml` — exclude `*.g.dart`/`*.freezed.dart`, ignore
    invalid_annotation_target.
  - `.gitignore` — added firebase secrets, *.habitview backups.
  - `assets/README.md` placeholder.
- **Phase 2 — Domain:** ✅
  - Models: `domain/models/app_user.dart`, `domain/models/app_settings.dart`
    (+ `AppThemeMode` enum).
  - Repository interfaces in `domain/repositories/`: auth, habit, habit_log,
    insight, user_progress, settings, backup (+ `BackupImportResult`).
- **Phase 3 — Data layer:** ✅
  - Isar entities (`data/local/entities/`): habit, habit_log (composite unique
    index habitId+date), insight, user_progress, settings (singleton id 0).
    Each has `part '*.g.dart'` — **needs build_runner**.
  - `data/local/isar_service.dart` — opens single instance, lists schemas
    (HabitEntitySchema, etc. — generated symbols).
  - Mappers (`data/local/mappers/`): enum_mapping, habit, habit_log, insight,
    user_progress, settings.
  - Repo impls (`data/repositories/`): habit, habit_log, insight, user_progress,
    settings — all Isar-backed.
  - `data/auth/firebase_auth_repository.dart`.
  - `data/backup/backup_repository_impl.dart` — local JSON export/import +
    file export + optional Firestore single-doc cloud backup/restore with
    optional encryption.
  - `core/services/encryption_service.dart`.
  - Deleted the 4 empty legacy stubs (firestore_service.dart + 3 old repo
    stubs). Kept `data/firebase/timestamp_mapper.dart` (still present).
- **Phase 4 — Services + providers:** ✅
  - Services (`application/services/`): schedule_utils, streak_calculator,
    productivity_calculator, analytics_service, premium_service. (Existing
    consistency_calculator, insight_engine, progressive_disclosure_service
    untouched.)
  - `core/services/notification_service.dart`.
  - Providers (`application/providers/`): app_providers (isar override, repos,
    services), auth_providers (authState, currentUserId, AuthController),
    settings_providers, premium_providers, habit_providers (HabitController),
    habit_log_providers (LogController, todayLogsByHabit, logsByHabit),
    user_progress_provider, analytics_providers, insight_providers
    (InsightController.regenerate).
  - Added `watchLogsForUser` to log repo interface + impl.

## Remaining phases — ALL COMPLETE IN CODE (2026-06-18)

- **Phase 5 — screens:** ✅ all 17 screens written; router imports resolve.
- **Phase 6 — tests/docs/audit/release:** ✅
  - Tests: 11 suites authored (services, mappers, encryption, date_utils, widget).
  - Docs rewritten for Isar local-first: `FEATURES.md`, `PRODUCTION_READINESS.md`
    (others were already current); added `docs/CODESPACES_VALIDATION.md`.
  - `.devcontainer/` (devcontainer.json + setup.sh) for Codespaces verification.
  - `final_audit/` — README, security_audit, code_audit, architecture_review,
    VERIFICATION_STATUS.
  - Root reports: `PROJECT_COMPLETION_REPORT.md`, `RELEASE_CHECKLIST.md`.
  - `firestore.rules` already has the owner-only `backups/{uid}` rule.
- **Only outside-code work left:** run the toolchain gates (Codespaces) + native
  Firebase/app-id config. See `RELEASE_CHECKLIST.md` section A & B.

## (historical) Phase 5 detail when it was in progress

- **Phase 5 — Navigation/screens/widgets:** IN PROGRESS.
  - ✅ Done: `presentation/router/app_routes.dart`, `app_router.dart`;
    `lib/app.dart` (MaterialApp.router + themeMode), `lib/main.dart`
    (Firebase.initializeApp + Isar open + notifications init + ProviderScope
    overrides).
  - ✅ Widgets done: category_visuals, metric_card, habit_card, insight_card,
    skip_reflection_sheet, async_value_view (+ EmptyState).
  - ❌ **Screens NOT yet written** — the router imports them so they MUST be
    created or the app won't compile. Required files (all currently 0-line stubs
    or missing):
    - `screens/splash/splash_screen.dart`  (MISSING — create)
    - `screens/auth/login_screen.dart`     (stub — overwrite)
    - `screens/auth/register_screen.dart`  (stub — overwrite)
    - `screens/auth/forgot_password_screen.dart` (MISSING — create)
    - `screens/onboarding/onboarding_screen.dart` (stub — overwrite)
    - `screens/home/home_shell.dart`       (MISSING — create; uses
      StatefulNavigationShell)
    - `screens/today/today_screen.dart`    (stub — overwrite)
    - `screens/dashboard/dashboard_screen.dart` (MISSING — create)
    - `screens/insights/insights_screen.dart` (stub — overwrite)
    - `screens/habits/habit_create_screen.dart` (stub — overwrite)
    - `screens/habits/habit_edit_screen.dart`   (stub — overwrite)
    - `screens/habits/habit_detail_screen.dart` (MISSING — create)
    - `screens/settings/settings_screen.dart`   (MISSING — create)
    - `screens/settings/account_screen.dart`    (MISSING — create)
    - `screens/settings/backup_screen.dart`     (MISSING — create)
    - `screens/settings/notification_settings_screen.dart` (MISSING — create)
    - `screens/settings/premium_screen.dart`    (MISSING — create)
- **Phase 6 — Tests/docs/audit/release:** NOT STARTED.
  - Tests: streak_calculator, productivity_calculator, analytics_service,
    premium_service, mappers, encryption_service. Existing tests
    (consistency/insight/progressive/date_utils) should still pass. NOTE:
    `test/widget_test.dart` likely references the old launch shell and will need
    updating for the new router/ProviderScope.
  - Rewrite `CLAUDE.md`, `docs/*` (ARCHITECTURE, SETUP, FEATURES, TESTING,
    DEPLOYMENT, PRODUCTION_READINESS), `README.md`, `RESUME_SUMMARY.md` for
    Isar local-first.
  - Generate `final_audit/` reports (10 files listed in CLAUDE.md
    post_completion_audit), PROJECT_COMPLETION_REPORT.md, RELEASE_CHECKLIST.md,
    PORTFOLIO_SUMMARY.md, RESUME_PROJECT_SUMMARY.md.
  - Add `.devcontainer/` for Codespaces + a Codespaces validation guide.
  - Consider deleting/var-checking old `firestore.rules`/indexes relevance
    (now only used for optional `backups/{userId}` doc — should add a rule for
    that collection).

## Pending tasks / known follow-ups

- **Android native config not done:** package name still `com.example.habitview`
  in `android/` — must change to `com.atharvsawane.habitview`; add
  `google-services.json`, Google Sign-In SHA-1, Gradle Firebase plugin,
  notification permission, minSdk for Isar/notifications. (Codespaces/native.)
- `firestore.rules` should get a `backups/{userId}` owner-only rule; the old
  habits/logs/insights/user_progress rules are now unused (local-first) — note
  in docs rather than silently delete, or trim with explanation.
- Verify Isar generated query accessors match naming used in repo impls
  (e.g. `_isar.habitEntitys`, `.filter().userIdEqualTo(...)`,
  `sortByConfidenceDesc`, `watchObject`). These assume default Isar codegen
  pluralization (`habitEntitys`). **Confirm after build_runner** — if the
  generated collection accessor differs, repo impls need adjusting.
- `share_plus`/`file_picker` imported in pubspec but wiring into Backup screen
  still to do in Phase 5.

## Assumptions made (document in final report)

- Free tier: 10 active habits, 30-day analytics window; premium: unlimited +
  365-day window. Custom categories premium-only (free uses 5 built-ins).
- Single device-local settings row (settings are per-device, not per-user).
- Streak grants "today grace": today unlogged doesn't break the current streak.
- Productivity score = difficulty-weighted completion ratio over window.
- Cloud backup encryption optional; passphrase-based; SHA-256 KDF + AES-CBC.
- Email verification sent on register (not enforced as a gate).

## Next recommended action

Resume **Phase 5**: create all the screen files listed above (they are imported
by `app_router.dart`, so the project will not compile until they exist). Build
order suggestion: splash → home_shell → auth (login/register/forgot) →
onboarding → today → dashboard → insights → habit create/edit/detail →
settings (settings/account/backup/notifications/premium). Then move to Phase 6
(tests, docs rewrite, final_audit, Codespaces devcontainer). Do not git
init/push without explicit user approval.
