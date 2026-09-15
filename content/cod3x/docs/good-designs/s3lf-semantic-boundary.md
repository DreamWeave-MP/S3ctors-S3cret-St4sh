---
title: 'Design Genealogy: I.s3.lf'
description: How lazy caching turned repeated OpenMW userdata and bound-method construction into ordinary table access, then grew into an attached-object facade.
weight: 30
extra:
  kind: guide
---

## What it actually does

S3lf is a lazily cached facade over the attached OpenMW object. It resolves type methods, stats, records, object fields, and related helpers on demand, caching results directly on the facade when the configured key behavior allows it.

The common case is simple:

```lua
local health = types.Actor.stats.dynamic.health(self)
```

That call is perfectly readable. Repeating it throughout a hot path can repeatedly cross the binding boundary and reconstruct engine-backed values. With S3lf:

```lua
local s3lf = I.s3.lf

local health = s3lf.health
```

The first access resolves `health` and stores the result on the S3lf instance. Later accesses find the cached value through ordinary Lua table lookup. Keys configured as uncacheable are read again; ignored keys return `nil`. The cache policy is explicit because not every engine value has the same lifetime.

S3lf also binds type methods to the attached object once:

```lua
local stance = types.Actor.getStance(self)
local equipment = types.Actor.getEquipment(self, slot)
```

becomes:

```lua
local stance = s3lf.getStance()
local equipment = s3lf.getEquipment(slot)
```

Type methods are wrapped once with the attached object and cached, removing repeated `self` plumbing and repeated facade resolution.

## The problem

OpenMW exposes related but different things: records, object instances, concrete types, engine-owned userdata, actor stats, script contexts, and APIs whose availability depends on what the attached object actually is.

Every consumer can learn all of that. Every consumer can repeat the type checks, record lookups, lifetime assumptions, engine crossings, and `self` plumbing.

Or one piece of code can resolve it once and make the repeated access cheap.

The exact external ancestry of S3lf is not established in this repository. Earlier community `omwself` helpers clearly belong to the surrounding design context, but the precise gnounc → MaxYari → S3lf authorship chain still needs primary-source verification. The internal DreamWeave lineage below is verified.

## The tempting design

Without a shared cache boundary, callers grow their own access paths:

```lua
local health = types.Actor.stats.dynamic.health(self)
local record = self.type.records[self.recordId]
local stance = types.Actor.getStance(self)
```

That code may be fine once. Repeated across a codebase, it makes every consumer responsible for engine-backed value construction, method binding, type narrowing, and deciding what may be retained. A later fix has to find every copy.

## The first useful trick

The first internal S3lf version was much more primitive than the current interface. Commit [`f6f73098`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/f6f73098e6b4039416709bbcf9ecf1512b6a9255) introduced the CHIM 2090 S3lf class and moved a consumer onto it.

Its important idea was already practical rather than grand:

> Resolve the attached object's expensive or awkward values lazily, then retain the safe result where the next access can find it.

The semantic facade came after that pressure. Once one object-shaped view already owned the lazy lookups, it became a natural home for narrowing helpers, record access, common fields, and attached-object vocabulary.

## How the lookup earns its keep

The current [`lf.lua`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/h3lp_yours3lf/scripts/s3/lf.lua) lookup follows the attached object through several sources:

1. configured key behavior decides whether the key is ignored, uncacheable, or cacheable;
2. the attached object's type provides a value or function;
3. actor stats provide dynamic stats, attributes, skills, level, and AI stats;
4. the object's record provides record-derived fields;
5. the attached object provides inherited object fields;
6. animation helpers and a few S3lf-specific values complete the cold path.

Functions are wrapped with the attached object as their first argument and cached on the instance. Type methods are therefore bound once, while engine-backed values such as dynamic stats are retained as values according to the key policy. S3lf caches the engine-backed stat object, not a numeric snapshot of the stat: caching `s3lf.health` does not freeze `health.current`; it retains the DynamicStat view instead of reconstructing that wrapper every time. Cacheable values are written directly onto the instance with `rawset`, so the metatable does not run again for that key.

This is why the implementation is more than a convenience alias. It changes repeated engine-backed access into a local lookup while keeping the lookup policy in one place.

## The facade that grew around the cache

Once the performance boundary existed, semantic helpers became useful without changing the original reason for the object:

- `asActor`, `asNPC`, `asPlayer`, `asCreature`, and `asNonActor` narrow the attached object once;
- records and common object fields have one predictable vocabulary;
- actor methods omit the repeated object argument;
- `distance`, `sendObjectEvent`, and related helpers live beside the cached view;
- the installed `I.s3.lf` interface gives consumers one provider boundary.

The abstraction is therefore both a performance tool and a facade. The order matters. The convenience view became valuable because it was already eliminating repeated lookup and binding work; it was not invented as a generic object model first.

## The genealogy

The internal path is:

{{ schematic(data_path="data/schematics/s3lf-genealogy.json") }}

Commit [`9ffbd3f9`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/9ffbd3f96923a01675345569cdaebf4934bca77d) published S3lf as its own release. Commit [`257aabfd`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/257aabfdc42e2a483057940e031140eb5d4eaf7a) then migrated the implementation into H3lp Yours3lf, where the installed interface became the stable consumer boundary.

The names and types continued to improve after the boundary existed. Commit [`71c8a463`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/71c8a463071d52566bca772018163e75055cbe94) added explicit type-casting helpers and repaired the type model. Commit [`3a914c36`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/3a914c36a45f1152c38a8b945c184b4a67b9edc9) removed the older `objectType` field for memory savings. The architecture survived API refinement because its cache and attached-object boundary were already useful.

## What to steal

If the same engine-backed values and bound methods are reconstructed repeatedly, first measure the crossing and allocation cost. If the result's lifetime makes caching safe, attach the cache to the object-shaped view that owns the lookup. Keep the performance claim primarily on the engine-backed values and their access paths; method binding is the convenience that removes repeated `self` plumbing and facade resolution.

Then let convenience grow around the real performance boundary. Do not build a giant facade merely because it can forward many members.

See [Engine Boundaries](@/cod3x/docs/performance/engine-boundaries.md), [Measure First](@/cod3x/docs/performance/measure-first.md), and the [H3 S3lf reference](@/h3lp_yours3lf/docs/api/interfaces/s3lf.md).

## When not to use this

If there is one consumer, one lookup, and no repeated engine-backed construction to centralize, use the OpenMW API directly. Do not cache values whose current state must be observed on every access. A facade is useful when it makes repeated work cheaper and gives several consumers one stable attached-object boundary.
