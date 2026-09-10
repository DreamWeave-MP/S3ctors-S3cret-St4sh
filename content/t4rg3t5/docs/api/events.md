---
title: Events
description: Player-scoped events for controlling target lock-on and observing target changes.
weight: 60
extra:
  api_docs: true
  kind: events
---

## `S3TargetLockOnto`

T4rg3t5's target event works both ways.

Send an actor to request a lock, or `nil` to clear it. T4rg3t5 emits the same payload after its own target changes.

A lock request is accepted only for a valid actor while targeting is enabled. If you need the current truth, ask the [Manager](@/t4rg3t5/docs/api/interface.md) for `getTargetObject()`.

Notifications happen after the target changes. They're useful for reacting to a lock, not vetoing it.

```lua
---@omw-context player
local self = require 'openmw.self'

local function requestLock(target)
    if not target or not target:isValid() then return end
    self:sendEvent('S3TargetLockOnto', target)
end

local function requestUnlock()
    self:sendEvent('S3TargetLockOnto', nil)
end
```

See the [target event observer example](@/t4rg3t5/docs/examples/target-event-observer.md).

## `S3TargetLockHit`

Carries the object hit by the player and drives target-marker hit feedback. Most mods can ignore this; send it only when integrating another hit source with T4rg3t5's marker effects.

## `S3TargetLock` trigger

`S3TargetLock` toggles the normal lock lifecycle. It's bound through `S3TargetLockBinding`, and a player script can activate it directly:

```lua
---@omw-context player
require 'openmw.input'.activateTrigger('S3TargetLock')
```

It selects a target when unlocked and clears the target when locked. Use `Manager.getTargetObject()` for lock state; marker visibility is just presentation.
