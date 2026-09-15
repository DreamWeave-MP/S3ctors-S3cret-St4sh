---
title: Contracts, Measurements, Derivations, and Preferences
description: Know what kind of claim you are making before turning it into doctrine.
weight: 10
extra:
  kind: guide
---

Strong engineering guidance is useful only when the reader knows **why** it is true.

Cod3x uses four mental categories.

## Contract

A contract is required by the engine, API, runtime, serialization format, or another explicit boundary.

Examples:

- `openmw.world` is a global-context API.
- `object.cell` can be absent.
- a `GObject` exposes mutation capabilities that an `LObject` does not.
- a public event payload has whatever fields your consumers depend on.

Breaking a contract is not a style disagreement.

## Measured

A measured recommendation has evidence from a representative workload.

Examples from the corpus include:

- Cod3x's context parser being improved by a less-allocation-heavy fast path, with the commit reporting up to roughly 30% improvement;
- repeated C++-backed queries in Static Switching System being cached for one activation batch;
- Rubic0n allocator/finalizer work evaluated with dedicated benchmarks rather than assumed to be faster because the patch looked lower-level.

A measurement is never just a number. Record the workload, environment, runtime, and limitations.

See [Benchmarking Without Lying to Yourself](@/cod3x/docs/performance/benchmarking.md).

## Derived

A derived recommendation follows from known implementation behavior even when every call site has not been benchmarked independently.

Examples:

- stale deferred work needs identity if later state changes can invalidate it;
- repeatedly crossing a binding boundary cannot be optimized away by rearranging pure Lua on the caller side;
- a cache with no invalidation rule is a second source of truth, not merely an optimization.

Derived claims should still identify the mechanism.

## Preference

A preference is an engineering choice.

Examples:

- use full-word variable names by default;
- keep comments rare and high-signal;
- separate logical control-flow blocks with whitespace;
- prefer explicit state transitions over metatable magic;
- fail fast when core invariants are violated.

Preferences can be supported by years of experience and still remain preferences.

Do not write “OpenMW requires” when the actual statement is “this codebase is easier to maintain when.”

## Why the distinction matters

Cargo cults form when evidence categories collapse.

Someone sees a local alias in a hot S3maphore module and concludes every global function in every Lua file must be localized.

Someone sees an expensive engine query cached for one activation batch and concludes all OpenMW userdata should be cached forever.

Someone sees a valid `pcall` at a plugin boundary and concludes protected execution is defensive programming.

All three conclusions lose the mechanism that made the original choice correct.

Cod3x should preserve that mechanism.

## Write recommendations so they can be challenged

A good recommendation survives questions like:

- What layer is expensive?
- What would make this advice stop being true?
- Which OpenMW version does this describe?
- Is this a runtime behavior or a style choice?
- Is the benchmark representative?
- Is there a primary source?
- Was this learned from a failure?

The goal is not to eliminate opinions.

The goal is to make opinions distinguishable from physics.
