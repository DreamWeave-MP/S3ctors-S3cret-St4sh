---
title: Error Handling
description: Fail fast on programmer errors; protect only real recovery or cleanup boundaries.
weight: 30
extra:
  kind: guide
---

The default error policy is simple:

**If correct execution says an operation cannot fail, let it fail loudly when it does.**

Do not turn programming errors into control flow.

Do not convert violated invariants into ambiguous state.

Do not catch an error merely because seeing an error feels impolite.

## `pcall` is not defensive programming

Do not wrap ordinary calls in `pcall` because they might throw.

Do not use protected execution to hide:

- incorrect API usage;
- malformed registrations;
- impossible state;
- missing required dependencies;
- type errors;
- bugs in your own callback;
- failures you cannot actually recover from.

If the only recovery plan is “print something and continue as though the operation worked,” you do not have a recovery plan.

**I will hunt you for using `pcall`.**

There. Now read the exceptions instead of cargo-culting the threat.

## A protected call needs a boundary

Protected execution is justified when failure is part of the boundary's contract and you have something specific to do with it.

Three recurring legitimate cases appear in the corpus.

### 1. Arbitrary external/plugin code

DreamScripts' script loader eventually had to execute arbitrary compiled script chunks. An unhandled script error could escape through the host boundary and crash the process path.

DreamScripts [commit `219c6e4b`](https://github.com/DreamWeave-MP/DreamScripts/commit/219c6e4b6b2567d7950f20368b2c765c654dd789) wrapped that execution, logged the failure, and stopped the server.

The protected call did **not** convert a broken script into success. It translated an uncontrolled host failure into a controlled fatal boundary.

That is legitimate.

### 2. Restore invariants, then rethrow

H3's [`Signal:fire`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/h3lp_yours3lf/scripts/s3/signal.lua) uses `xpcall` around listener invocation so that listener mutations and firing state can be cleaned up even when a callback throws. The error is then rethrown.

The goal is not suppression.

The goal is:

{{ schematic(data_path="data/schematics/error-invariant.json") }}

That is legitimate.

### 3. Introspection APIs where absence/failure is data

Pr0f1l3r probes LuaJIT/debug facilities that can legitimately be unavailable or reject a particular trace/function/PC combination. The profiler must be able to record partial telemetry rather than crash because one introspection query has no answer.

That is legitimate because the operation's contract includes “this information may not be obtainable.”

### 4. Capability probing where failure is the answer

ProtectedTable uses protected execution when probing a storage section's write capability. The attempted operation is explicitly expected to fail for read-only sections, and that failure itself supplies the information being requested. The constructor uses the result to choose the write path; it does not hide a programming error and continue as though the write succeeded.

That is legitimate.

## Context probing is an edge case, not a design model

Historical Starwind code and current H3 compatibility helpers use protected `require` calls to identify the active script context.

That works because failure itself is the signal being queried.

Do not generalize that into ordinary module architecture. Cod3x context annotations and context-specific entry points are preferable for normal code.

See [Probing Context by Failure](@/cod3x/docs/anti-patterns/context-probing.md).

## Preserve the diagnostic

If you must catch an error, do not destroy the useful information.

DreamScripts has a delightful pair of historical fixes whose subjects amount to “we should probably actually print the traceback.” That is exactly the lesson.

An error boundary should preserve:

- the original message;
- traceback when useful;
- the operation being attempted;
- relevant IDs/paths/context;
- whether execution continued or terminated.

Catching an error and replacing it with `failed` is vandalism.

## Recovery must restore a valid state

Suppose a callback mutates three structures and throws after the first.

If you catch the error and continue, which structures are authoritative now?

Unless the boundary is transactional, can roll back, can rebuild, or can safely discard the work, continuing may be worse than stopping.

“Robustness” means preserving valid behavior, not maximizing uptime at any cost.

## Fatal means fatal

When an invariant violation makes future behavior unknowable, terminate the feature or process at the appropriate level.

S3maphore's CellPresence collection was changed in [commit `c100e5eb`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/c100e5eb90718aaf6df75d00db4f235b568bc13a) so collection errors are fatal rather than tolerated. That choice reflects the state machine's dependency on correct presence data.

A half-valid resolver is not more user-friendly than an error.

## `core.quit()` is not `return`

OpenMW-specific warning: requesting game termination does not imply the current Lua function immediately stops executing.

[Commit `e3e21b64`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/e3e21b642728d07de2b0ae7565b7aa4a3e2766d9) exists because code continued after calling `core.quit()`.

H3 Pattern: use [Result](@/h3lp_yours3lf/docs/api/packages/result.md) when a caller needs explicit success/failure data, not a hidden protected call. Use [Signal](@/h3lp_yours3lf/docs/api/packages/signal.md) when synchronous listener cleanup and rethrowing are the actual boundary contract.

If execution must stop locally, return.

See [Quitting Is Not Returning](@/cod3x/docs/paid-for-with-blood/quit-is-not-return.md).

## See also

- [Fail Fast, Recover Deliberately](@/cod3x/docs/anti-patterns/pcall-everything.md)
- [State Ownership and Invalidation](@/cod3x/docs/practice/state.md)
- [Pr0f1l3r](@/cod3x/docs/performance/pr0f1l3r.md)
- PCallManager

For a practical demonstration of an architecture in which protected execution is applied without meaningful discrimination, see PCallManager.
