---
title: 'Design Genealogy: PlaylistRules and Private Machinery'
description: How S3maphore exposed semantic playlist questions while hiding the caches and invalidation needed to answer them quickly.
weight: 85
extra:
  kind: guide
---

## The problem

S3maphore playlist conditions ask questions that can be expensive to answer: does this cell contain a matching object, is a combat target of a given type present, or does a content file contribute enough objects?

The public caller wants the answer. It should not need to know which engine collection was scanned, which identity formed the cache key, or which event made an old answer invalid.

> Expose the semantic question. Hide the machinery needed to answer it quickly.

{{ schematic(data_path="data/schematics/playlist-rules-boundary.json") }}

## The first cache

The first useful optimization was not a general cache framework. Commit [`07df2d73`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/07df2d7356d1331038b44fe67c2c252949147c53) added a small helper to remove repeated cell-caching boilerplate from PlaylistRules.

That helper made the repeated shape visible: obtain a stable input, compute an answer once for the relevant lifetime, and reuse it. The important part was not the helper's name. It was that the cache had a home near the semantic rule instead of leaking into every playlist callback.

## Repetition earns deployment

Once several rules had the same need, commit [`186e469d`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/186e469dabb02c5fc5ef24d5be09f52ebc506230) deployed the helper across the rule set. The public surface could remain about questions such as `cellName`, `contentTag`, `typeCount`, and combat-target matching while the implementation shared the boring cache mechanics.

The [playlist rules reference](@/s3maphore/docs/api/rules/_index.md) is for authors. It describes meaning and inputs, not cache tables. The [playlist eligibility study](@/cod3x/docs/good-designs/s3maphore-playlist-eligibility.md) explains the other half of the boundary: the resolver asks whether a playlist applies, while the rule owns how its condition is expressed.

## Caches create obligations

A cache is not free speed. It creates a claim about identity and lifetime. PlaylistRules learned that claim through several invalidation fixes:

- [`32153de8`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/32153de83e2714c18f6364c94b98d3cc75d0eeb8) added an event path for clearing combat-target caches;
- [`a1a431b1`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/a1a431b1b530500d28620fc2147f90512c1ea643) narrowed clearing to the affected target while preserving dynamic-stat caching;
- [`73038e4a`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/73038e4ad9e4755ed5c525fa59babb89f48f98ad) cleared combat caches when an actor left combat, before a new key could be generated;
- [`c077f20f`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/c077f20f251b5b3e1a3b11c16a7529e2bb714073) corrected nil-index behavior during combat-start cache clearing.

The lesson is not “cache playlist rules.” It is:

> Every cached answer needs a defined identity, semantic lifetime, and invalidation path.

The [resolver invalidation scar](@/cod3x/docs/paid-for-with-blood/resolver-invalidation.md) and [event-driven resolution genealogy](@/cod3x/docs/good-designs/s3maphore-event-resolution.md) document what happens when those obligations are treated as details.

## Hide what callers should not own

After the cache machinery had a real shape, commit [`80b31628`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/80b31628948f3a2c4b3c0bd711a2f6130221cda1) privatized the cache-related functions while preserving the public PlaylistRules API.

That was not cosmetic encapsulation. It stopped callers from becoming coupled to implementation operations whose correct use depends on invalidation timing. A playlist author should be able to ask whether a rule matches. The rules module should own whether that answer came from a cache, a fresh engine query, or a cache miss.

This is semantic encapsulation: hide the representation because the representation has obligations the caller cannot safely manage.

## What to steal

Start with the question the consumer needs answered. Add caching only after measuring repeated work and identifying the value's identity and lifetime. Then keep cache keys, invalidation, and rebuild operations behind the semantic boundary.

Do not confuse a private cache with a private contract. The public API still needs to say what the answer means, what inputs are valid, and when it reflects current state.

## When not to use this

Do not add caching when the query is cheap, the input changes constantly, or the invalidation graph is harder to maintain than the original work. Do not hide a relationship that callers genuinely need to coordinate. A cache that cannot state when it becomes stale is a bug incubator wearing a performance hat.
