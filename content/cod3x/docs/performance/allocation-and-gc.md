---
title: Allocation and Garbage Collection
description: Distinguish transient churn, retained memory, userdata lifetime, and collector pacing.
weight: 35
extra:
  kind: guide
---

Memory work has at least three different failure modes:

1. allocating too much temporary data;
2. retaining data that should have died;
3. distributing collection/finalization work badly across frames.

Do not collapse all three into “GC is slow.”

## Transient allocation

Common sources include:

- temporary tables;
- rebuilt event payloads;
- string transformations in hot paths;
- vector/value userdata returned from bindings;
- repeated parser masking/copying;
- closure creation in frequently called functions.

The right fix depends on ownership. Reuse can help only when the reused value cannot escape into a consumer that expects to retain it.

## Retention

A module-level cache can make allocation graphs look better while memory usage only grows.

Inspect:

- cache size over time;
- object/userdata references held by tables;
- listener/subscription cleanup;
- UI elements not destroyed;
- stale per-cell/per-object maps;
- closures retaining large state.

A full collection cannot reclaim live references.

## Userdata and finalizers

Engine-bound values can require native finalization even when the Lua source looks tiny.

Rubic0n's runtime work exists partly because OpenMW-style userdata churn can make allocation/finalizer behavior significant. Its experiments include GC statistics, finalizer lookup, direct/batched finalizers, pacing, and allocator work.

Normal mod authors cannot and should not reproduce those runtime tricks. They can reduce avoidable churn and measure when returned native values dominate.

## Collector pacing matters to frame time

Total GC throughput is not the whole story.

Games care about tails and spikes. Work that is cheap in aggregate can still cause a visible hitch if finalization/collection happens in bursts.

This is why the Rubic0n history includes fixes for accounting and pacing after introducing batched finalizers.

## Allocation profilers perturb the system

Pr0f1l3r's allocation-attribution mode uses debug hooks and explicitly marks itself unsuitable for clean throughput claims.

Use it to locate suspicious call sites. Then measure the resulting change with a lower-overhead mode.

## Reduce lifetime before inventing pools

Pooling has costs:

- retained memory;
- reset logic;
- borrowed-lifetime contracts;
- harder ownership;
- accidental cross-frame aliasing.

Use a pool only when allocation is measured, the object shape is stable, and the lifetime can be enforced.

Otherwise let the collector do its job.

H3 Pattern: [Pool](@/h3lp_yours3lf/docs/api/packages/pool.md) is the mod-level escape hatch when measured temporary allocation justifies a borrowed-lifetime contract. It does not solve engine userdata ownership; [Rubic0n](@/cod3x/docs/performance/rubic0n.md) is the separate runtime-engineering trail.
