---
title: S3lf
description: The installed local/player interface for convenient access to the attached object.
weight: 10
extra:
  kind: api
---

{{ api_signature(value="require('openmw.interfaces').s3.lf → S3lfObject") }}

S3lf exposes frequently used object, type, record, and stat data through a lazily resolved view. It reduces repeated engine API indexing; it does not turn every engine value into a plain Lua value or remove the engine's restrictions.

{% usage_note(title="Installed interface · Local and player") %}
Enable H3's plugin and use the interface on an object where its provider is attached. This is not a global or menu interface. `I.s3.lf` is the current path; `I.s3lf` is not. Do not require the provider script as a constructor.
{% end %}

## Read the attached actor's health

```lua
local I = require 'openmw.interfaces'

local function reportHealth()
    local s3lf = assert(I.s3 and I.s3.lf, 'H3 S3lf interface is unavailable')
    local actor = s3lf.asActor()
    if actor then
        print(actor.recordId .. ': ' .. tostring(actor.health.current))
    end
end

return {
    engineHandlers = {
        onInit = reportHealth,
        onLoad = reportHealth,
    },
}
```

Use the [bootstrap's player-script registration](@/h3lp_yours3lf/docs/getting-started/overview.md). The lookup happens when the handler runs rather than assuming the interface is ready during another script's top-level evaluation.

## Selected members

| Member | Meaning |
| --- | --- |
| `id` | Game-object instance ID, not record ID. |
| `recordId` | Record identifier shared by instances of that record. |
| `object` | Underlying local game object. |
| `record` | Record data exposed as a field, not a record lookup function. |
| `health`, `magicka`, `fatigue` | Engine stat objects on actors; read their current/base fields as appropriate. |
| `actorType` | `0` player, `1` NPC, `2` creature, `3` non-actor. |
| `asActor()`, `asNPC()`, `asPlayer()`, `asCreature()`, `asNonActor()` | Same view narrowed to the matching type, or `nil`. NPC includes player. |
| `distance(other)` | Distance from the attached object's position to another object's position. |
| `sendObjectEvent(name, data?)` | Sends an event to the attached object. |

Bound type methods omit the object argument. For example, `actor.getStance()` and `actor.getEquipment(slot)` operate on the attached actor. Use dot calls: adding a colon would supply an extra argument. Availability still depends on the object type and underlying OpenMW API.

## Player-specific tracking

| Member | Meaning |
| --- | --- |
| `isInCombat()` | Whether tracked target data is nonempty and engine AI is enabled. |
| `targetData()` | Read-only map of tracked actor IDs to actor objects. |
| `cellsVisited` | Map of cell IDs observed by the player's update handler. |

Combat tracking consumes `OMWMusicCombatTargetsChanged`; it is not an independent scan of every fight in the world. Incoming reports produce `S3CombatTargetAdded` or `S3CombatTargetRemoved`, with the reporting actor as payload. Do not interpret repeated reports as a unique kill count or guaranteed deduplicated transition history.

`S3LFCellChanged` carries the previous cell ID when the player moves between known cells. The player provider saves its tracked target data and visited cells. Consumers should use the interface, not reach into that provider's save payload.

## Caching and lifetime

Most resolved members are cached; selected `openmw.self` keys are explicitly ignored or left uncached through H3's key-behavior table. Type values, type methods, stats, record values, object values, and animation values then follow their own lazy-cache paths. This is not a deep snapshot: cached engine stat objects can still expose current values. Do not infer that every cached scalar is refreshed each frame or that every field exists on every object. Retain the interface only for its valid script/object lifetime and read changing data when needed.

See [State and Context](@/h3lp_yours3lf/docs/concepts/state-and-context.md) for the distinction between wrappers, permissions, and persistent data.
