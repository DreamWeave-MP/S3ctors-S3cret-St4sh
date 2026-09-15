---
title: When Lua-Side Optimization Stops Being Enough
description: What Rubic0n teaches about userdata, GC, finalizers, allocators, and the ceiling below mod code.
weight: 90
extra:
  kind: guide
---

Rubic0n is useful to Cod3x even if you never build a runtime.

It is the point where performance investigation stopped asking only “how should this mod be written?” and started asking “what is the runtime and binding layer charging for this workload?”

## Keep fork-specific behavior separate from OpenMW contracts

Rubic0n contains DreamWeave changes on top of the LuaJIT/OpenResty lineage.

Features such as additional GC statistics, finalizer modes, allocator experiments, and some bytecode/introspection tooling are **not** universal OpenMW-Lua APIs.

Do not write normal mod code that assumes they exist unless the mod explicitly requires the corresponding runtime.

Cod3x documents them to explain mechanisms and profiling methodology.

## Userdata churn became a runtime problem

OpenMW exposes many C++ values through userdata. Small value objects can be created at high frequency in vector-heavy or engine-query-heavy code.

Rubic0n work explored:

- GC allocation telemetry;
- userdata allocation caches;
- userdata finalizer lookup;
- direct C finalizer paths;
- non-resurrecting finalizer contracts;
- GC pacing tuned for OpenMW-style userdata churn;
- batched finalization;
- allocator front ends for small requests;
- userdata/metatable specialization.

The lesson for mod authors is not “implement a custom allocator.”

The lesson is that enough apparently small value crossings can push cost below anything source-level Lua can eliminate.

## Runtime optimization requires stronger contracts

Some Rubic0n finalizer optimizations depend on deliberately narrower semantics than generic Lua finalization.

Those paths are documented as embedder contracts because violating them can cause corruption or crashes.

That is the natural end of “optimize harder”: the lower you go, the less room there is for vague behavior.

Mod-level code should learn the same habit at a safer layer. Fast paths need explicit preconditions.

## Reverts are first-class evidence

Rubic0n includes reverted userdata-cache experiments.

That is valuable.

An optimization at allocator/GC level can look obviously favorable in code review and still lose under real allocation patterns, fragmentation, bookkeeping, locality, or finalizer behavior.

See [The Userdata Cache Was Not Free](@/cod3x/docs/paid-for-with-blood/userdata-cache-revert.md).

## GC telemetry is not free either

`jit.gcstats`-style instrumentation provides detailed counters for allocations, frees, bytes, finalizers, sweep steps, and related runtime behavior in supported Rubic0n builds.

Instrumentation adds overhead.

Use telemetry to explain **why** a workload behaves as it does, then use non-instrumented comparable builds for performance claims.

## Finalizer pacing is a gameplay concern

Bulk benchmark throughput is not the only target.

A runtime can reclaim the same total work but distribute it differently across frames. Rubic0n's batched-finalizer history includes fixes specifically for GC accounting and pacing.

That distinction matters for games: a 1 ms average cost with a periodic 15 ms finalizer burst can feel worse than 2 ms evenly distributed.

## LuaJIT is not the endpoint

Years of bytecode, trace, binding, userdata, allocator, and GC work can make LuaJIT substantially better understood and, in places, substantially faster.

That does not mean every architectural limitation disappears.

The conclusion behind the broader DreamWeave runtime work is that LuaJIT is not a sufficient long-term endpoint for the scripting system being pursued.

Cod3x should document that conclusion technically, not tribally:

- identify concrete runtime/binding limitations;
- benchmark them;
- separate current OpenMW constraints from future-runtime design;
- do not turn “different VM” into a magic performance claim.

The valuable habit is the same one that started the investigation:

**keep digging until you find the actual layer.**
