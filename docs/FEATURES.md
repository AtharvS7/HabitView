# Features

Legend: ✅ implemented end-to-end (UI + logic) · 🟢 logic implemented & unit-tested
· ⚪ optional / opt-in · ⛔ planned / future

> **Verification note:** "implemented" here means the code is written across the
> domain → data → application → presentation layers. It is **statically written
> but not compile-verified** (the authoring environment had no Flutter SDK).
> Run the gates in `docs/CODESPACES_VALIDATION.md` to confirm.

## Habit tracking ✅
- Model: `Habit` with category, schedule (daily or specific weekdays), optional
  time window, difficulty (1–5), trigger, active/paused state.
- Daily logging via `HabitLog` (done / skipped), keyed by the local calendar day
  (`'YYYY-MM-DD'` day keys, `core/utils/date_utils`).
- UI: `today_screen` (log/skip), `habit_create_screen`, `habit_edit_screen`,
  `habit_detail_screen`, shared `habit_form` widget and `habit_card`.
- Persistence: Isar (`HabitEntity` / `HabitLogEntity`, composite unique index
  `habitId+date`) via `HabitRepository` / `HabitLogRepository` impls.

## Skip reflection ✅
- `HabitLog` captures a `SkipReason` (too tired, too busy, forgot, low
  motivation, custom), optional custom text, optional mood (1–5) and notes.
- UI: `skip_reflection_sheet` bottom sheet.
- Feeds the skip-pattern insight.

## Consistency score 🟢
A 0–100 score over a rolling window:
- 60% raw completion (completed ÷ scheduled-expected days)
- 40% recency-weighted completion (recent days weighted higher)
- Trend (improving / stable / declining) from first-half vs second-half rates,
  with the real percentage-point delta.
- Human-readable `message` and `trendText`.

Source: `application/services/consistency_calculator.dart` · tested in
`test/application/services/consistency_calculator_test.dart`.

## Behavioural insights ✅
Top-3 ranked, confidence-gated insights from four rules, surfaced on the
`insights_screen` via `insight_card` and regenerated through `InsightController`.

| Rule | Fires when | Example |
|------|-----------|---------|
| Time preference | A time-of-day slot clearly outperforms | "You're 24% more consistent in the morning" |
| Difficulty mismatch | Difficulty ≥ 4 and < 50% recent completion | "This habit might be too ambitious" (+ action to reduce difficulty) |
| Skip pattern | One reason ≥ 40% of skips | "60% of skips are due to lack of time" |
| Recovery strength | ≥ 75% completion right after a skip | "You bounce back well from missed days" |

Confidence is clamped to 0–0.95; insights below 0.6 are dropped.

Source: `application/services/insight_engine.dart` · tested in
`test/application/services/insight_engine_test.dart`.

## Metrics dashboard ✅
`dashboard_screen` shows aggregated `DashboardStats` (streaks, productivity,
consistency, completion) built by `AnalyticsService` from `StreakCalculator`,
`ProductivityCalculator`, and `ConsistencyCalculator`, rendered via `metric_card`.

## Progressive onboarding 🟢
New users aren't shown analytics until they're useful:
- **trackingOnly** — just log habits.
- **basicStats** — after ~3 days, show simple stats.
- **insightsEnabled** — after ~8 days *and* ≥ 10 logs, show insights.

Source: `application/services/progressive_disclosure_service.dart` · tested in
`test/application/services/progressive_disclosure_service_test.dart`.

## Authentication ✅
Email/password + Google Sign-In via Firebase Auth, confined to
`data/auth/firebase_auth_repository.dart`; errors translated to typed
`AuthException`. UI: `login_screen`, `register_screen`, `forgot_password_screen`,
`account_screen`. Routing/redirect driven by auth state + onboarding flag in
`presentation/router/app_router.dart`.

> Requires the real Firebase Android API key (`firebase_options.dart` placeholder)
> and native config before it runs on a device — see `docs/CODESPACES_VALIDATION.md`.

## Persistence (local-first) ✅
**Isar is the source of truth.** All habit/log/insight/progress data lives in a
local Isar database; the app is fully offline-first. No network is required for
any core feature. Settings are device-local (`SettingsEntity` singleton).

## Cloud backup / sync ⚪ (opt-in, disabled by default)
Optional encrypted snapshot to a single Firestore document per user at
`backups/{uid}` (never per-habit writes — keeps Firebase cost ~0).
- Local JSON export/import + file export, and optional cloud backup/restore.
- Encryption: AES-256-CBC, key = SHA-256(passphrase). Upgrade path (Argon2 + GCM)
  documented in `final_audit/security_audit.md`.
- UI: `backup_screen` (wires `share_plus` / `file_picker`).

## Reminders / notifications ✅ (logic + UI; needs native permission)
`flutter_local_notifications` via `core/services/notification_service.dart`;
configured in `notification_settings_screen`. Requires the Android notification
permission / channel setup at native config time.

## Premium gating ✅
`PremiumService` gates features off a local `AppSettings.premiumUnlocked` flag
(payment-provider-agnostic). Free tier: 10 active habits, 30-day analytics
window, 5 built-in categories. Premium: unlimited habits, 365-day window, custom
categories. UI: `premium_screen`. Tested in
`test/application/services/premium_service_test.dart`.

## Future / not yet planned ⛔
Charts/graphs in the dashboard, server-side multi-device live sync, localisation,
home-screen widgets, App Check + Crashlytics hardening.
