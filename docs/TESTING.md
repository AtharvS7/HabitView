# Testing Report & Strategy

## How to run

```bash
flutter test                                   # all tests
flutter test test/application                  # a directory
flutter test test/application/services/insight_engine_test.dart   # one file
flutter test --plain-name "returns at most three insights"        # by name
flutter test --coverage                        # writes coverage/lcov.info
```

> **Execution note:** these tests were authored in an environment **without a
> Dart/Flutter toolchain installed**, so they have not yet been executed here.
> They are written against the public APIs of the implemented code and are
> expected to pass once `flutter test` is run in a normal Flutter environment.
> This is the first thing to verify after cloning.

## What is covered

| Suite | File | Focus |
|-------|------|-------|
| Consistency scoring | `test/application/services/consistency_calculator_test.dart` | window/expected-days math, completed counting, trend = stable + steady text, divide-by-zero safety, score-band message |
| Insight engine | `test/application/services/insight_engine_test.dart` | min-data gate, difficulty-mismatch rule + action, confidence clamped to ≤ 0.95, no "null" in titles, top-3 cap |
| Progressive disclosure | `test/application/services/progressive_disclosure_service_test.dart` | all phase transitions and the stats/insights gates |
| Date utilities | `test/core/utils/date_utils_test.dart` | day-key formatting, round-trip, same-day |
| App shell (widget) | `test/widget_test.dart` | app boots into the HabitView launch screen |

These directly verify the bug fixes from the audit: confidence overflow
(BUG-06), `null` skip label (BUG-07), divide-by-zero in trend text (BUG-08/09),
and log-ordering determinism (BUG-10).

## Test design notes

- Business-logic tests use plain model objects — no Firebase, no widgets — so
  they run fast and deterministically.
- Date-sensitive tests avoid the exact window-boundary days (which depend on the
  current time of day) and assert ranges where a boundary could shift a value.

## Gaps / next tests to add (with the data + UI layers)

- **Repository tests** against the Firestore emulator (or `fake_cloud_firestore`),
  including the `TimestampMapper` round-trip.
- **Provider/state tests** once Riverpod is wired.
- **Widget tests** for each screen (today, create/edit, insights, onboarding).
- **Integration tests** (`integration_test/`) for the core flow:
  sign in → create habit → log → see score/insight.
- **Security-rules tests** with `@firebase/rules-unit-testing`.
- Add a coverage gate in CI once the above land.
