# Codespaces / Dev Container Validation Guide

HabitView was authored in an environment **without a Dart/Flutter SDK**, so the
generated files (`*.g.dart` for Isar entities, `*.freezed.dart`/`*.g.dart` for
freezed models) were never built and the code is **written-to-compile, not
compile-verified**. This guide is the procedure to actually verify it in a real
toolchain.

The `.devcontainer/` in the repo root gives you that toolchain with one click.

## 1. Open the dev container

**GitHub Codespaces:** push the repo, then *Code → Codespaces → Create codespace*.
The `ghcr.io/cirruslabs/flutter:stable` image boots and
`.devcontainer/setup.sh` runs automatically.

**VS Code locally:** install the *Dev Containers* extension and run
*Dev Containers: Reopen in Container*.

`setup.sh` runs the two steps that could not run during authoring:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

If `setup.sh` did not run (or you want to re-run it):

```bash
bash .devcontainer/setup.sh
```

## 2. Verification gates (run in order)

| # | Command | Pass criteria | Notes |
|---|---------|---------------|-------|
| 1 | `flutter pub get` | resolves, no version conflicts | Firebase stack is pinned to the 3.x/5.x/5.x line — see `CLAUDE.md`. |
| 2 | `dart run build_runner build --delete-conflicting-outputs` | exits 0; `*.g.dart`/`*.freezed.dart` appear | **Do this before anything else compiles.** |
| 3 | `flutter analyze` | no errors | Warnings/infos may remain; triage them. |
| 4 | `flutter test` | all suites pass | 11 suites under `test/`. |
| 5 | `flutter build apk --debug` | builds | Needs Android config (see §4). |

## 3. The one thing to confirm right after build_runner

Isar's generated collection accessors use the generator's default
pluralisation. The repository impls in `lib/data/local/` assume names like
`_isar.habitEntitys`, `.filter().userIdEqualTo(...)`, `sortByConfidenceDesc`,
and `watchObject`. **If `flutter analyze` reports an undefined getter on the Isar
collection**, the generated accessor name differs from the assumption — adjust
the repo impls to match the generated symbol. This is the single most likely
post-generation fixup. See `CLAUDE.md` → "Data layer specifics".

## 4. Before a real auth / device run (not required for analyze + test)

These need your credentials and native config; they are intentionally not done
in the repo:

1. **Firebase Android API key** — `lib/firebase_options.dart` ships a placeholder
   `REPLACE_WITH_ANDROID_API_KEY`. Run `flutterfire configure` (or paste the key)
   for the `habitview-1574c` project.
2. **Application id** — still `com.example.habitview` in `android/`. Change to the
   real id before Firebase registration / store submission, then add the matching
   `google-services.json` and the Google Sign-In SHA-1.
3. **Gradle / native** — Firebase Gradle plugin, notification permission, and the
   minSdk required by Isar + `flutter_local_notifications`.

See `docs/SETUP.md` and `docs/DEPLOYMENT.md` for the full procedure.

## 5. Recording results

After running the gates, update `docs/PRODUCTION_READINESS.md` and
`final_audit/VERIFICATION_STATUS.md`: move items from
**Requires-Codespaces-verification** to **Verified** with the command output, or
file the failures. Do not mark a gate green without the command output.
