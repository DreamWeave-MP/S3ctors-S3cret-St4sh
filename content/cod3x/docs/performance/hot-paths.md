---
title: Hot Paths, Hoisting, and Precomputation
description: Localize and precompute where the path is actually hot, not everywhere on principle.
weight: 20
extra:
  kind: guide
---

DreamWeave's production code deliberately localizes functions and precomputes values in hot modules.

That is a technique, not a religion.

## What localization can remove

Consider code that repeatedly does this:

```lua
if types.Actor.isDeathFinished(actor) then
  actor:sendEvent('SomethingChanged')
end
```

A hot module may instead bind frequently used operations once:

```lua
local IsDeathFinished = types.Actor.isDeathFinished
local SendEvent = actor.sendEvent
```

The potential savings are not mystical. You are avoiding repeated table/property resolution and, depending on the binding shape, potentially avoiding repeated wrapper lookup before the engine call.

S3maphore's actor code localizes operations such as:

- `core.isWorldPaused`;
- `core.sendGlobalEvent`;
- `AI.getTargets`;
- `AI.isFleeing`;
- actor type methods;
- `gameSelf.sendEvent`.

Its player combat code similarly hoists `gameSelf.type`, `gameSelf.id`, the health/level accessors, and frequently used table/string/math functions.

## Do not cargo-cult every local alias

In ordinary setup code, this:

```lua
local format = string.format
```

may make no measurable difference and can make the file harder to scan if every standard function is renamed.

Use localization when at least one of these is true:

- the operation occurs in a measured hot loop;
- it removes repeated traversal through an engine-backed object/type table;
- the alias improves clarity by naming the exact operation the module depends on;
- the module is performance infrastructure where lookup overhead accumulates at very high frequency.

Prefer readable aliases.

## Hoist stable object properties

St4sh [commit `c3e70aa5`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/c3e70aa5084e8042817f628cdef1eec7148ca9f7) hoisted `gameSelf.id` in a combat hot loop.

That is useful when the property is stable for the module lifetime and repeatedly used in an inner loop.

Do **not** hoist a property whose value can change unless the cache lifetime matches that change.

Performance and correctness share the same question: **what is the lifetime of this value?**

## Normalize input once

If conditions are registered once and evaluated thousands of times, do normalization at registration.

The SSS performance pass pre-lowercased condition data and removed redundant `lower()` work from hot evaluation paths.

General rule:

{{ schematic(data_path="data/schematics/hot-path-normalization.json") }}

This also improves error messages: malformed input fails near registration rather than halfway through gameplay.

## Prefer numeric loops for dense arrays in proven hot code

Several St4sh performance commits replaced `ipairs` with numeric loops in hot paths.

```lua
for index = 1, #actors do
  local actor = actors[index]
  -- hot work
end
```

This can give LuaJIT a simpler loop shape and avoids iterator overhead.

Do not rewrite every `ipairs` in documentation examples. Readability remains the default. Numeric loops become compelling when:

- the data is a dense sequence;
- the loop is hot;
- index access is natural;
- profiling says this layer matters.

## Reuse small tables carefully

S3maphore reuses some event payload tables and proxy tables to reduce allocation pressure.

That is safe only when consumers do not retain the table beyond the call/event contract.

A reused mutable payload that escapes is a time bomb.

When designing a borrowed/reused object, document the lifetime explicitly.

## Avoid repeated geometry queries

Camera and targeting work repeatedly taught the same lesson: engine geometry queries are not ordinary field reads.

Historical fixes include querying NPC bounding boxes once for stable target positions and larger rewrites to reduce lock-on raycasts and runtime operations.

If a frame path needs the same engine-derived value three times, query it once and keep it for the duration in which it is valid.

## Spread unavoidable work

S3maphore's combat polling uses a bounded batch size and a target latency rather than asking every nearby actor for combat state every frame.

That turns an O(N)-per-frame spike into a controlled stream of work.

The technique is useful when:

- state need not be globally fresh every single frame;
- latency has a known acceptable bound;
- work can be partitioned without violating correctness.

Do not batch correctness-critical work merely to make a graph look prettier.

## Fast paths are worth code when the common case is truly common

Cod3x [commit `4f488e47`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/4f488e4745a52447c526a10bb8c39cc35fb49eb6) changed its context parser to avoid constructing/masking a character array on simple lines. The parser first detects whether quotes, comments, or long brackets require the slow path. The commit reports up to roughly 30% better performance.

H3 Pattern: use [Budget](@/h3lp_yours3lf/docs/api/packages/budget.md), [Every](@/h3lp_yours3lf/docs/api/timing.md), or [Cooldown](@/h3lp_yours3lf/docs/api/timing.md) to make cadence and bounded work explicit before reaching for lower-level allocation tricks.

That is a classic useful fast path:

- common input is simpler than worst-case input;
- the fast predicate is cheap;
- slow behavior remains available for complex syntax;
- semantics are preserved;
- the improvement was measured.

Do not create a fast path whose detection costs as much as the work it avoids.

## The rule

Localize, hoist, normalize, reuse, and batch because a measured path justifies it.

Not because somebody once told you locals are fast.
