# Missing & Unfinished Features — HabitView

_Audit date: 2026-06-17_

This inventory lists what the scaffold implies the product should do versus what
actually exists. Status legend: ✅ implemented · 🟡 partial / broken · ⛔ empty
stub · ❌ not present at all.

## 1. Empty stub files (0 bytes)

These files exist only as placeholders created by `scripts/init_structure.sh`:

| File | Purpose | Status |
|------|---------|--------|
| `lib/app.dart` | App composition root / `MaterialApp` | ⛔ |
| `lib/core/theme/app_theme.dart` | Theme tokens | ⛔ |
| `lib/core/constants/app_constants.dart` | Constants | ⛔ |
| `lib/core/utils/date_utils.dart` | Date helpers | ⛔ |
| `lib/data/firebase/firestore_service.dart` | Firestore access | ⛔ |
| `lib/data/repositories/habit_repository.dart` | Habit CRUD | ⛔ |
| `lib/data/repositories/habit_log_repository.dart` | Log CRUD | ⛔ |
| `lib/data/repositories/insight_repository.dart` | Insight persistence | ⛔ |
| `lib/application/providers/habit_providers.dart` | Habit state | ⛔ |
| `lib/application/providers/insight_providers.dart` | Insight state | ⛔ |
| `lib/application/providers/user_progress_provider.dart` | Progress state | ⛔ |
| `lib/presentation/screens/auth/login_screen.dart` | Login UI | ⛔ |
| `lib/presentation/screens/auth/register_screen.dart` | Register UI | ⛔ |
| `lib/presentation/screens/today/today_screen.dart` | Daily tracking UI | ⛔ |
| `lib/presentation/screens/habits/habit_create_screen.dart` | Create habit | ⛔ |
| `lib/presentation/screens/habits/habit_edit_screen.dart` | Edit habit | ⛔ |
| `lib/presentation/screens/insights/insights_screen.dart` | Insights UI | ⛔ |
| `lib/presentation/screens/onboarding/onboarding_screen.dart` | Onboarding | ⛔ |
| `lib/presentation/widgets/habit_card.dart` | Habit list item | ⛔ |
| `lib/presentation/widgets/metric_card.dart` | Metric tile | ⛔ |
| `lib/presentation/widgets/insight_card.dart` | Insight tile | ⛔ |
| `lib/presentation/widgets/skip_reflection_sheet.dart` | Skip reason sheet | ⛔ |

**22 empty files.**

## 2. Feature-by-feature status

### Authentication ❌
- Login/register screens are empty stubs.
- **No `firebase_auth` dependency** in `pubspec.yaml`.
- No auth state, no session handling, no route guarding.
- Models carry `userId` everywhere (`Habit.userId`, `HabitLog.userId`, …) but
  nothing produces or enforces a user identity.

### Onboarding / progressive disclosure 🟡
- `ProgressiveDisclosureService` (`application/services/progressive_disclosure_service.dart:92`)
  implements phase logic (`trackingOnly` → `basicStats` → `insightsEnabled`).
- But: no UI (`onboarding_screen.dart` empty), no persistence (the
  Firestore-backed version is commented out), and the service isn't wired to
  anything.

### Habit creation / editing ❌
- `Habit` model exists; create/edit screens are empty; no repository to save to.

### Daily tracking ("Today") ❌
- `today_screen.dart` empty. No way to view today's habits or log
  done/skipped. `HabitLog` model exists but is unreachable.

### Skip reflection ❌
- `skip_reflection_sheet.dart` empty. `SkipReason` enum and `HabitLog.skipReason`
  exist but no UI captures them.

### Consistency scoring 🟡
- `ConsistencyCalculator` (`application/services/consistency_calculator.dart:4`)
  is implemented but **does not compile** (missing imports) and is not surfaced
  in any UI. See `bug_report.md`.

### Insights engine 🟡
- `InsightEngine` (`application/services/insight_engine.dart:3`) implements four
  heuristic rules but **does not compile** (missing imports), has no persistence
  (`insight_repository.dart` empty), and no UI (`insights_screen.dart` empty).

### Metrics / stats dashboard ❌
- `metric_card.dart` empty; no aggregation surface, no charts.

### Notifications / reminders ❌
- `Habit` has `trigger`, `timeWindowStart/End`, but there is no notification
  package (e.g. `flutter_local_notifications`) and no scheduling logic.

## 3. Wholly absent capabilities (no dependency, no code)

- ⛔ Firebase initialization (`Firebase.initializeApp`) — see `firebase_report.md`.
- ❌ Authentication (`firebase_auth`).
- ❌ Local notifications / reminders.
- ❌ Routing (`go_router`/`Navigator 2.0`) — no router declared.
- ❌ State management / DI (Riverpod, provider, bloc, get_it).
- ❌ Charts/visualization for insights & metrics.
- ❌ Offline/empty/error UI states.
- ❌ Settings / profile / sign-out.
- ❌ Analytics / crash reporting.
- ❌ Localization (i18n).

## 4. Recommended build order

1. Add and configure Firebase (`firebase_core` + `flutterfire configure`).
2. Add state management + DI (Riverpod) and routing (go_router).
3. Implement `FirestoreService` + repositories.
4. Fix the two non-compiling services (add imports) and wire them through
   repositories.
5. Build `app.dart` and replace `main.dart`.
6. Implement auth (add `firebase_auth`) → onboarding → today → create/edit →
   insights/metrics.
7. Add reminders, settings, and empty/error states last.
