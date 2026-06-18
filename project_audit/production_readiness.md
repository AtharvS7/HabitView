# Production Readiness Report — HabitView

_Audit date: 2026-06-17_

## Verdict: 🔴 NOT production-ready — pre-MVP scaffold

The repository is an early scaffold. The runnable app is the default Flutter
counter. There is no UI, no data layer, no auth, and no Firebase initialization.
The implemented business logic (two of three services) does not currently
compile due to missing imports. Substantial development is required before any
release.

---

## Deployment blockers (must fix to ship anything)

### 🔴 B-1 — No real application
`lib/main.dart:1` runs the counter template; `lib/app.dart` is empty. The product
does not exist as a runnable app. (BUG-03)

### 🔴 B-2 — Code does not compile
`consistency_calculator.dart:4` and `insight_engine.dart:3` reference domain
types with no imports. Any build that includes them fails. (BUG-01, BUG-02)

### 🔴 B-3 — Firebase not initialized / not configured
No `Firebase.initializeApp`, no `firebase_options.dart`, no platform config
files. Firestore is unreachable at runtime. (firebase_report.md)

### 🔴 B-4 — No authentication
No `firebase_auth`; per-user data cannot be isolated. (security_report.md SEC-02)

### 🔴 B-5 — No Firestore security rules in repo
Access control is undefined/unversioned — open- or closed-mode only.
(security_report.md SEC-01)

### 🔴 B-6 — Entire data + presentation layers empty
22 stub files: all repositories, all providers, all screens, all widgets.
(missing_features.md)

### 🟠 B-7 — Default app identifiers
`com.example.habitview` on Android and iOS — store-rejected and must be set
before Firebase registration. (security_report.md SEC-08)

### 🟠 B-8 — Timestamp serialization bug
Date round-trips through Firestore will throw or silently degrade. (BUG-05)

---

## Release-engineering gaps

| Area | Status | Notes |
|------|--------|-------|
| App icons / splash | ❌ | Default Flutter icons (`web/icons/*` are templates). |
| App name / branding | ❌ | `title: 'HabitView'` inline only; README is template. |
| Versioning | 🟡 | `1.0.0+1` but nothing implemented — misleading. |
| Android signing | ❌ | No release `signingConfig`/keystore configured. |
| `minSdk`/`targetSdk` | 🟡 | Flutter defaults; verify against Firebase mins. |
| iOS signing / capabilities | ❌ | Not configured. |
| CI/CD | ❌ | No workflows. |
| Crash reporting | ❌ | No Crashlytics/Sentry; no global error handler. |
| Analytics | ❌ | None. |
| Logging | ❌ | None. |
| Tests | 🔴 | Only the stale counter smoke test; no service tests. |
| `flutter analyze` clean | ❓ | Will fail given B-2; not run (read-only audit). |
| Localization | ❌ | English strings hardcoded in services. |
| Empty/error/loading UI | ❌ | No UI at all. |
| Offline support | ❌ | Firestore offline persistence not configured. |
| Accessibility | ❌ | No UI to assess. |
| Privacy policy / store metadata | ❌ | Required for stores given user data + Firebase. |

## Dependency health

- `cloud_firestore ^4.15.0` is a major version behind 5.x; plan an upgrade.
- `firebase_core` not declared directly (only transitive).
- `freezed 2.5.2` / `freezed_annotation 2.4.1` / `json_serializable 6.8.0` are a
  generation behind current but mutually consistent and fine for now.
- `flutter_lints 6.0.0` active with default rules only.
- No state-management, routing, auth, or notification packages yet.
- SDK constraint `^3.10.7` (lock: Dart `>=3.10.7 <4.0.0`, Flutter `>=3.22.0`).

## Readiness gate checklist (suggested)

- [ ] App compiles and `flutter analyze` is clean
- [ ] Real `main.dart`/`app.dart` launching the product
- [ ] Firebase initialized + configured on all target platforms
- [ ] Auth implemented and routes guarded
- [ ] Versioned, deployed Firestore rules enforcing per-user ownership
- [ ] App Check enabled
- [ ] Repositories + Firestore service implemented; Timestamp bug fixed
- [ ] Core screens implemented with empty/error/loading states
- [ ] Real app id, icons, name, signing configs
- [ ] Crash reporting + global error handler
- [ ] Unit tests for services; widget tests for key screens
- [ ] CI running analyze + tests

---

## Rough effort estimate

Given empty data + presentation layers, no auth, and no Firebase wiring, this is
**multiple weeks of work to a first usable MVP**, not a finishing pass.
Prioritize: compile fixes → Firebase/auth → data layer → core UI → hardening.
