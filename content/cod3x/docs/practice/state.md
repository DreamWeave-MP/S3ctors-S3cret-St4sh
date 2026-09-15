---
title: State Ownership and Invalidation
description: One source of truth, explicit derived state, bounded caches, and generations for delayed work.
weight: 40
extra:
  kind: guide
---

Most difficult OpenMW-Lua bugs are not syntax bugs. They are disagreements about which state is authoritative and when derived state stops being valid.

## Name the owner

Every meaningful state value should have a clear owner.

Examples:

- a player script owns player music state;
- an actor-local script owns observations about that actor;
- a global script owns world mutation;
- a storage section owns persisted configuration;
- a cache owns nothing; it mirrors another source.

If two modules both believe they own the same value, synchronization work follows.

## Derived state needs an invalidation rule

Suppose `desiredPlaylist` is derived from journal state, cell presence, combat state, settings, and time of day.

Then each input that can change needs to answer:

**How does this derived value become dirty?**

[S3maphore commit `bfe28c01`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/bfe28c012a7c42a8e0349a9b06b5c0962e796c70) fixed a bug where a quest update cleared the journal cache but did not dirty the resolver correctly. The first journal update changed the source; a second update was needed before the derived playlist changed. The [current resolver implementation](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/s3maphore/00%20Core/scripts/s3/music/playlistReconciler.lua) keeps that ownership visible.

The lesson is larger than music:

**invalidating an input cache is not the same thing as invalidating every value derived from it.**

See [Invalidate the Resolver Too](@/cod3x/docs/paid-for-with-blood/resolver-invalidation.md).

H3 Pattern: [StateMachine](@/h3lp_yours3lf/docs/api/packages/state-machine.md) gives named transitions and explicit enter/exit behavior without owning your engine handler. For settings plus transient runtime values, use [ProtectedTable](@/h3lp_yours3lf/docs/api/interfaces/protected-table.md) and keep the persisted section separate from `.state`.

## Delayed work needs identity

A callback/event/timer can be valid when scheduled and wrong when it runs.

Use a generation, epoch, token, or other identity when mutable state can supersede in-flight work.

```lua
local generation = 0

local function beginRequest()
  generation = generation + 1
  return generation
end

local function acceptResponse(responseGeneration)
  return responseGeneration == generation
end
```

This is especially useful across:

- cell transitions;
- deferred UI updates;
- asynchronous callbacks;
- playback transitions;
- staged scans;
- queued engine events.

See [Generations for Deferred Work](@/cod3x/docs/paid-for-with-blood/generation-counters.md).

## A cache is a promise about lifetime

Caching is not “store result in a table.”

A cache must define:

- key identity;
- value identity;
- valid lifetime;
- invalidation event;
- behavior for cached absence;
- memory bound.

Static Switching System's batch cache is a good example because its lifetime is explicit: expensive C++-backed calls are reused only inside one activation batch, then the cache is cleared.

That is far safer than “cache forever and hope the world does not change.”

## Represent cached absence explicitly

If `nil` means “not present in cache,” you need a sentinel to cache a legitimate absent result.

```lua
local cached = cache[key]
if cached == nil then
  local value = expensiveLookup(key)
  cache[key] = value == nil and false or value
  cached = cache[key]
end

return cached ~= false and cached or nil
```

SSS uses this pattern for weather lookup inside an activation batch.

## Prefer recomputation when it is cheap

Not every derived value deserves a cache.

Caching adds a second data structure and therefore an invalidation problem. If the calculation is cheap, recomputing can be both faster to develop and more reliable in production.

Measure before constructing cache architecture.

## Transient state should stay transient

Do not persist:

- current iterators;
- UI elements;
- temporary lookup caches;
- per-frame work queues;
- live object handles unless the API explicitly supports the lifetime you need.

Persist the authoritative minimal data, then rebuild runtime structures.

## State machine transitions should carry side effects deliberately

A refactor that leaves the apparent state unchanged can still accidentally skip required dependent work.

[S3maphore commit `fbe9f127`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/fbe9f127c46161528b9156f9f952ca536c588f6e) fixed silence-chance state that stopped updating in ordinary playback after an earlier refactor. The playlist had not changed, so one path looked safe to skip, but a dependent side effect still needed to run.

When optimizing “nothing changed” paths, list the effects attached to the transition, not only the primary value.

### From the St4sh

[S3maphore's playlist-state documentation](@/s3maphore/docs/api/playlist-state.md) describes the public state contract; the [playlist reconciler source](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/s3maphore/00%20Core/scripts/s3/music/playlistReconciler.lua) shows the production invalidation path.

For the positive evolution from swappable handlers to named runtime phases, see the [NullFunction to StateMachine genealogy](@/cod3x/docs/good-designs/state-machine-genealogy.md). For the complementary event boundary, see [Event-Driven S3maphore Resolution](@/cod3x/docs/good-designs/s3maphore-event-resolution.md).

### Receipts

- Fix: [`bfe28c012a7c42a8e0349a9b06b5c0962e796c70`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/bfe28c012a7c42a8e0349a9b06b5c0962e796c70) — dirty derived resolver state when journal input changes.
- Current pattern: [StateMachine](@/h3lp_yours3lf/docs/api/packages/state-machine.md) plus explicit invalidation.
