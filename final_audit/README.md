# Final Audit

Post-completion audit of HabitView, written after the end-to-end Isar
local-first build. These documents reflect the code **as written**; the authoring
environment had no Dart/Flutter SDK, so nothing here is compile- or test-run
verified. See `docs/CODESPACES_VALIDATION.md` for the verification procedure.

| Document | Scope |
|----------|-------|
| [security_audit.md](security_audit.md) | Threat model, backup encryption, auth, data-at-rest, Firestore rules, hardening roadmap. |
| [code_audit.md](code_audit.md) | Per-layer review, known risks, the post-build_runner fixup list. |
| [architecture_review.md](architecture_review.md) | Layering, dependency rule, local-first trade-offs, cost model. |
| [VERIFICATION_STATUS.md](VERIFICATION_STATUS.md) | Implemented / statically-verified / requires-verification matrix. |

> The original (Firestore-era) audit lives in `project_audit/`. This folder
> supersedes it for the current architecture.
