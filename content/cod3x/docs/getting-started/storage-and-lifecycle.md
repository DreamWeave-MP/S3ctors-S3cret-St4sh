---
title: Storage, Save State, and Lifecycle
description: Persistent state needs ownership, invalidation, and migration rules.
weight: 50
extra:
  kind: guide
---

Persistence is an API contract with your future code.

A value that enters save state can outlive the implementation that created it. Treat storage formats, keys, defaults, and migrations with the same care as public interfaces.

## Own the state

Before choosing a storage section, decide who owns the value.

- Is it global world state?
- Is it player-specific state?
- Is it transient runtime state that should not be persisted at all?

Do not persist data merely because recalculating it feels inconvenient.

Derived caches usually should be rebuilt from authoritative state unless rebuilding is prohibitively expensive and the cache has a real version/invalidation strategy.

## Cache and persistence are different

A cache is allowed to be thrown away.

Persistent state is expected to survive.

Conflating them produces difficult migrations and stale data bugs. S3maphore and SSS both became more reliable as ephemeral caches were given explicit lifetimes rather than being treated as permanent truth.

## Subscriptions require invalidation discipline

Storage subscriptions are useful for propagating settings and shared state, but they introduce two copies of truth if you shadow values locally.

If you maintain a shadow cache:

- populate it deliberately;
- invalidate the correct key or whole group when needed;
- know whether `nil` means “not cached” or “cached absence”;
- do not assume a callback implies every derived value has been recomputed.

Starwind Builder's early `protectedTable` abstraction is a useful historical example: it wrapped storage, caching, logging, arbitrary state, method injection, subscriptions, and read-only behavior behind one metatable. It solved real problems, but it also made ownership and cache semantics harder to see.

H3 Pattern: [ProtectedTable](@/h3lp_yours3lf/docs/api/interfaces/protected-table.md) is the smaller current contract: settings remain storage-backed while transient values live under `.state`. Read the [implementation](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/h3lp_yours3lf/scripts/s3/protectedTable.lua) when the interface documentation leaves a lifetime question.

The later lesson is not “never wrap storage.” It is “keep the contract smaller than the implementation problems you happen to have today.”

## Save/load lifecycle is a boundary

Anything holding runtime handles, VFX instances, transient UI elements, iterators, or other engine-owned objects must decide what survives a save and what must be reconstructed.

Do not serialize engine runtime objects blindly.

{{ schematic(data_path="data/schematics/storage-lifecycle.json") }}

Prefer serializable identifiers and minimal authoritative data, then rebuild transient runtime state on load.

## Version your own assumptions

If a release changes the shape or meaning of persisted state, decide whether to:

- migrate it;
- tolerate both forms for a compatibility window;
- invalidate/rebuild it;
- make the incompatibility explicit.

Silent reinterpretation is the worst option.

## Failure policy

Malformed persisted state is not automatically recoverable.

If the state is optional cache data, discarding and rebuilding may be correct.

If it is required authoritative state and continuing would corrupt behavior, fail loudly with enough context to diagnose the save and key involved.

“Keep running” is not a universal robustness strategy.
