# Verification Status

Single source of truth for what is **done in code** vs **proven to work**. The
authoring environment had no Dart/Flutter SDK, so the right-hand columns are
honestly empty until someone runs the gates in `docs/CODESPACES_VALIDATION.md`.

## Legend
- ✅ Implemented (code written, all layers)
- 🧪 Test authored (not yet run)
- ⏳ Requires Codespaces/toolchain verification
- 🔧 Requires native config / credentials

## Matrix

| Area | Implemented | Test authored | Verified (run) |
|------|:-----------:|:-------------:|:--------------:|
| Domain models (freezed + plain) | ✅ | — | ⏳ |
| Isar entities + mappers | ✅ | 🧪 (enum_mapping) | ⏳ |
| Repository impls (habit/log/insight/progress/settings) | ✅ | — | ⏳ |
| Firebase auth repository | ✅ | — | ⏳ 🔧 |
| Backup repo + encryption | ✅ | 🧪 (encryption) | ⏳ |
| ConsistencyCalculator | ✅ | 🧪 | ⏳ |
| InsightEngine | ✅ | 🧪 | ⏳ |
| ProgressiveDisclosureService | ✅ | 🧪 | ⏳ |
| StreakCalculator | ✅ | 🧪 | ⏳ |
| ProductivityCalculator | ✅ | 🧪 | ⏳ |
| AnalyticsService | ✅ | 🧪 | ⏳ |
| PremiumService | ✅ | 🧪 | ⏳ |
| date_utils | ✅ | 🧪 | ⏳ |
| Riverpod providers/controllers | ✅ | — | ⏳ |
| go_router + redirect | ✅ | — | ⏳ |
| Screens (17) | ✅ | — | ⏳ |
| Widgets | ✅ | 🧪 (widget_test) | ⏳ |
| Notifications | ✅ | — | ⏳ 🔧 |

## Toolchain gates (none run yet)

| Gate | Status |
|------|--------|
| `flutter pub get` | ⏳ not run |
| `dart run build_runner build` | ⏳ not run |
| `flutter analyze` | ⏳ not run |
| `flutter test` (11 suites) | ⏳ not run |
| `flutter build apk/appbundle` | ⏳ 🔧 not run (needs native config) |

## Native config gates

| Item | Status |
|------|--------|
| Firebase Android API key | 🔧 placeholder in `firebase_options.dart` |
| Application id (real) | 🔧 still `com.example.habitview` |
| `google-services.json` + SHA-1 | 🔧 not added |
| Firebase App Check | 🔧 not enabled |

## How to update this file

After running the gates, change ⏳ → ✅ **with the command output recorded** (in
the PR / commit message), or file the failure. Do not mark a row verified without
evidence.
