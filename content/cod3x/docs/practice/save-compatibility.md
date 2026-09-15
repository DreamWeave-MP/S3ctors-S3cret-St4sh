---
title: Save Compatibility and Persistent State
description: Persist contracts, not implementation accidents; version or rebuild state that can outlive the code that wrote it.
weight: 55
extra:
  kind: guide
---

A save file is a consumer of your API.

The consumer may return months later running a newer version of your mod.

Treat persisted state with the same seriousness as a public interface.

## Persist the minimum authoritative state

Do not serialize everything that happens to be in memory.

Prefer the minimum facts from which runtime state can be reconstructed.

The St4sh history repeatedly moved in this direction. SSS persistence work, for example, evolved toward explicit saved DTOs and minimal replacement-chain entries rather than treating live runtime structures as save format.

Persisting less state reduces:

- migration surface;
- stale caches;
- accidental engine handles;
- save size;
- coupling between implementation and old saves.

## Derived caches should usually be rebuilt

If a value can be deterministically recreated from persisted authoritative state and current content, rebuilding is normally safer than saving it.

Examples:

- lookup maps derived from registrations;
- record caches;
- normalized configuration caches;
- UI layout state that can be reconstructed;
- transient target lists.

Only persist a cache if recomputation is genuinely too expensive and you have a version/invalidation strategy.

## Saved tables are schemas

Once shipped, fields acquire history.

Prefer explicit saved shapes:

```lua
local savedState = {
  version = 2,
  targetId = currentTarget and currentTarget.id or nil,
  mode = currentMode,
}
```

rather than dumping a giant internal manager table whose fields include caches, callbacks, userdata, and implementation details.

## Version when meaning changes

A field rename can be trivial in source and destructive in save data.

When persisted semantics change, choose deliberately among:

- migrate old versions;
- support both forms temporarily and normalize;
- invalidate/rebuild derived state;
- reject an unsupported old version with a precise error.

Do not silently reinterpret a value whose meaning changed.

## `onSave` and `onLoad` are lifecycle boundaries

They are not arbitrary serialization callbacks.

Use them to establish invariants:

- save only supported state;
- validate loaded data;
- rebuild caches;
- re-resolve object identities;
- restart transient effects/subscriptions intentionally.

St4sh VFX history includes fixes where visual-effect lifecycle and save/load behavior had to be reconciled explicitly. Anything with engine-side lifetime can require more than restoring a Lua table.

## Uninstall and missing dependency behavior is part of the contract

If persisted state references a module/content file that is no longer present, decide what happens.

Options include:

- cleanly discard optional derived state;
- migrate to a default;
- stop with a fatal error because continuing would corrupt the feature;
- provide an explicit uninstall/migration path.

Do not guess silently.

## Storage is not automatically save design

OpenMW storage makes persistence convenient. Convenience does not answer:

- who owns the key;
- whether it is authoritative;
- whether old values remain valid;
- whether local/global contexts agree on semantics;
- whether a subscription should fire during restoration.

Document keys that form durable contracts.

## Test old state deliberately

For a meaningful persistent feature, keep fixtures or controlled reproductions for at least the important compatibility boundaries.

Test:

1. fresh game / no stored state;
2. current state round trip;
3. previous supported state;
4. malformed/partial state if the input can realistically occur;
5. missing referenced object/content where relevant.

A save compatibility bug is usually much harder to fix after users have accumulated more state on top of it.
