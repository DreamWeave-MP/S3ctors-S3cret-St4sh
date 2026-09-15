---
title: 'Design Genealogy: StaticCollection'
description: How S3maphore changed representation, scheduling, and ownership before optimizing the collection loop.
weight: 100
extra:
  kind: guide
---

## The problem

S3maphore's playlist rules need facts about the world around the player: which records, types, and content files are present, whether hostile actors are nearby, and whether the exterior area has changed.

The naive representation is a retained list of game objects. That is convenient at first. It also keeps engine-backed values alive, repeats expensive interpretation at query time, and makes the lifetime of the collected objects part of every rule's problem.

## Change the representation first

The important early move was not a cleverer loop. It was changing what the collector retained.

Commit [`5d608a26`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/5d608a26a3a5496757d37284686461b44c606081) made that first move toward cached string and count primitives instead of retaining game objects as the main representation. The current [`staticCollection.lua`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/s3maphore/00%20Core/scripts/s3/music/staticCollection.lua) exposes the result as counts by record, type, and content file.

That choice changes the problem. Playlist rules can ask semantic questions about counts and identities without repeatedly crossing into object userdata. The collector owns the engine-bound traversal; the consumer receives data shaped for the decision it has to make.

## Then make the work incremental

The representation change made incremental work possible:

- [`342d77dd`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/342d77dd6f012caa29458a3623499aacceff63f9) then tracked cell and combat-target changes with events, removing more repeated work from the collection path;
- [`8d574d40`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/8d574d403613a184bbf47adec238d7a16eed4e22) moved presence tracking into a coroutine-driven global sweep;
- [`76358648`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/76358648d8f0f7e03fcca055c9cfa8ac83e3fd86) removed the redundant `staticList` representation;
- [`b202141c`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/b202141c0eb3d9617ed55f73b80485fc9c9fc574) added per-cell presence so the system could choose the appropriate scope;
- [`d7f38bb5`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/d7f38bb5b983c5e26d28fbd23c88a8ce38a3c6ff) applied a large optimization pass after the shape and ownership were understood.

The sequence is more important than any one commit:

{{ schematic(data_path="data/schematics/static-collection-representation.json") }}

The generation-counter scar belongs in this genealogy too. Once work can be deferred, [`b148ee31`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/b148ee31cb8fd023436e8b00d984d1098299b0a2) gives a result an identity so an old sweep cannot quietly publish into a newer world. See [Generations for Deferred Work](@/cod3x/docs/paid-for-with-blood/generation-counters.md).

## Why this is a crown jewel

This one system ties together several performance truths without reducing them to “Lua is slow”:

- representation determines what must cross the engine boundary;
- counts and strings can outlive a traversal more safely than live object handles;
- incremental work makes a large scan fit within a frame budget;
- events reduce needless recomputation but increase invalidation responsibility;
- deferred work needs an authority check before it publishes;
- optimization comes after the data shape and ownership are honest.

That is why this belongs late in the suggested path. The pieces are simple individually, but the genealogy shows how they become necessary rather than fashionable.

## What to steal

Before optimizing a loop, ask whether it is iterating the right representation. Before making work incremental, define what data may be published and when it becomes stale.

Do not begin with a coroutine, a cache, or a generation counter. Begin by deciding what the consumer actually needs and who owns the engine traversal.

## When not to use this

If the collection is small, short-lived, and not queried by multiple consumers, retain the simplest local representation. Do not build a global incremental collector to avoid a cheap direct lookup. This design earns its machinery through world size, repeated queries, engine-boundary cost, or a real frame budget.
