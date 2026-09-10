---
title: S3LockOn Interface
description: The player-scoped T4rg3t5 interface for settings, target state, and lock-on integration.
weight: 50
extra:
  api_docs: true
  kind: interface
---

`I.S3LockOn` lives in the player context. Guard it if T4rg3t5 is optional.

```lua
---@omw-context player
local I = require 'openmw.interfaces'
local Manager = I.S3LockOn and I.S3LockOn.Manager

if Manager then
    local target = Manager.getTargetObject()
    if target and target:isValid() then
        -- Use the current target.
    end
end
```

The current interface version is `2`.

## Manager

`I.S3LockOn.Manager` exposes T4rg3t5's supported live state and settings through a H3lp Yours3lf `ProtectedTable`.

Anything documented below is fair game. `Manager.state`, camera internals, frame handlers, and anything else hanging off the table are implementation details. Poke at ’em if you like; just don’t build your house there.

See [Settings](@/t4rg3t5/docs/api/settings.md) for configurable fields and the [ProtectedTable documentation](@/h3lp_yours3lf/index.md#protectedtable) for the shared model.

## Manager methods

| Member | Signature | Behavior |
| --- | --- | --- |
| `getTargetObject` | `fun() → openmw.LObject?` | Returns the semantic target, or `nil`; validate the handle before use. |
| `targetIsActor` | `fun() → boolean` | Returns whether the current target is a valid actor. |
| `getMarkerVisibility` | `fun() → boolean` | Returns marker presentation state; do not use it as lock state. |
| `selectNearestTarget` | `fun(goLeft?) → openmw.LObject?` | Selects the nearest eligible combat target; `true` restricts the search to the left side, `false` to the right, and `nil` to both sides. |
| `shouldTrack` | `fun() → boolean` | Returns whether player-facing tracking is enabled. |
| `setTrackingState` | `fun(state: boolean)` | Temporarily enables or disables player-facing tracking. |
| `getLockOnFileName` | `fun(baseName: string) → string` | Returns the VFS path for a marker texture. |
| `isBouncing` | `fun() → boolean` | Returns whether hit-marker feedback is active. |

## Target control

Use `S3TargetLockOnto` to request target changes and observe accepted transitions. See [Events](@/t4rg3t5/docs/api/events.md) for the protocol.

## Crosshair ownership

T4rg3t5 owns vanilla crosshair visibility while locking. It hides the crosshair on acquisition and shows it when the target clears. It doesn't restore a previous state, so two crosshair mods trying to own vanilla visibility at once are liable to have a custody dispute.
