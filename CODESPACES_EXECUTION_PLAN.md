# Codespaces Execution Plan

The concrete plan for verifying HabitView in GitHub Codespaces immediately after
push. The `.devcontainer/` boots the toolchain that was unavailable during
authoring; this document is the step-by-step run order, what each step proves,
and what to do when it fails.

## Phase 0 — Boot the container

1. On GitHub: **Code → Codespaces → Create codespace on `main`**.
2. The `ghcr.io/cirruslabs/flutter:stable` image starts and
   `.devcontainer/setup.sh` runs `flutter pub get` + `build_runner` automatically.
3. Wait for the terminal to print `Bootstrap complete.`

If the post-create command didn't run: `bash .devcontainer/setup.sh`.

## Phase 1 — Dependency resolution

```bash
flutter pub get
```
**Proves:** the version constraints in `pubspec.yaml` resolve together.
**Most likely issue:** a transitive conflict on the Firebase line. **Fix:** keep
`firebase_core` 3.x / `firebase_auth` 5.x / `cloud_firestore` 5.x aligned; run
`flutter pub upgrade --major-versions` only as a last resort.

## Phase 2 — Code generation (CRITICAL FIRST GATE)

```bash
dart run build_runner build --delete-conflicting-outputs
```
**Proves:** Isar entities + freezed models emit their `*.g.dart` / `*.freezed.dart`
parts. Nothing in `lib/data/local/entities/` or `lib/domain/models/` compiles
until this succeeds.
**Most likely issue:** an annotation/schema error in an entity. **Fix:** read the
generator error, correct the offending entity, re-run.

## Phase 3 — Static analysis

```bash
flutter analyze
```
**Proves:** the written-to-compile code actually type-checks.
**Highest-probability finding (see `COMPILATION_RISK_REPORT.md` R1):** Isar
generated collection-accessor names differ from the repo-impl assumptions
(`_isar.habitEntitys`, `.filter().userIdEqualTo`, `sortByConfidenceDesc`,
`watchObject`). **Fix:** rename the accessor calls in `lib/data/local/` to match
the symbols the generator actually emitted. Mechanical, not structural.

## Phase 4 — Tests

```bash
flutter test
```
**Proves:** the 11 authored suites pass.
**Most likely issue:** `test/widget_test.dart` referencing the old launch shell,
or a provider override missing in a test harness. **Fix:** update the widget test
to boot the real router + `ProviderScope` overrides.

## Phase 5 — Build (needs native config)

```bash
flutter build apk --debug
```
**Proves:** the Android toolchain assembles the app.
**Prerequisite:** Firebase Android API key + real application id +
`google-services.json` (see `RELEASE_CHECKLIST.md` §B/§C). Without these, expect a
Firebase/Gradle configuration failure — that's config, not a code defect.

## Recording outcomes

After each gate, update `final_audit/VERIFICATION_STATUS.md` (⏳ → ✅ with the
command output) or file the failure. Do not mark a gate green without evidence.

## Time/effort estimate

| Phase | Expected effort |
|-------|-----------------|
| 0–2 (boot + pub get + build_runner) | ~5–10 min, mostly download |
| 3 (analyze + fix Isar accessors) | ~15–45 min depending on accessor drift |
| 4 (test + fix widget_test) | ~10–20 min |
| 5 (build) | gated on native config — separate session |

The realistic critical path to a clean `flutter analyze` + green `flutter test`
is **one focused Codespaces session**, dominated by the Isar accessor fixup.
