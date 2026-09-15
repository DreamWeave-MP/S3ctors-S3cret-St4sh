---
title: 'Design Study: ImageAtlas'
description: How repeated texture-frame arithmetic became a small domain object with useful operations.
weight: 60
extra:
  kind: guide
---

## The problem

Several UI systems needed many frames stored in one texture: status indicators, hand poses, animated icons, and other image sequences.

Without a shared concept, every consumer calculates row and column offsets, creates one texture resource per tile, tracks the current frame, wraps at the ends, updates the element, and gets the direction cases slightly wrong.

That arithmetic is not difficult. Repeating its rules in every consumer is how small bugs become a family tradition.

## The reduction

The useful domain question is:

> Which frame is next, where is it in the atlas, and how do I display it?

H3's `ImageAtlas` gives that question a vocabulary: `getCoordinates`, `getNextFrame`, `spawn`, `cycleFrame`, and `getElement`. The [ImageAtlas reference](@/h3lp_yours3lf/docs/api/interfaces/image-atlas.md) describes the runtime and allocation contract.

The H4ND implementation became the first real consumer immediately after the abstraction was introduced. [`bf230995`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/bf23099565db2e94f3450dbfdadc9c198e204d74) added ImageAtlas to H3, and [`224d20c`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/224d20c505c64d81b8bf5e4a36b2fa81fc376ae6) shows the first H4ND consumer. The [H3 ImageAtlas reference](@/h3lp_yours3lf/docs/api/interfaces/image-atlas.md) documents the durable API.

## Give repeated rules a home

The atlas owns the rules that belong to an atlas:

- frames are one-based;
- coordinates advance across rows;
- forward and backward movement wrap;
- construction creates the tile resources;
- cycling changes an existing element rather than rebuilding the UI.

The consumer owns the meaning of the frame: health, fatigue, compass direction, hand pose, or something else. That division is why the object is useful without becoming a UI framework.

## Reality corrects the edges

The first abstraction was not perfect. Later history repaired the contract where actual use found gaps:

- [`494ebdc4`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/494ebdc4a881dfbe7c7acd4dba9e7529065bb426) fixed the false/backward case.

Later commits [`51cfc16c`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/51cfc16c3371eeedaebc94ea81f193cfb767522e) and [`8fa3d40a`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/8fa3d40a879c178d81e06c46bd1a3d3d64fef32e) added the dedicated next-frame operation and fixed the current-tile update. The current source preserves that resulting behavior in `getNextFrame` and `cycleFrame`.

This is not evidence that the abstraction was a mistake. It is evidence that a useful boundary gives bugs one place to be fixed.

## What to steal

When a representation has recurring rules, give the representation a domain vocabulary. Do not scatter frame arithmetic through every caller.

But do not turn every four-line calculation into a class. The repeated domain concept, shared ownership, and real consumer pressure are what justify `ImageAtlas`.

See [H3UI](@/h3lp_yours3lf/docs/concepts/h3ui.md) for the higher-level UI layer and [Allocation and GC](@/cod3x/docs/performance/allocation-and-gc.md) for the difference between constructing an atlas once and rebuilding it in a frame loop.

## When not to use this

If one caller performs four lines of frame arithmetic once, it does not have a reusable atlas boundary yet. Use an ordinary texture and local code until repeated frames, wrapping rules, or shared ownership justify the domain object.
