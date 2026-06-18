# Compilation Risk Report

Honest assessment of what could fail when HabitView is first compiled in a real
toolchain. The code is **written-to-compile, not compile-verified** (no
Dart/Flutter SDK in the authoring environment). Risks are ordered by probability ×
impact and tagged with the fix.

> No `flutter analyze`, `flutter test`, or build has been run. These are
> predictions, not observations.

## Risk register

### R1 — Isar generated collection-accessor names (HIGH likelihood, LOW effort)
Repo impls assume Isar's default codegen pluralisation: `_isar.habitEntitys`,
`.filter().userIdEqualTo(...)`, `sortByConfidenceDesc`, `watchObject`. If the
generator emits different symbols, `flutter analyze` reports "undefined getter/
method" at each call site.
- **Detection:** Phase 3 of `CODESPACES_EXECUTION_PLAN.md`.
- **Fix:** rename the call sites in `lib/data/local/` to the generated symbols.
  Purely mechanical; no logic changes.
- **Blast radius:** the 5 repository impls.

### R2 — freezed nullable-clear semantics (MEDIUM likelihood, LOW effort)
`copyWith(field: null)` cannot distinguish "clear" from "unchanged" in freezed.
The habit edit flow may not clear optional fields (e.g. reminder time) as
intended. Compiles fine; manifests as a behaviour bug.
- **Detection:** `flutter test` / manual edit-flow test.
- **Fix:** explicit clear path for nullable fields in `habit_edit` / `habit_form`.

### R3 — `widget_test.dart` harness drift (MEDIUM likelihood, LOW effort)
The widget test must boot the new go_router + `ProviderScope` with the same
overrides as `main()` (`isarProvider`, `notificationServiceProvider`). If it
references the old launch shell or omits an override, the test fails to pump.
- **Detection:** Phase 4.
- **Fix:** update the test to construct the real app with test overrides (e.g. a
  temp Isar instance or a fake repository).

### R4 — Provider override wiring at startup (LOW likelihood, MEDIUM effort)
`main()` overrides `isarProvider` / `notificationServiceProvider`. If an
AsyncNotifier reads a provider before its override is in place, you get a runtime
(not compile) error on first frame.
- **Detection:** app launch / widget test.
- **Fix:** ensure overrides are set in `ProviderScope` before `runApp`.

### R5 — Dependency resolution conflict (LOW likelihood, MEDIUM effort)
The Firebase + Isar + Riverpod versions are pinned to known-compatible lines and
a `pubspec.lock` is committed, but a transitive bound could still conflict on the
exact SDK present in Codespaces.
- **Detection:** Phase 1 (`flutter pub get`).
- **Fix:** keep the Firebase 3.x/5.x/5.x line aligned; adjust a single transitive
  pin if flagged.

### R6 — intl / API-surface drift (LOW likelihood, LOW effort)
`intl: ^0.19.0` and a few package APIs (e.g. `go_router`, `flutter_local_
notifications` 17.x) move between minors. A deprecated/renamed call could surface
in analyze.
- **Detection:** Phase 3.
- **Fix:** follow the analyzer's suggested replacement.

### R7 — Missing generated parts at clone time (EXPECTED, not a defect)
`*.g.dart` / `*.freezed.dart` are gitignored, so a fresh clone won't compile
until `build_runner` runs. This is the documented, intended workflow — not a bug.
- **Mitigation:** `.devcontainer/setup.sh` runs build_runner automatically.

## Probability summary

| Outcome after a focused Codespaces session | Estimate |
|--------------------------------------------|---------:|
| `build_runner` succeeds | High |
| `flutter analyze` clean after the R1 fixup | High |
| `flutter test` green after R2/R3 fixups | Moderate–High |
| `flutter build apk` (debug) without native config | Low (config-gated, expected) |

**Overall:** the dominant risk is mechanical (R1). No structural rework is
anticipated. Estimated probability of reaching a clean analyze + green tests in
one Codespaces session: **~75–85%**, with the remainder being small mechanical
fixups rather than redesign.
