---
title: A Faster Finalizer Still Has to Fit the GC Budget
description: Rubic0n batched finalizers needed explicit accounting and pacing after the fast path changed how much work one GC step performed.
weight: 95
extra:
  kind: guide
---

## Paid For With Blood

Rubic0n introduced a direct/batched C finalizer path to reduce the overhead of OpenMW-style userdata reclamation.

Making the individual operation cheaper was not the end of the problem.

Commit [`6797075e`](https://github.com/DreamWeave-MP/Rubic0n/commit/6797075e4b1215c6b3782cb68fa7958dbe4fb13f) fixed GC accounting so a batch of finalizers charged cost proportional to the amount of finalization work rather than pretending the batch was one ordinary finalizer step.

Commit [`75a9a247`](https://github.com/DreamWeave-MP/Rubic0n/commit/75a9a2473f56adee36590e4480f031451383cae6) then fixed pacing so the batch size respected the collector's available budget instead of always consuming the maximum configured batch.

## What went wrong

An optimization changed the granularity of work.

The old collector model assumed roughly one finalizer operation at a time. A batch can retire many objects in one call, so reusing the old accounting makes the collector believe less work occurred than actually did.

That can move latency rather than remove it.

A total-throughput win can still create worse frame spikes if the scheduling model no longer matches the amount of work executed per incremental step.

## The rule

**When an optimization batches incremental work, update the accounting and pacing model too.**

Measure both:

- total throughput;
- distribution of work across frames/steps.

This applies above the runtime as well.

If an OpenMW mod replaces one-object-per-frame processing with a batch of 100, it must reconsider frame budget and latency rather than assuming fewer callbacks automatically means smoother execution.

Sources: Rubic0n commits [`6797075e`](https://github.com/DreamWeave-MP/Rubic0n/commit/6797075e4b1215c6b3782cb68fa7958dbe4fb13f) and [`75a9a247`](https://github.com/DreamWeave-MP/Rubic0n/commit/75a9a2473f56adee36590e4480f031451383cae6).

See [Allocation and Garbage Collection](@/cod3x/docs/performance/allocation-and-gc.md) and [Bounded Batch](@/cod3x/docs/cookbook/bounded-batch.md).
