---
title: Make Two Scripts Talk
description: Choose direct calls, events, or interfaces by ownership and direction.
weight: 80
extra:
  kind: guide
---

You have a `player.lua` and a `global.lua`. How do they exchange information?

Start with the receiver. Does it own an object? Does the message cross contexts? Is the other script publishing a capability rather than announcing an occurrence?

## A local event tells one object something

The receiver is a local script attached to an object:

```lua
---@omw-context local

return {
    eventHandlers = {
        MyModSetMarked = function(marked)
            print('The attached object is marked:', marked)
        end,
    },
}
```

The sender needs a target object and sends to that object:

```lua
target:sendEvent('MyModSetMarked', true)
```

Use a local event when the target object naturally owns the behavior.

## A global event crosses into global infrastructure

The player script can announce a world-level event:

```lua
---@omw-context player

local core = require 'openmw.core'

core.sendGlobalEvent('MyModVisitRecorded', { cellId = 'Balmora' })
```

The global script receives it:

```lua
---@omw-context global

return {
    eventHandlers = {
        MyModVisitRecorded = function(data)
            print('Visited:', data.cellId)
        end,
    },
}
```

Keep event payloads small and deliberate. An event is an engine-managed boundary, not a convenient pipe for every private table in your program.

## An interface exposes a capability

An interface is for a provider that owns a stable thing another script wants to call or query. For example, a player script can consume H3's attached-object interface:

```lua
---@omw-context player

local interfaces = require 'openmw.interfaces'
local actor = interfaces.s3.lf.asActor()

if actor then
    print(actor.recordId)
end
```

The player is not announcing that something happened. It is asking an owner for a capability. That is an interface-shaped question.

## The tiny decision table

| Question | Start with |
| --- | --- |
| Can a compatible module call the code directly? | A normal Lua function/module call. |
| Does one object own the receiver? | A local event. |
| Does the message cross to global infrastructure? | A global event. |
| Does another script need a stable query or operation? | An interface. |

For the formal version, read [Events and Interfaces](@/cod3x/docs/getting-started/events-and-interfaces.md). Next, learn what the objects and records in those messages actually are in [Objects, Records, and Cells](@/cod3x/docs/zero-to-hero/objects-records-cells.md).
