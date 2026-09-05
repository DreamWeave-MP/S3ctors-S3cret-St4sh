+++
title = "PlaylistState"
description = "The contextual state available to every playlist callback."
weight = 30

[extra]
api_docs = true
kind = "state"
+++

`PlaylistState` is the read-only context behind `Playback.state` and `I.S3maphore.state`. It describes the player's location, nearby content, combat, player condition, and the current playback inputs. `Playback` is provided by the [PlaylistEnvironment](@/s3maphore/docs/api/playlist-environment.md).

Inside a playlist callback:

```lua
isValidCallback = function()
    return Playback.state.cellIsExterior
        and Playback.state.weather == 'rain'
        and not Playback.state.isInCombat
end
```

`I.S3maphore.getState()` returns a read-only snapshot. `I.S3maphore.state` is a live read-only proxy. A snapshot is useful when inspecting several values together; the live proxy is the normal choice inside a callback.

## Location

| Field | Type | Meaning |
| --- | --- | --- |
| `cellName` | `string` | Lowercased cell name. For an unnamed cell, this is the lowercased cell ID. |
| `cellId` | `string` | Engine cell identifier. Use it for cache/debug keys; prefer `cellName` for portable playlist rules. |
| `cellIsExterior` | `boolean` | Whether the cell is exterior-like. Cells tagged `QuasiExterior` also return `true`. |
| `currentGrid` | `{ x: integer, y: integer }?` | The current actual exterior grid coordinate. `nil` indoors and in quasi-exteriors. |
| `nearestRegion` | `string?` | The current region, lowercased by the engine data. For interiors without a region, a teleport door destination may provide it. |
| `weather` | `string?` | Current weather record ID. It may be unavailable during initial setup. |
| `cellHasWater` | `boolean` | Whether the current cell has water. |
| `cellWaterLevel` | `number?` | Water level when the current cell provides one. |
| `playlistTimeOfDay` | `TimeOfDay` | One of `night`, `morning`, `afternoon`, or `evening`. |

`currentGrid` is the actual exterior coordinate, not a 3×3 area. The area used by presence collection is described in [CellPresence](@/s3maphore/docs/api/cell-presence.md).

## Presence

| Field | Type | Meaning |
| --- | --- | --- |
| `objectsByRecord` | `table<string, integer>` | Record ID to instance count in the current cell or exterior 3×3 grid. |
| `objectsByType` | `table<string, integer>` | OpenMW type name to instance count, such as `Static`, `Container`, `NPC`, or `Creature`. |
| `objectsByContentFile` | `table<string, integer>` | Content file to object count. |
| `staticObjectContentFiles` | `string[]` | Content files that contributed static objects. |
| `objectCount` | `number` | Total object count, computed from `objectsByType`. |

Counts are counts of instances, not merely presence flags. A lookup such as `state.objectsByRecord['some_id']` returns the number of instances, or `nil` when the record is absent. The built-in [presence rules](@/s3maphore/docs/api/rules/presence.md) apply the common checks for you.

## Hostility and combat

| Field | Type | Meaning |
| --- | --- | --- |
| `cellHasHostileActors` | `boolean` | A living actor in the player's current cell has a sufficiently high fight value. |
| `areaHasHostileActors` | `boolean` | A living hostile actor exists anywhere in the current exterior 3×3 grid. Indoors this reflects the current cell. |
| `combatTargets` | `openmw.LObject[]` | Current combat targets in insertion order. |
| `isInCombat` | `boolean` | Music-adjusted combat state. It reflects the `BattleEnabled` setting. |
| `isExploring` | `boolean` | Music-adjusted exploration state. It is distinct from `not isInCombat` because settings can disable exploration music. |

`I.S3maphore.isInCombat()` is the raw combat query and does not apply the music setting. `state.isInCombat` is the value intended for playlist selection.

## Player state

| Field | Type | Meaning |
| --- | --- | --- |
| `normalizedHealth` | `number` | Current health divided by base health, rounded to two decimals. |
| `normalizedMagicka` | `number` | Current magicka divided by base magicka, rounded to two decimals. |
| `normalizedFatigue` | `number` | Current fatigue divided by base fatigue, rounded to two decimals. |
| `movementMode` | `string` | `standing`, `walking`, `running`, `sneaking`, `swimming`, or `flying`. |
| `selectedSpellSchool` | `string?` | The selected spell's school, such as `destruction`, or `nil` when no spell is selected. |

These normalized values describe the player. [The `dynamicStatThreshold` rule](@/s3maphore/docs/api/rules/combat.md#dynamicstatthreshold) describes combat-target percentages instead.

## Persistence

| Field | Type | Meaning |
| --- | --- | --- |
| `killCounts` | `table<string, number>` | Global counts of actors that have died during the playthrough. `TotalKills` is the aggregate. This does not prove that the player caused the death. |

State tables are read-only at the top level. Treat nested maps and arrays as engine-owned data: read them, do not mutate them or retain assumptions about their identity between updates.

## Example: combine state and rules

```lua
local ExploreCells = {
    ['bitter coast'] = true,
    ['ashlands'] = true,
}

local Weather = {
    rain = true,
    thunder = true,
}

return {
    {
        id = 'my-mod/storm-explore',
        priority = PlaylistPriority.Explore,
        randomize = true,
        isValidCallback = function()
            local state = Playback.state
            return state.isExploring
                and state.cellIsExterior
                and Playback.rules.region(ExploreCells)
                and Playback.rules.weatherType(Weather)
        end,
    },
}
```
