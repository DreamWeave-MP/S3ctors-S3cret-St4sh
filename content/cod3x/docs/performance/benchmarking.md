---
title: Benchmarking Without Lying to Yourself
description: Pin inputs, isolate mechanisms, warm up deliberately, and state what the benchmark does not model.
weight: 80
extra:
  kind: guide
---

A benchmark is an argument.

Its methodology determines what the number can legitimately support.

## Pin the environment

For serious performance work, record source identities.

Rubic0n's OpenMW userdata harness pins:

- the Rubic0n/LuaJIT commit;
- the OpenMW checkout;
- the vendored Sol source identity/patch set;
- the OpenSceneGraph checkout.

That is the right level of precision for binding/runtime work.

For mod-level benchmarks, at minimum record the OpenMW build and relevant mod commit/configuration.

## Build the smallest benchmark that preserves the mechanism

The Rubic0n harness does not boot OpenMW. It reproduces the important value-userdata path using OpenMW's Sol configuration, Sol headers, and actual OSG vector types.

That is a strong benchmark because it removes unrelated engine systems without replacing the mechanism under test with a toy.

The fake position source still returns vectors by value so common OpenMW-like chains retain their allocation shape.

## Separate allocation from collection when needed

The harness times an allocation phase with GC stopped, then restarts collection and performs full collections as a separate phase.

This isolates bulk allocation and reclamation costs.

It **does not** claim to reproduce OpenMW's incremental per-frame GC pacing.

Write that limitation down. Every benchmark needs its equivalent sentence.

## Warm up intentionally

JIT runtimes have warmup behavior.

Untimed warmups can ensure you are measuring steady-state compiled behavior when that is the question.

If the question is startup/trace formation, then warming everything first would destroy the thing you intended to measure.

Choose deliberately.

## Keep work observable

A benchmark whose result is never consumed may allow optimization/elision or accidentally test less than you think.

Rubic0n's harness feeds workload results into a numeric sink so work remains observable.

Use an equivalent mechanism appropriate to the language/runtime.

## Compare like with like

Instrumentation changes performance.

Rubic0n's GCStats-enabled builds have telemetry overhead. The benchmark documentation explicitly says to compare telemetry builds with telemetry builds and use no-GCStats builds for allocator performance claims.

Likewise:

- do not compare JIT-off against JIT-on and attribute the entire difference to one source change;
- do not compare debug-hook profiler mode to an uninstrumented run;
- do not change allocator flags and workload size simultaneously.

## Report distributions, not only one average

Frame-like workloads can have tails.

Useful summaries include:

- median;
- p95/p99;
- maximum;
- sample count;
- burst/window structure.

Averages can hide a periodic 20 ms spike that matters far more to gameplay than a tiny mean improvement.

## Benchmark controls

Include controls that reveal harness overhead.

Rubic0n includes nonallocating controls and an empty/control path so collection/harness costs are visible.

Without controls, you may optimize the benchmark infrastructure instead of the feature.

## Re-run in game

A standalone result establishes a mechanism.

The final question is whether that mechanism is important in the real OpenMW workload.

If an isolated optimization saves 40% of a function that accounts for 0.1% of a frame, you learned something useful about the runtime and almost nothing about player-visible performance.
