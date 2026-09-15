---
title: Effective OpenMW Lua Foundations
description: "The basic discipline carried forward from Effective OpenMW Lua: narrow scope, explicit control flow, clear tables, and functions with one job."
weight: 15
extra:
  kind: guide
---

Cod3x does not assume that advanced engine work makes the basics obsolete.

The opposite is true.

The deeper a mod gets into engine state, asynchronous callbacks, UI, storage, events, and performance-sensitive work, the more expensive sloppy fundamentals become.

This page carries forward the useful core of Yvan/Hebi's historical *Effective OpenMW Lua* effort and modernizes it for current OpenMW scripting.

## Local by default

Use the narrowest scope that owns the value.

```lua
local core = require 'openmw.core'

local function formatRecordId(recordId)
  return recordId:lower()
end
```

Avoid creating globals accidentally:

```lua
-- Bad: mutates the script environment.
currentTarget = object
```

Prefer:

```lua
local currentTarget = object
```

OpenMW scripts already have enough implicit environment supplied by the engine. Do not add invisible application state through accidental globals.

## Scope is ownership

A local variable should normally live only as long as the state it represents.

Use function scope for temporary work.

Use module scope for module-owned state.

Use storage or save data for state that intentionally survives the script instance/lifecycle boundary.

Do not hoist values to module scope merely because local access can be faster. Performance never justifies changing semantic lifetime without evidence.

## Prefer simple conditionals

Write conditions so the reason for each branch is visible.

Prefer:

```lua
if not object:isValid() then return end
if not object.cell then return end
if not shouldProcess(object) then return end

process(object)
```

when the alternative is a pyramid of nested conditions.

Do not turn every boolean into a clever expression. The reader should be able to identify which invariant failed.

## Functions should establish a useful contract

A function is not valuable merely because code can be moved into it.

Good reasons to extract a function include:

- one operation has a meaningful name;
- the behavior is reused;
- the operation has an invariant worth isolating;
- the function creates a useful test seam;
- a slow path can be separated from a hot path.

Weak reasons include:

- reducing line count;
- making every three-line sequence "DRY";
- hiding a dependency that callers still need to understand.

## Know whether a table is a sequence, map, state object, or API

Lua uses one table type for many jobs. Your code still needs to know which job a specific table performs.

A sequence has dense numeric indices and can use `#`/numeric iteration under the appropriate assumptions.

A map is keyed by identity and should not be treated like a sequence.

A state table has an owner and lifecycle.

An interface table is public API.

A cache has key identity and invalidation rules.

Do not blur those categories because they happen to share `{}` syntax.

## Normalize names and keys once

If external data is case-insensitive, normalize it at ingress.

If an event name has one canonical representation, establish it before registration.

DreamScripts repeatedly moved toward lowercased/canonical registration keys because letting each lookup decide how to compare names invites missed matches and repeated work.

See [Validate and Normalize at Ingress](@/cod3x/docs/practice/ingress.md).

## Do not use errors as routine branching

An error is for a failed contract, not ordinary control flow.

Likewise, `pcall` is not a replacement for `if`.

Use explicit conditions for expected states. Let violated invariants fail loudly unless a real boundary can recover.

See [Error Handling](@/cod3x/docs/practice/error-handling.md).

## Keep state transitions legible

When a function mutates several pieces of state, separate the phases.

```lua
local previousTarget = currentTarget
currentTarget = nextTarget

if previousTarget == currentTarget then return end

notifyTargetChanged(previousTarget, currentTarget)
```

This is preferable to burying mutation inside a call expression or metatable side effect where the transition is difficult to see.

## Use comments only for information code cannot carry

The historical Effective OpenMW Lua work emphasized readable structure. Cod3x pushes that further.

Do not narrate:

```lua
-- Set active to true.
state.active = true
```

Document the non-obvious contract instead:

```lua
-- The generation must change before deferred callbacks are scheduled so stale work can reject itself.
state.generation = state.generation + 1
```

And if names/structure can express the rule without the comment, prefer that.

## The basics survive optimization

Advanced OpenMW Lua may eventually involve:

- engine binding costs;
- bytecode;
- traces;
- userdata;
- allocation;
- GC behavior;
- runtime changes.

None of those excuse unreadable control flow.

The best performance work in the St4sh generally makes the code *more explicit*: fewer repeated operations, narrower hot paths, canonical data, clearer ownership, and less hidden work.

Start simple enough that you can still tell what you optimized later.
