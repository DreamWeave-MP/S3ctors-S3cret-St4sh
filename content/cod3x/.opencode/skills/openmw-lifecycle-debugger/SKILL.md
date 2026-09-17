---
name: openmw-lifecycle-debugger
description: "OpenMW new-game/existing-save lifecycle, script activation, top-level work, storage subscribers, save migration, reload, and handler-order debugging."
---

# OpenMW Lifecycle Debugger

Use this skill when OpenMW Lua behavior differs between a fresh install, new game, existing save, mod update, or mod added to an old save.

## First Establish

Derive from the report/files/logs when possible, and ask only when missing information blocks the diagnosis:

- New game, existing save, or existing save after install/update.
- Script context: global, player, local, menu, or load where relevant.
- Failure boundary: module load, `onInit`, `onLoad`, `onUpdate`, callback/event, reload, or later runtime.
- Whether storage/state is nil, stale, missing, or from an older schema.
- Matching OpenMW version/API revision.

## Reasoning Model

- Treat fresh-game and existing-save paths as distinct execution histories.
- Top-level module code executes at load time; lifecycle handlers execute later under different guarantees.
- Handler registration at top level is normal. Lifecycle-dependent work at top level is the hazard.
- Persisted state can bypass assumptions made for first initialization.
- Scripts introduced to existing saves may activate differently from scripts present from game creation; verify version-specific behavior before relying on startup timing.
- Storage subscribers and cross-context events can observe partially initialized state if ordering is assumed rather than designed.
- Do not assume another context is ready just because one context has initialized.

## Debugging Workflow

1. Reproduce or reason separately for the relevant fresh/old-save paths.
2. Inventory top-level storage access, subscriptions, interface registration, event sends, object lookups, and migrations.
3. Map prerequisites for every lifecycle handler and callback.
4. For missing state, distinguish absent key, uninitialized section, script not yet active, failed migration, and wrong ownership/context.
5. Add narrow lifecycle traces when source inspection cannot establish order.
6. Separate persistent migration from transient runtime-cache initialization.

## Source Hierarchy

Exact ordering is version-sensitive. Prefer matching OpenMW source, then official docs, then Cod3x stubs, then local traces/tests. Runtime evidence for the target version beats remembered historical behavior.

## Fix Guidance

- Move lifecycle-dependent work to the earliest handler whose prerequisites are actually guaranteed.
- Make migrations idempotent and tolerant of missing/partial old data.
- Keep transient defaults separate from persisted defaults.
- Guard subscriber/event callbacks against not-yet-ready dependencies.
- Use explicit request/acknowledgement or state handshakes across contexts instead of incidental load order.
- Verify both the target existing-save path and fresh-game path before closing a compatibility bug.
