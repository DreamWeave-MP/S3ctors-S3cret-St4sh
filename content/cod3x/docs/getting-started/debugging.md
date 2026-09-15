---
title: Debugging OpenMW Lua
description: Preserve the first useful failure, reduce the mechanism, and inspect the engine boundary instead of guessing.
weight: 70
extra:
  kind: guide
---

Debugging OpenMW Lua gets dramatically easier when failures are allowed to remain specific.

The worst debugging architecture is one that catches the original error, keeps running with half-updated state, and finally fails somewhere unrelated three callbacks later.

Start with the first wound.

## Preserve the traceback

If an error crosses a boundary you intentionally protect, preserve enough information to reconstruct the call path.

DreamScripts contains multiple historical fixes whose entire lesson is that protected execution without a useful traceback is not useful error handling. [Commits `c8737a3`](https://github.com/DreamWeave-MP/DreamScripts/commit/c8737a31b9af36d70320bec8dc38ea0c906bfba6) and [`0e7eb8d`](https://github.com/DreamWeave-MP/DreamScripts/commit/0e7eb8d3906af34abaa628fa338672ebc8deb75a) corrected error paths so the traceback was actually emitted.

A useful failure report should normally identify:

- the original message;
- traceback when available;
- script/context involved;
- object, record, event, path, or registration ID involved;
- whether execution stopped or continued;
- any version/build information needed to reproduce the engine behavior.

Do not replace all of that with `something went wrong`.

## Reproduce before theorizing

Reduce the problem to the smallest repeatable action.

If the failure appears to depend on:

- entering a cell;
- loading a save;
- switching UI modes;
- one record type;
- a particular event ordering;
- one configuration field;

make that dependency explicit before changing architecture.

A reliable reproducer is worth more than a plausible theory.

## Ask which layer is wrong

A symptom in Lua does not prove the bug is in Lua.

The relevant layers may include:

1. your script state;
2. OpenMW's Lua API contract;
3. the C++ binding representation;
4. engine state or game data;
5. LuaJIT behavior;
6. a fork/runtime-specific facility.

The GMST optimization failure documented under Paid For With Blood is a perfect example: code that looked numerically trivial was actually interacting with userdata-backed values.

## Check context before API semantics

When `require 'openmw.foo'` fails or Cod3x reports an unavailable module, first confirm the active script context.

Do not spend an hour debugging a function signature when the module cannot exist in that sandbox.

See [Script Contexts](@/cod3x/docs/getting-started/contexts.md) and [Context Availability Is a Contract](@/cod3x/docs/paid-for-with-blood/context-availability.md).

## Check object validity and lifetime

OpenMW objects are engine-backed references. A reference can outlive the state in which it was useful.

Before blaming an unrelated accessor, ask:

- is this object still valid?
- is it loaded?
- does it still have a cell?
- was this work deferred across a transition?
- are we holding a transient object where an ID would be safer?

Stale work is a lifecycle bug until proven otherwise.

## Use logging to establish ordering

When the bug depends on event/lifecycle ordering, log the transitions rather than every local variable.

Useful logs look like:

```text
transition=17 cell=Vivec start
transition=17 presence-request sent
transition=18 cell=Ald-ruhn start
transition=17 presence-response rejected stale=true
```

That tells you which invariant held or failed.

A wall of `x = 1`, `x = 2`, `x = 3` rarely does.

## Profile performance bugs, do not debug them by aesthetic preference

If the bug is "this is slow":

1. reproduce the slowdown;
2. count the work;
3. time the work;
4. identify allocations if relevant;
5. inspect bytecode/traces only if Lua execution remains material;
6. inspect engine-bound calls if they dominate.

See [Measure First](@/cod3x/docs/performance/measure-first.md) and [Pr0f1l3r](@/cod3x/docs/performance/pr0f1l3r.md).

## Reduce, then source-dive

Once the mechanism is narrow enough, inspect OpenMW source instead of inventing semantics from observations.

A five-minute source read is often cheaper than a twenty-commit workaround around an assumption that was never true.

See [Source Diving](@/cod3x/docs/tooling/source-diving.md).
