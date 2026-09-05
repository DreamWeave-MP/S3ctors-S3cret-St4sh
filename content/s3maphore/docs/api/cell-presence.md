+++
title = "CellPresence"
description = "The asynchronous world scan that feeds PlaylistState."
weight = 40

[extra]
api_docs = true
kind = "advanced"
+++

`CellPresence` is the global synchronization record S3maphore builds while scanning the player's current cell. For actual playlist authoring, consume its player-side projection through [PlaylistState](@/s3maphore/docs/api/playlist-state.md). Do not require the internal collector or send its synchronization events yourself.

Think of it as a mailbox between two jobs: a global script scans world content, then the player script accepts the matching result and exposes it as `Playback.state`.

## Shape

| Field | Type | Meaning |
| --- | --- | --- |
| `byRecord` | `table<string, integer>` | Record ID to instance count. |
| `byType` | `table<string, integer>` | OpenMW type name to instance count. |
| `byContentFile` | `table<string, integer>` | Content file to object count. |
| `staticContentFiles` | `string[]` | Content files that contributed static objects. |
| `nearestRegion` | `string?` | Region found on the cell, or through an interior teleport door. |
| `cellHasHostileActors` | `boolean` | Hostile living actor in the player's current cell. |
| `areaHasHostileActors` | `boolean` | Hostile living actor anywhere in the scanned exterior area. |
| `cellId` | `string?` | Cell for which this scan was produced. |
| `generation` | `integer?` | Transition generation used to reject an older scan. |

## Scan scope

For an interior, S3maphore scans the current cell. For an actual exterior, it scans the current cell and the surrounding 3×3 grid. The center cell supplies `cellHasHostileActors`; any hostile actor in the nine-cell area makes `areaHasHostileActors` true.

Interior visits preserve an exterior snapshot so returning through the same door can avoid a complete rescan. When the exterior grid changes, old cells are removed and the new 3×3 is rebuilt.

## How it becomes PlaylistState

The player-side subscriber accepts a record only when `presence.cellId` matches the player's current cell. It then maps the fields like this:

| CellPresence | PlaylistState |
| --- | --- |
| `byRecord` | `objectsByRecord` |
| `byType` | `objectsByType` |
| `byContentFile` | `objectsByContentFile` |
| `staticContentFiles` | `staticObjectContentFiles` |
| `nearestRegion` | `nearestRegion` |
| `cellHasHostileActors` | `cellHasHostileActors` |
| `areaHasHostileActors` | `areaHasHostileActors` |

`PlaylistState.objectCount` is calculated from `byType` after the mapping.

## Timing and stale data

The scan is coroutine-based and may be spread across multiple update steps. A cell transition can start another scan before the old one has reached storage. `cellId` and `generation` let S3maphore reject that stale write.

The storage section is temporary. `CellPresence` is not ordinary save data and is not a stable persistence surface for other mods.

## What not to consume

These implementation events exist for S3maphore's own synchronization:

- `S3maphoreUpdatePresence`
- `S3maphoreCellPresenceUpdated`
- `S3maphoreWeatherChanged`
- `S3maphoreDeathCountIncrement`

Do not send them or build a mod around their payloads. Use `I.S3maphore.state`, `I.S3maphore.getState()`, and the built-in rules instead.

## Example: use the projection, not the mailbox

```lua
local DwemerObjects = {
    ['dwrv_ruin_scaffold_01'] = true,
}

local DwemerFiles = {
    ['morrowind.esm'] = true,
    ['tamriel rebuilt.esm'] = true,
}

return {
    {
        id = 'my-mod/dwemer-presence',
        priority = PlaylistPriority.CellExact,
        randomize = true,
        isValidCallback = function()
            local state = Playback.state
            return state.cellIsExterior
                and Playback.rules.objectExact(DwemerObjects)
                and Playback.rules.staticContentFile(DwemerFiles)
        end,
    },
}
```
