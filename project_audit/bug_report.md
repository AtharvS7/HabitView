# Bug Report — HabitView

_Audit date: 2026-06-17 · Severity: 🔴 critical · 🟠 high · 🟡 medium · 🔵 low_

Findings are from static reading only (the project was not run/compiled per
instructions). Severities reflect impact once the code is reachable.

---

## 🔴 BUG-01 — `ConsistencyCalculator` has no imports (won't compile)
**File:** `lib/application/services/consistency_calculator.dart:4`
The file begins with a comment then `class ConsistencyCalculator` and uses
`Habit`, `HabitLog`, `LogStatus`, and `ScheduleType` — but contains **zero
`import` statements**. As soon as anything references this file, analysis/compile
fails with "undefined class" errors.
**Fix:** add
`import '../../domain/models/habit.dart';` and
`import '../../domain/models/habit_log.dart';`.

## 🔴 BUG-02 — `InsightEngine` has no imports (won't compile)
**File:** `lib/application/services/insight_engine.dart:3`
Uses `Habit`, `HabitLog`, `Insight`, `InsightAction`, `SkipReason`, `LogStatus`
with no imports.
**Fix:** import `habit.dart`, `habit_log.dart`, and `insight.dart`.

## 🔴 BUG-03 — App entry point is the default counter, not HabitView
**File:** `lib/main.dart:1`
`main()` runs `MyApp` → `MyHomePage` (the increment-counter template). It never
references `app.dart` (which is empty), never initializes Firebase, and renders
none of the product. The app "works" but is the wrong app.
**Fix:** implement `app.dart` and rewrite `main.dart` to initialize Firebase and
launch the real root widget.

## 🔴 BUG-04 — Firebase never initialized
**Files:** `lib/main.dart`, whole repo
`cloud_firestore` is a dependency but `Firebase.initializeApp(...)` is called
nowhere, there is no `firebase_options.dart`, and no platform config files. Any
Firestore call will throw `[core/no-app] No Firebase App '[DEFAULT]' has been
created`. See `firebase_report.md`.

## 🟠 BUG-05 — Firestore `Timestamp` ↔ `DateTime` serialization mismatch
**Files:** generated `*.g.dart` for every model with a date field:
- `domain/models/habit.g.dart:23` (`createdAt`, `pausedAt`)
- `domain/models/habit_log.g.dart:20` (`loggedAt`, `completedAt`)
- `domain/models/insight.g.dart:21` (`generatedAt`)
- `domain/models/user_progress.g.dart:13` (`firstHabitCreatedAt`, `firstLogAt`)

`fromJson` does `DateTime.parse(json['createdAt'] as String)` and `toJson` emits
`toIso8601String()`. Firestore stores/returns `DateTime` fields as `Timestamp`
objects, **not** ISO strings. Reading a document whose date field is a
`Timestamp` will throw `type 'Timestamp' is not a subtype of type 'String'`.
A `TimestampMapper` exists (`data/firebase/timestamp_mapper.dart:3`) but is
**never wired in** — the `@JsonKey(fromJson:…, toJson:…)` converters that the
commented-out model versions had were dropped from the active models
(`habit.dart:48`, `habit_log.dart:45`, etc.).
**Fix:** add `@JsonKey` converters (or a custom `JsonConverter`) using
`TimestampMapper` on every `DateTime?` field and regenerate, OR map Timestamps
in the repository layer before calling `fromJson`.

## 🟠 BUG-06 — Insight confidence can exceed 1.0
**File:** `lib/application/services/insight_engine.dart:149`
`confidence: 0.7 + (percentage - 40) / 100` — with `percentage` up to 100 this
yields `0.7 + 0.6 = 1.3`. `confidence` is documented/treated as a 0–1 value and
sorting/threshold logic assumes that range. The time-preference rule correctly
`.clamp(0, 0.95)` (`insight_engine.dart:80`) but the skip rule does not.
**Fix:** `.clamp(0.0, 0.95)` the skip-pattern confidence.

## 🟡 BUG-07 — `SkipReason.custom` produces "due to null"
**File:** `lib/application/services/insight_engine.dart:128`
`reasonLabels` maps `tooBusy/tooTired/forgot/lowMotivation` but **omits**
`SkipReason.custom`. If the dominant skip reason is `custom`, the title becomes
`"…% of skips are due to null"`.
**Fix:** add a `custom` label or skip the insight when the top reason is custom.

## 🟡 BUG-08 — Division by zero / NaN in `trendText`
**File:** `lib/application/services/consistency_calculator.dart:133`
`trendText` computes `(completedCount / expectedCount) * 100 - 50`. When
`expectedCount == 0` (e.g. a `specificDays` habit whose scheduled days don't fall
in the window) this divides by zero → `NaN`/`Infinity`, rendering as text like
`"NaN% from last week"`.
**Fix:** guard `expectedCount == 0`.

## 🟡 BUG-09 — `trendText` reports a fabricated percentage
**File:** `lib/application/services/consistency_calculator.dart:133`
The trend *direction* is computed properly from first-half vs second-half rates
(`_calculateTrend`, line 83), but `trendText` ignores those and prints
`(completedCount/expectedCount*100) - 50`, an arbitrary expression unrelated to
"last week." The displayed delta is misleading.
**Fix:** carry the actual first/second-half rates into `ConsistencyResult` and
format the real delta.

## 🟡 BUG-10 — Services assume log ordering that isn't guaranteed
**Files:** `insight_engine.dart:88` (`logs.take(14)`),
`insight_engine.dart:160` (`for i in logs` recovery scan).
`_checkDifficultyMismatch` takes the "recent 14" via `take(14)` and the recovery
rule walks `logs` in array order, both assuming `logs` is sorted (recent-first
or chronological). Nothing in the code sorts the input. Results depend on
whatever order the (future) repository returns.
**Fix:** sort logs by `date`/`loggedAt` explicitly inside each rule.

## 🟡 BUG-11 — Recency window boundary excludes start date
**File:** `lib/application/services/consistency_calculator.dart:14`
`recentLogs` uses `logDate.isAfter(startDate)`, which excludes a log dated
exactly `startDate`, while `_getExpectedDays` (line 49) counts that day as
expected. Off-by-one inflates the denominator vs numerator for the window's first
day.
**Fix:** use `!logDate.isBefore(startDate)` for an inclusive lower bound.

## 🔵 BUG-12 — `generateWeeklyInsights` is `async` but does no async work
**File:** `lib/application/services/insight_engine.dart:4`
The method is `Future<...> async` yet contains no `await`. Harmless but
misleading; it will need real async once persistence is added.

## 🔵 BUG-13 — Large blocks of dead commented code in model files
**Files:** `habit.dart:1-46`, `habit_log.dart:1-43`, `insight.dart:1-39`,
`user_progress.dart:1-39`.
Each model duplicates an older commented-out version of itself (including the
intended `@JsonKey` timestamp converters that were never applied — see BUG-05).
Noise; should be deleted.

## 🔵 BUG-14 — Stale smoke test will fail once `main.dart` changes
**File:** `test/widget_test.dart:14`
Tests the counter (`find.text('0')`, tap `Icons.add`). The moment `MyApp`/
`main.dart` becomes the real app, this test breaks. There are no tests for the
implemented services (`ConsistencyCalculator`, `InsightEngine`,
`ProgressiveDisclosureService`), which is where tests would actually add value.

---

## Compile-blocking subset (must fix before anything runs)
BUG-01, BUG-02 (missing imports), BUG-03/BUG-04 (no real app / no Firebase init).
