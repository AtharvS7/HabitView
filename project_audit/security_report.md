# Security Report — HabitView

_Audit date: 2026-06-17_

Severity: 🔴 critical · 🟠 high · 🟡 medium · 🔵 low/informational

The app is pre-functional, so most findings are about the **security posture of
the backend design** that will bite the moment Firestore and auth are wired up.

---

## 🔴 SEC-01 — No Firestore security rules in the repository
There is no `firestore.rules`, `firebase.json`, or `.firebaserc` anywhere in the
project. That means access control is whatever was last set in the Firebase
console — typically either:
- **Test mode** (`allow read, write: if true`) → the entire database is publicly
  readable and writable by anyone with the project's (public) API key. All users'
  habits, logs, moods, and notes are exposed.
- **Locked mode** → all client access denied, app appears broken.

Either way, rules are undefined-in-repo and unversioned. **This is the single
biggest security risk.**
**Fix:** add a `firestore.rules` file enforcing per-user ownership, e.g.
`allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;`
and version it. Validate writes against the schema.

## 🔴 SEC-02 — No authentication, but data is per-user
Every model carries a `userId` (`Habit.userId` `habit.dart:57`,
`HabitLog.userId`, `Insight.userId`, `UserProgress.userId`) implying per-user
data isolation. Yet there is **no `firebase_auth` dependency** and no auth code
(`login_screen.dart`/`register_screen.dart` are empty). Without authentication,
`request.auth` is null and ownership rules (SEC-01) cannot be enforced — the only
options are "open to all" or "closed to all."
**Fix:** add `firebase_auth`, gate the app behind sign-in, and derive `userId`
from `FirebaseAuth.instance.currentUser.uid` rather than trusting client input.

## 🟠 SEC-03 — `userId` is client-supplied and unvalidated
Because services and (future) repositories build documents from client-side
`userId` strings, a malicious client could write documents tagged with another
user's id unless rules forbid it. The data model trusts the client.
**Fix:** in security rules, require `request.resource.data.userId ==
request.auth.uid` on create/update; never let the client choose an arbitrary
owner id.

## 🟠 SEC-04 — No input validation anywhere
No validation exists on any model field. Once UI/repos are built, free-text
fields (`Habit.name`, `HabitLog.notes`, `skipReasonCustom`, `Habit.trigger`) and
bounded fields (`difficulty` 1–5, `mood` 1–5) will be written to Firestore
unchecked. Unbounded strings enable storage abuse and oversized documents;
out-of-range numerics break the scoring logic.
**Fix:** validate at the boundary (UI + repository) and re-validate in Firestore
rules (length caps, numeric ranges, enum membership).

## 🟡 SEC-05 — Firebase config will be committed once added
When `flutterfire configure` is run it generates `lib/firebase_options.dart`
(and `google-services.json` / `GoogleService-Info.plist`). These contain the
project's API keys. Firebase client API keys are *designed* to be public, so
committing them is acceptable — **but only if Firestore rules (SEC-01) are
sound**. The current `.gitignore` does not exclude these files, so they will be
committed by default.
**Action:** this is acceptable *provided* rules + App Check are in place; do not
treat the API key as a secret, and do not rely on its secrecy for security.

## 🟡 SEC-06 — No Firebase App Check
There is no App Check integration. Without it, the public API key can be used
from outside your apps to hit Firestore directly (subject only to rules).
**Fix:** enable App Check (Play Integrity / DeviceCheck / reCAPTCHA) before
launch to limit abuse.

## 🔵 SEC-07 — No secrets currently in the repo (good)
A scan for committed credentials found none (no `firebase_options.dart`, no
service-account JSON, no API keys in `web/index.html`). The repo is clean today;
the risk is entirely about what gets added next.

## 🔵 SEC-08 — Default application identifiers
`com.example.habitview` is used on Android (`android/app/build.gradle.kts`) and
iOS (`ios/Runner.xcodeproj`). The `com.example.*` namespace is a placeholder and
will be rejected by the stores; it also signals an unconfigured project.
**Fix:** set a real reverse-domain identifier before configuring Firebase
(the id is baked into the Firebase app registration).

## 🔵 SEC-09 — No crash/error reporting boundary
Not strictly security, but there is no global error handling, so unhandled
exceptions (e.g. the Timestamp cast in BUG-05) will surface raw and may leak
internal details in logs. Add a top-level error handler and consider Crashlytics.

---

## Priority order
1. SEC-02 (add auth) and SEC-01 (write + version rules) — do these together.
2. SEC-03 / SEC-04 (server-enforced ownership + validation).
3. SEC-06 (App Check), SEC-09 (error boundary) before public launch.
