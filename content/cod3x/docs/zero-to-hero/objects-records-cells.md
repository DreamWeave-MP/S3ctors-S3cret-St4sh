---
title: Objects, Records, and Cells
description: Tell runtime instances from content definitions and locations before building on them.
weight: 90
extra:
  kind: guide
---

OpenMW answers several different questions with several different things. “What is this?” might mean an object instance, a record definition, a concrete type, or a location.

## An object is an instance

An object is one runtime thing in the world or an inventory:

```lua
local instanceId = object.id
local recordId = object.recordId
```

`object.id` identifies this instance. `object.recordId` identifies the content definition it came from. Three iron swords can share one record ID and have three different object IDs.

## A record is a definition

A record describes content: a weapon, NPC, creature, door, or another game category. It is not the live object that can move, be disabled, enter a container, or become invalid.

When you already know the type, ask the type API for its record:

```lua
local types = require 'openmw.types'
local record = types.Weapon.record(object)
```

Use a record ID for metadata about a definition. Use an object ID for state about one live instance.

## A type gives the object meaning

The generic object surface cannot tell you every operation the object supports. `openmw.types` provides concrete APIs:

```lua
local types = require 'openmw.types'

if types.Actor.objectIsInstance(object) then
    local health = types.Actor.stats.dynamic.health(object)
end
```

Do not infer a type from a name or record ID when OpenMW provides a predicate.

## A cell is a location and a lifecycle boundary

An object's `cell` may be `nil` while the object is in an inventory, container, or transitional loading state:

```lua
local cell = object.cell
if not cell then
    return
end

print(cell.id)
```

Cell changes affect which objects exist, which handles remain useful, and when cached or deferred work becomes stale. Treat a cell transition as more than a string changing.

## Find the right question

- Need one live thing? Find an object.
- Need the definition shared by many things? Read a record.
- Need actor or weapon behavior? Use a type API.
- Need where a thing currently is? Inspect its cell, if the object can be in the world.

The full map is in [Objects, Records, Types, and Cells](@/cod3x/docs/getting-started/objects-records-types.md). Next, decide which facts should survive in [Keep Some State](@/cod3x/docs/zero-to-hero/keep-state.md).
