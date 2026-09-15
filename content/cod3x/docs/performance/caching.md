---
title: Caching Without Creating New Bugs
description: Cache by semantic lifetime, record absence explicitly, and invalidate next to the cause.
weight: 30
extra:
  kind: guide
---

A cache trades repeated work for state-management complexity.

If you cannot state the cache lifetime in one sentence, you probably do not have a cache design yet.

## Start with the expensive operation

[Static Switching System's batch cache](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/static_switching_system/Scripts/staticSwitcher/batchCache.lua) covers calls including:

- `types.Player.quests(Player)`;
- `Player:getEquipment()`;
- `core.weather.getCurrent(cell)`.

The key insight was not “tables are fast.”

The key insight was that many conditions inside **one activation batch** asked the same C++-backed questions while the values were semantically stable for that batch.

The cache is cleared when the batch boundary begins.

That is a good lifetime.

## Put invalidation beside the event that invalidates

Do not scatter “maybe clear cache” calls through consumers.

If a cell transition invalidates per-cell state, clear it at the transition.

If a registration update invalidates a derived catalog, dirty it at registration.

If a reload invalidates event registrations, clear them at reload.

The farther invalidation lives from its cause, the easier it is to miss a path.

## Cache absence when absence is a result

If an engine query can validly return `nil`, using `nil` as both “not cached” and “cached no result” repeats the expensive query forever.

Use a sentinel such as `false` or a unique local object.

## Do not cache runtime handles forever

Object handles have engine lifetimes.

A cache keyed by an object ID and rebuilt on cell transitions may be correct. A module-level table retaining arbitrary object userdata indefinitely is not automatically safe or cheap.

Ask whether the cache prolongs memory retention and whether handles can become invalid.

## Cache the right layer

[DreamScripts commit `28062542`](https://github.com/DreamWeave-MP/DreamScripts/commit/28062542ca4e8f0eecc65237264aa2b13c44e8d1) fixed a module loader that cached compiled chunks rather than the modules those chunks returned.

The cache technically contained reusable work, but not the abstraction callers expected.

A cache should preserve the semantics of the operation it replaces.

H3 Pattern: [memoize](@/h3lp_yours3lf/docs/api/packages/memoize.md) supplies explicit invalidation, TTL, entry limits, cached absence, and reference-retention semantics. For path-shaped keys, [normalizePath](@/h3lp_yours3lf/docs/api/packages/normalize-path.md) is the small canonicalization helper; it is not file validation.

## A cache can hide stale state

S3maphore's journal bug is a warning here. Clearing one cache did not automatically tell the playlist resolver that its derived answer was stale.

When multiple caches/derived layers exist, draw the dependency graph explicitly.

{{ schematic(data_path="data/schematics/cache-dependency.json") }}

Then attach invalidation to every derived layer that depends on the change.

## Memory is part of cache cost

A cache that saves 20 microseconds and retains thousands of objects forever may be a regression.

Track:

- entry count;
- key churn;
- retained userdata;
- eviction/clear frequency;
- whether tables themselves become a GC burden.

Pr0f1l3r can help distinguish retained growth from temporary allocation pressure.

### From the St4sh

[S3maphore's playlist API](@/s3maphore/docs/api/playlist.md) and [playlist environment](@/s3maphore/docs/api/playlist-environment.md) show a production system where cached inputs and derived playback state have separate lifetimes. [Pr0f1l3r](@/pr0f1l3r/index.md) is the tool for checking whether the retained data is actually a problem.

The positive design story is in [Event-Driven S3maphore Resolution](@/cod3x/docs/good-designs/s3maphore-event-resolution.md), [PlaylistRules](@/cod3x/docs/good-designs/playlist-rules-private-machinery.md), and [Earned Shared Infrastructure](@/cod3x/docs/good-designs/earned-shared-infrastructure.md): keep the public rule semantic, hide the cache machinery, and make invalidation explicit.
