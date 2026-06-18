# Résumé / Portfolio Improvements — HabitView

_Audit date: 2026-06-17_

This report covers how to evolve HabitView into a strong portfolio piece and how
to describe it credibly. **Important honesty note:** in its current state the
project is a scaffold (default counter app + a few non-compiling logic files), so
it is **not yet résumé-ready**. The items below are what to build/fix so that the
résumé claims become true.

---

## 1. What is genuinely demonstrable today

These are real and worth highlighting once the project compiles:
- **Clean layered architecture** (`core`/`domain`/`data`/`application`/
  `presentation`) with a deliberate dependency direction.
- **Immutable domain modeling** with `freezed` + `json_serializable` across four
  models (`Habit`, `HabitLog`, `Insight`, `UserProgress`).
- **Non-trivial business logic**: a recency-weighted consistency score with trend
  detection (`consistency_calculator.dart`) and a rule-based insight engine with
  four heuristics (`insight_engine.dart`).
- **Progressive-disclosure onboarding model** (phase gating in
  `progressive_disclosure_service.dart`) — a thoughtful UX concept.

## 2. Must-fix before claiming the project at all

1. **Make it compile** — add the missing imports in the two services
   (BUG-01/02).
2. **Make it run as HabitView** — implement `app.dart`, replace the counter
   `main.dart`, initialize Firebase (BUG-03/04).
3. **Ship at least one end-to-end vertical slice**: sign in → create a habit →
   log it today → see a consistency score. One complete flow beats ten stubs.
4. **Fix the Timestamp serialization bug** (BUG-05) so Firestore round-trips work.

## 3. High-impact additions that read well on a résumé

- **Authentication** (`firebase_auth`) + route guarding — shows you handle real
  user sessions and security boundaries.
- **Versioned Firestore security rules** committed to the repo — demonstrates
  backend security awareness (rare and impressive in junior portfolios).
- **State management + DI** (Riverpod recommended) — shows architectural maturity
  beyond `setState`.
- **Tests**: unit tests for `ConsistencyCalculator` / `InsightEngine` (pure logic,
  easy to test, high signal) and a couple of widget tests. Delete the stale
  counter test.
- **CI** (GitHub Actions running `flutter analyze` + `flutter test`) — a green
  badge signals professionalism.
- **Data visualization** for insights/metrics (e.g. `fl_chart`) — produces the
  screenshots that make a portfolio entry pop.
- **Offline support + optimistic UI** with Firestore persistence — concrete
  talking point about UX under poor connectivity.

## 4. Polish that turns it into a showcase

- Real branding: app name, icon, splash, and a cohesive theme in
  `core/theme/app_theme.dart`.
- A real `README` with: problem statement, screenshots/GIF, architecture
  diagram, feature list, and "how to run." Replace the template README.
- Empty/loading/error states for every screen.
- App Check + Crashlytics to show production-hardening.
- Accessibility pass (semantics labels, contrast, dynamic text).

## 5. Suggested résumé bullet points (use only once true)

Draft these to match what you actually finish:

- "Built a cross-platform habit-tracking app in Flutter using a layered
  (domain/data/application/presentation) architecture with Riverpod for state and
  DI."
- "Designed an immutable domain model with freezed/json_serializable and a
  Firestore data layer with custom Timestamp serialization."
- "Implemented a recency-weighted consistency-scoring algorithm and a rule-based
  insight engine surfacing behavioral patterns (time-of-day, difficulty,
  skip-reason, recovery)."
- "Secured per-user data with Firebase Auth and versioned Firestore security
  rules, and hardened the backend with App Check."
- "Set up CI (GitHub Actions) running analyzer and unit/widget tests."

## 6. Talking points for interviews (concept-level strengths)

- Why progressive disclosure (don't show insights until enough data exists) —
  good product thinking.
- The blend of raw vs recency-weighted scoring (60/40) — a deliberate design
  tradeoff you can defend.
- Confidence-thresholded, ranked insights (top-3) — shows judgment about not
  overwhelming users.

## 7. Priority order

1. Fix compile + run + one vertical slice (Sections 2).
2. Auth + security rules + tests (Section 3, top items).
3. Charts + polish + README + CI (Sections 3–4).
4. Then write the résumé bullets in Section 5 to match reality.

> Bottom line: the *ideas* here are résumé-worthy; the *execution* is not yet.
> Finishing one polished, tested, secured vertical slice will do more for a
> portfolio than the current breadth of empty stubs.
