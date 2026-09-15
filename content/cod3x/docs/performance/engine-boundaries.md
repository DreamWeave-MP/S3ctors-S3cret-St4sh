---
title: Engine Boundaries
description: The Lua code is only one layer; bindings, userdata, queries, and C++ work often dominate.
weight: 40
extra:
  kind: guide
---

An OpenMW API call is not equivalent to calling a pure Lua function.

The path may involve:

{{ schematic(data_path="data/schematics/engine-boundary.json") }}

The exact path depends on the API, but the important lesson is general: **optimize the boundary you actually cross.**

## Bound methods can hide work

A property such as `object.position` may return a value userdata. A method such as `getBoundingBox()` can compute/construct a result. A type function can query engine state. A ray cast can involve physics/world traversal.

Do not reason about these using only Lua syntax size.

```lua
local center = object:getBoundingBox().center
```

looks tiny. The work is not necessarily tiny.

## Returned value types can allocate

OpenMW's vector and related value types historically pass through Sol-bound userdata paths.

Rubic0n's OpenMW userdata benchmark was created specifically to reproduce common value-return patterns without booting the full engine:

{{ schematic(data_path="data/schematics/engine-boundary-allocation.json") }}

That is why a chain of innocent-looking vector producers can become an allocation/GC problem.

The benchmark does not mean “never use vectors.” It gives us a mechanism for understanding when vector-heavy hot paths create pressure.

## JIT compilation cannot erase an engine call

LuaJIT can optimize Lua around a C boundary, but it cannot transform arbitrary engine internals into traced Lua.

If a loop is dominated by a C++ query, perfect trace formation around it may not move the result much.

The better optimization may be:

- call less often;
- move query outside the inner loop;
- cache for a valid lifetime;
- restructure ownership so the state is observed where it naturally changes;
- add a narrower/faster engine API.

## Localize the binding lookup only when it matters

S3maphore localizes frequently used engine functions because the call path is hot enough that repeated property resolution itself can accumulate.

That optimization does **not** make the C++ operation free.

Always distinguish:

{{ schematic(data_path="data/schematics/engine-boundary-cost.json") }}

The dominant term decides the strategy.

## Userdata is not a Lua table

Do not assume table idioms apply to engine wrappers.

Historical St4sh [commit `3649154c`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/3649154c732e0bfaa87d781ad587fd02aaac1643) fixed code that attempted to iterate CellPresence elements with table-oriented `next` patterns even though the values were userdata.

DreamScripts similarly discovered that GMST values that looked semantically numeric were userdata at runtime.

Runtime representation matters.

See [Userdata Is Not a Table](@/cod3x/docs/paid-for-with-blood/userdata-is-not-table.md) and [The Number Was Userdata](@/cod3x/docs/paid-for-with-blood/gmst-userdata.md).

## Crossing context boundaries also costs architecture

Events and storage subscriptions are engine-mediated coordination mechanisms.

Even if their raw CPU cost is acceptable, they add:

- payload construction;
- scheduling/dispatch;
- lifetime questions;
- serialization constraints;
- stale-message possibilities.

A direct interface call inside the same context can be both faster and easier to reason about when it fits the ownership model.

## When the boundary itself is the problem

At some point Lua-side changes stop being enough.

Rubic0n exists because profiling pushed into allocation, userdata finalization, GC pacing, and LuaJIT runtime behavior. Some experiments helped; some were reverted; some required explicit embedder contracts that ordinary mod code cannot safely touch.

That work is valuable to mod authors because it teaches where the ceiling comes from.

See [When Lua-Side Optimization Stops Being Enough](@/cod3x/docs/performance/rubic0n.md).
