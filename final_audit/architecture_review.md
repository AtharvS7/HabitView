# Architecture Review

_HabitView — local-first Flutter habit tracker._

## Shape

Layered "clean architecture" with a strict inward dependency rule:

```
presentation ──▶ application ──▶ domain ◀── data
   (UI/router)     (services,        (models,      (Isar, Firebase
                    providers)        interfaces)    auth, backup)
```

Domain has no outward dependencies. Data depends on domain only to implement its
interfaces. Application orchestrates domain logic and exposes it via Riverpod.
Presentation consumes providers. The rule is respected throughout.

## Key decisions & rationale

| Decision | Rationale | Trade-off |
|----------|-----------|-----------|
| **Isar as source of truth** | Offline-first, fast local queries, zero cloud cost for core use. | Multi-device live sync is not automatic (deferred / opt-in backup only). |
| **Firebase = auth + opt-in backup only** | Keep Firebase cost ~0; no per-habit cloud writes. | Backup is snapshot-based, not real-time; restore is whole-snapshot. |
| **Single `backups/{uid}` doc** | One write per backup, owner-scoped, trivially cheap. | Document size grows with data; needs a size guard (see security audit). |
| **Enums stored as `.name` strings + mappers** | On-disk/backup stability across enum reordering; generator stays domain-ignorant. | Slight indirection in the data layer. |
| **Freezed for domain, hand-written for `AppUser`/`AppSettings`** | Avoid needing build_runner for the small plain models. | Two model styles to maintain. |
| **Riverpod (providers + AsyncNotifier)** | Testable DI, override-in-`main` for Isar/notifications, fine-grained rebuilds. | Provider graph requires discipline. |
| **go_router `StatefulShellRoute.indexedStack`** | Persistent bottom-nav tab state + centralized auth/onboarding redirect. | Redirect logic must handle the auth-loading window (it does, via splash). |
| **Premium gating off a local flag** | Payment-provider-agnostic; easy to test. | No server-side entitlement enforcement (acceptable for v1). |

## Cost model

The design deliberately targets near-zero Firebase cost: no per-habit reads or
writes, auth tokens only, and at most one backup document write per user per
backup. Firestore is otherwise idle. This is the central architectural
constraint and the code honors it.

## Testability

Business logic is pure and isolated in `application/services/`, each with a unit
test. The Isar/Firebase boundaries sit behind repository interfaces, so the
services never touch infrastructure. This is the strongest part of the design.

## Risks & limitations

1. **Generated-code dependency.** Nothing in the data/domain entities compiles
   until build_runner runs; the accessor-name assumption (`habitEntitys`) is the
   one thing to confirm post-generation (see code audit C-1).
2. **No live multi-device sync.** By design; users get manual/opt-in backup.
   A future server-sync mode could reuse the retained per-collection rules.
3. **Snapshot backup growth.** A single doc per user scales fine for a personal
   tracker but should be size-guarded server-side.
4. **Settings are device-local**, not per-user — intentional, documented.

## Verdict

The architecture is coherent, cost-conscious, and testable, and it matches the
local-first product intent. No structural changes recommended for v1; the open
items are verification (toolchain) and configuration (Firebase/native), not
design.
