---
name: openmw-persistence-storage-auditor
description: "openmw.storage, settings-backed state, save data, migrations, protected/read-only tables, serialization, reload/save/load behavior, and versioned schemas."
---

# OpenMW Persistence Storage Auditor

Use this skill to review OpenMW Lua state that persists across saves, reloads, sessions, or settings changes.

## Audit Focus

- Identify the owner/lifetime of every state value: global, player, local/object, settings-backed, transient runtime-only, or derived cache.
- Ensure authority and lifetime match the concept represented.
- Treat every persisted key, table shape, enum/string, unit, and identifier format as a compatibility contract.
- Require migrations when non-trivial schemas change; migrations should be idempotent and old saves should tolerate missing/partial data.
- Apply defaults only when data is absent, not in a way that overwrites legitimate persisted state on every load.
- Flag persistent writes in per-frame/high-frequency paths; prefer dirty flags, batching, event-driven updates, or explicit persistence points.
- Treat API-owned/protected/read-only values according to OpenMW's documented semantics instead of assuming normal mutable Lua tables.
- Persist only values the target OpenMW version documents as serializable. Prefer primitives, plain tables, and stable IDs; distrust functions, closures, userdata, live objects, metatables, and coroutines unless explicitly supported.
- Separate persisted state from runtime caches that can be rebuilt after load/reload.
- Make versioning explicit for non-trivial schemas.

## Review Questions

- Who owns and may mutate this state?
- Can an old save or missing key load safely?
- Where is the migration and how is it tested?
- Are defaults centralized and non-destructive?
- Are writes bounded and intentional?
- Are object references represented by stable identifiers when persistence crosses runtime lifetimes?
- Can context/script activation order change without corrupting or resetting state?

## Validation

Test fresh state, at least one previous-schema save when available, repeated save/load/reload, runtime settings changes, and malformed/partial data where defensive loading is expected. Use focused migration tests when possible.
