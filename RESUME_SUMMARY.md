# HabitView — Project Summary (Resume / Portfolio)

## One-liner
A Flutter + Firebase habit tracker that turns daily logs into **behavioural
insights** — recency-weighted consistency scoring, rule-based pattern detection,
and progressive disclosure of analytics.

## Elevator pitch
Most habit apps only show streaks. HabitView analyses *how* you build habits: it
computes a windowed consistency score, detects your best time of day, flags
habits that are too ambitious, surfaces your dominant skip reason, and recognises
when you recover well from misses — revealing each insight only once there's
enough data to trust it.

## What it demonstrates
- **Layered/clean architecture** with a strict inward dependency rule
  (`presentation → application → domain ← data`), keeping business rules
  framework-free and unit-testable.
- **Immutable domain modelling** with `freezed` + `json_serializable`.
- **Non-trivial algorithms**: a 60/40 raw-vs-recency consistency score with
  trend analysis, and a confidence-ranked, multi-rule insight engine.
- **Product thinking**: progressive disclosure so analytics appear only when
  meaningful.
- **Backend security**: per-user Cloud Firestore rules with server-side schema
  validation, plus indexes — versioned in the repo.
- **Testing**: deterministic unit tests for all business logic.
- **Documentation**: setup, architecture, features, testing, and deployment guides.

## Suggested resume bullets
> Use these once the corresponding work is finished and verified (`flutter test`
> green, app running against Firebase).

- Built a cross-platform Flutter (Material 3) habit-tracking app on a layered
  architecture with `freezed` domain models and Cloud Firestore.
- Designed a recency-weighted consistency-scoring algorithm and a confidence-ranked,
  rule-based insight engine (time-of-day, difficulty, skip-reason, recovery).
- Secured per-user data with Firebase Auth and versioned Firestore security rules
  enforcing server-side ownership and schema validation.
- Wrote deterministic unit tests for the scoring/insight logic and authored full
  setup/architecture/deployment documentation.

## Honest status (June 2026)
Domain models, business logic, security rules, tests, and docs are complete. The
data layer, UI, auth, and Firebase project configuration are the remaining build
phase — fully specified in [`docs/`](docs/). The most resume-impactful next step
is finishing one end-to-end vertical slice (sign in → create habit → log → see
score) so the project is demonstrably runnable.

## Tech stack
Flutter · Dart 3 · Material 3 · Cloud Firestore · `freezed`/`json_serializable`.
Planned: Riverpod (state/DI), go_router (navigation), Firebase Auth.

## Links to include
- Live demo / screenshots (after the UI phase)
- `docs/ARCHITECTURE.md` for the design write-up
- `project_audit/` to show a rigorous self-review process
