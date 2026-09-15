---
title: Paid For With Blood — The Raycast Was the Optimization Target
description: Targeting code evolved from fixing accidental UI churn to restructuring the expensive engine work itself.
weight: 80
extra:
  kind: guide
---

## Paid For With Blood

The Starwind lock-on implementation is useful because its history shows performance maturity in layers.

An early fix, [commit `f90baec`](https://github.com/DreamWeave-MP/Starwind-Builder/commit/f90baec9f50a7fab7bb5a731a0986e71dee4c53e), corrected a bug where the lock-on texture resource was effectively recreated continuously because the cached value and compared value used different representations.

That is a valid micro-level fix: stop rebuilding a resource whose configuration did not change.

But the larger targeting system still had a much more expensive layer: geometry and engine queries.

By the later T4rg3t5 implementation, [commit `de85472b`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/de85472bc40a29076b55e20d7ba0715326f37242) was explicitly a **major refactor to minimize raycasts and runtime operations**.

### From the St4sh

The [T4rg3t5 targeting API](@/t4rg3t5/docs/_index.md) is the public surface. The [lock-on manager source](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/t4rg3t5/scripts/s3/target/lockOnManager.lua) is the implementation worth studying: target state, camera work, and presentation are not the same operation.

It changed the shape of the work rather than polishing one Lua expression.

Among other things, the refactor:

- stopped evaluating both shoulder-camera candidates unconditionally;
- checked the current side first and only evaluated the alternate side when needed;
- compared squared distances where normalization/length was unnecessary;
- removed redundant vector normalization before angle calculations;
- cached marker visibility as ordinary state instead of rereading UI layout state;
- avoided UI updates when visibility did not change.

## What changed in the engineering question

The early question was:

> Why are we recreating this texture?

The later question was:

> Why are we asking the engine all of these geometry questions every frame?

Both are correct questions at different stages.

The second usually matters more.

## The rule

When profiling engine-bound code, rank work by **semantic cost**, not by how complicated the Lua expression looks.

A table lookup may look busy and cost almost nothing beside:

- a raycast;
- a bounding-box query;
- a world/object scan;
- a UI rebuild;
- a binding that constructs temporary userdata.

Optimize the layer the profiler says is expensive.

See [Engine Boundaries](@/cod3x/docs/performance/engine-boundaries.md), [Hot Paths](@/cod3x/docs/performance/hot-paths.md), and [Every Frame Is a Budget, Not an Invitation](@/cod3x/docs/anti-patterns/per-frame-everything.md).
