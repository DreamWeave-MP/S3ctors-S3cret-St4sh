---
name: openmw-ui-runtime-debugger
description: "OpenMW Lua UI runtime debugging: traces, event timing, stale callbacks, root lifetime, redraw/rebuild ordering, timers, and layout snapshots."
---

# OpenMW UI Runtime Debugger

Use this skill when UI behavior cannot be established statically: missing redraws, wrong event order, stale callbacks, destroyed roots, menu/inventory visibility interactions, timer races, or unexpected layout state.

## Runtime-First Workflow

1. Instrument the smallest relevant path.
2. Reproduce on the target OpenMW version and scenario.
3. Assert the disputed ordering from logs/traces.
4. Compare layout/snapshot state when structure or visibility is involved.
5. Separate request, mutation-applied, defer, redraw, destroy, and callback boundaries.
6. Remove temporary instrumentation once the claim is proved or disproved.
7. Retest the narrow reproduction.

## Trace Convention

Use stable one-line records, for example:

```text
OMWTRACE seq=<n> context=<global|player|menu|local> phase=<phase> event=<event> detail=<optional>
```

Example:

```text
OMWTRACE seq=12 context=player phase=request event=inventory_rebuild generation=4 visible=false
OMWTRACE seq=13 context=global phase=mutate event=inventory_rebuild generation=4
OMWTRACE seq=14 context=player phase=redraw event=inventory_rebuild generation=4 rootAlive=true
```

Keep only fields needed to prove the failure. Sequence numbers should be monotonic within the traced path.

## Ordering Discipline

A request is not proof that a mutation completed. When redraw correctness depends on engine work:

- trace the request;
- trace the point where the mutation is actually applied or acknowledged;
- trace any deliberate defer boundary;
- validate owner/root/generation/visibility immediately before redraw.

Do not assume an event callback may safely mutate UI synchronously merely because it was reached.

## Common Hazards

- Stale callbacks after rebuild/menu transitions.
- Destroyed or detached elements retained by closures.
- Visibility state suppressing expected work.
- Timers running after generation/context/visibility changed.
- Missing generation guards on deferred callbacks.
- UI mutation from the wrong script context.
- Snapshot differences caused by normal layout recalculation rather than the target bug.

## Retest Checklist

- Expected trace order is present.
- No new Lua/runtime errors appear.
- Snapshot/layout differences are either clean or explained.
- Deferred work has explicit ordering evidence when correctness depends on it.
- Stale callback, destroyed root, timer, visibility, and generation risks were checked.
- Temporary debug code is removed unless intentionally retained.
