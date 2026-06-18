# Security Audit

_HabitView — Isar local-first architecture. Code-as-written review; not penetration-tested._

## 1. Threat model & attack surface

HabitView is local-first: all primary data lives in an on-device Isar database
and never leaves the device unless the user **opts in** to encrypted cloud
backup. This collapses most of a typical cloud app's attack surface.

| Surface | Exposure | Notes |
|---------|----------|-------|
| Local Isar DB | Device-local | Protected by OS app sandboxing; not encrypted at rest by default (see §4). |
| Firebase Auth | Network | Email/password + Google; tokens managed by the SDK. |
| Firestore `backups/{uid}` | Network, opt-in | Single per-user snapshot doc; optionally client-side encrypted. |
| Local backup files | Device/shared storage | Exported via `share_plus`/`file_picker`; optionally encrypted. |
| Notifications | Local | No network; payloads are non-sensitive. |

Firestore per-habit collections are **not written** by the shipping client, so
they are not part of the live attack surface.

## 2. Authentication

- All Firebase Auth is confined to `data/auth/firebase_auth_repository.dart`;
  the rest of the app sees only the domain `AppUser` and typed `AuthException`.
- Email verification is sent on register but **not enforced** as an access gate
  (documented assumption). Consider enforcing for sensitive operations.
- Google Sign-In requires the SHA-1 fingerprint registered in Firebase and the
  correct application id (currently the placeholder `com.example.habitview`).
- `userId` is derived from the authenticated user and used to scope data.

**Findings:** No credential is logged. No password is stored by the app (handled
by Firebase). ✅

## 3. Backup encryption (`core/services/encryption_service.dart`)

Current implementation:
- **Cipher:** AES-256-CBC, random 16-byte IV per payload, IV stored alongside
  ciphertext with a `habitview-enc-v1` marker.
- **Key derivation:** `SHA-256(passphrase)` → 32-byte key.

| Issue | Severity | Detail | Recommendation |
|-------|----------|--------|----------------|
| SEC-B1 | High | SHA-256 is a fast hash, not a KDF — offline brute-force of weak passphrases is cheap. | Replace with a memory-hard KDF (**Argon2id**) with a stored random salt + tunable cost. |
| SEC-B2 | Medium | CBC provides confidentiality but **no integrity/authentication** — ciphertext is malleable, no tamper detection. | Move to an AEAD mode (**AES-256-GCM**) so decryption fails on tampering. |
| SEC-B3 | Low | No per-backup salt; same passphrase → same key across users/devices. | Add a random salt per backup, stored with the payload (paired with SEC-B1). |
| SEC-B4 | Low | Passphrase strength is user-chosen and unvalidated. | Add a minimum-strength check / zxcvbn-style meter in `backup_screen`. |

The `v1` marker is intentionally version-tagged so a `v2` (Argon2 + GCM + salt)
can be introduced with backward-compatible decryption of old payloads.

**Upgrade path (target v2):**
```
salt        = random 16 bytes
key         = Argon2id(passphrase, salt, m=64MiB, t=3, p=1) -> 32 bytes
ciphertext  = AES-256-GCM(plaintext, key, random 12-byte nonce)  // includes auth tag
payload     = { marker: 'habitview-enc-v2', salt, nonce, ciphertext }
```

## 4. Data at rest (local)

The Isar DB is not encrypted at rest by default; it relies on OS-level app
sandboxing. For a higher bar, enable Isar's encryption (encrypted instance) or
store the DB in an OS-protected keystore-backed location. Acceptable for v1 given
the local-first, single-user-device model; document for privacy-sensitive users.

## 5. Firestore security rules (`firestore.rules`)

- Only `backups/{uid}` is read/written by the shipping client; the rule restricts
  access to `request.auth.uid == uid` (owner-only). ✅
- Legacy per-collection rules (`habits`, `habit_logs`, `insights`,
  `user_progress`) are retained but **unused** by the local-first client; they are
  owner-scoped and schema-validated, so harmless if unused. Documented in-file.
- **Recommendation:** add size/shape validation on the `backups` document
  (max size, required fields) to bound abuse, since it now carries the whole
  snapshot.

## 6. Secrets & configuration

- `lib/firebase_options.dart` contains real project ids and an **Android API key
  placeholder** — must be set via `flutterfire configure`. Firebase API keys are
  not secrets in the classic sense (they identify, not authorize), but App Check
  should be enabled to prevent abuse.
- `.gitignore` excludes `google-services.json`, key material, and `*.habitview`
  backup files. ✅
- No hard-coded credentials found in `lib/`. ✅

## 7. Recommendations (prioritised)

1. **Argon2id + AES-GCM + per-backup salt** for backup encryption (SEC-B1/2/3).
2. **Enable Firebase App Check** before public release.
3. **Validate the `backups/{uid}` document** size/shape in `firestore.rules`.
4. Add passphrase-strength validation in the backup UI (SEC-B4).
5. Consider Isar at-rest encryption for privacy-sensitive deployments.
6. Enforce email verification for sensitive flows if the threat model warrants.

## 8. Verification still required

This audit is static. Before relying on it: run the gates in
`docs/CODESPACES_VALIDATION.md`, and ideally add a round-trip test
(`encrypt → decrypt`) and a tamper test once GCM lands.
