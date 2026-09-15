---
title: Provenance and Research Corpus
description: How Cod3x turns repository history into engineering evidence.
weight: 2
extra:
  kind: guide
---

Cod3x is evidence-driven documentation. The initial engineering corpus was built by traversing every reachable commit in complete Git bundles of four major repositories, not by reading only their current trees.

At the snapshot used for this manual, the supplied bundles contained:

| Repository | Reachable commits | Particularly useful history |
| --- | ---: | --- |
| S3ctors S3cret St4sh | 4,971 | OpenMW production mods, Cod3x, H3, S3maphore, SSS, UI systems, performance work |
| DreamScripts | 2,737 | Lua architecture, event systems, script loading, hot reload, optimization experiments, TES3MP-era failure modes |
| Starwind Builder | 481 | Early OpenMW systems, context probing, manager architecture, camera/lock-on work, experimental infrastructure |
| Rubic0n | 3,605 | LuaJIT/OpenResty history plus DreamWeave runtime, GC, finalizer, allocator, userdata, benchmark work |

The counts include all reachable refs from the supplied bundles. Rubic0n contains a large upstream LuaJIT/OpenResty history; Cod3x must distinguish upstream runtime behavior from DreamWeave-specific fork work.

## What history is for

The current implementation tells us what survived.

History tells us why.

Searches for `FIX:`, `PERF:`, `CHECK:`, `REVERT:`, regression, crash, allocation, cache, event, context, sandbox, userdata, finalizer, JIT, profiling, and related terms are only the first pass. A commit becomes useful documentation when the implementation change can be generalized into an engineering lesson.

For example:

- a stale resolver fix becomes a lesson about invalidating derived state;
- a transition-generation fix becomes a lesson about rejecting stale deferred work;
- a failed GMST optimization becomes a lesson about measuring runtime representation instead of trusting semantic type;
- a reverted userdata cache becomes a lesson about testing engine/runtime optimizations against real workloads;
- a profiler cleanup bug becomes a lesson about protected execution as an invariant-restoration boundary rather than generic error suppression.

## Evidence categories

Every significant recommendation should be mentally classified as one of four things.

**Contract** means the engine, API, language, or data model requires it.

**Measured** means we have representative evidence that a choice changes behavior or performance.

**Derived** means it follows from known implementation details or engineering constraints, but may not have a benchmark attached to every use.

**Preference** means it is a style or architectural choice. Preferences can be strong. They must not masquerade as engine law.

See [Contracts, Measurements, Derivations, and Preferences](@/cod3x/docs/practice/evidence.md).

## Historical code is not automatically advice

An old repository is a laboratory, not scripture.

A historical example may be included because it is:

- a good pattern that survived;
- an intermediate design worth understanding;
- a bad pattern we now avoid;
- a failed experiment;
- an engine assumption that later changed;
- a useful demonstration of how a system evolved.

The page using it should say which one it is.

Starwind Builder is particularly valuable here. Some of its Community Patch Project code contains the ancestor of later H3 concepts. That makes it useful. It also contains patterns that Cod3x now explicitly discourages. That makes it useful too.

## Attribution

Community knowledge should remain attributable.

Where a concept, implementation, bug report, or educational structure comes from another contributor or project, preserve that lineage. Cod3x should absorb knowledge, not erase provenance.

The same standard applies internally. If a rule is here because a specific production bug hurt, link the commit when practical. The embarrassing commits are not liabilities. They are receipts.

For a compact map of especially useful source commits, see [Historical Evidence Index](@/cod3x/docs/reference/history-index.md).

For current implementations, start with [H3's API and examples](@/h3lp_yours3lf/docs/_index.md), [S3maphore's integration docs](@/s3maphore/docs/_index.md), [T4rg3t5's API](@/t4rg3t5/docs/_index.md), and [Pr0f1l3r](@/pr0f1l3r/index.md). A useful provenance chain is **principle → implementation → pinned history → current source**.
