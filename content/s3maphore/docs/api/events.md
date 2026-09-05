+++
title = "Events"
description = "Player-scoped events for controlling playback and observing state changes."
weight = 70

[extra]
api_docs = true
kind = "events"
+++

S3maphore's public events live in the OpenMW `Player` scope. They are useful when a mod already communicates through events; for direct calls, the [I.S3maphore interface](@/s3maphore/docs/api/interface.md) is usually clearer.

## Control events

| Event | Payload | Effect |
| --- | --- | --- |
| `S3maphoreSkipTrack` | none | Stops the current track and lets normal resolution choose what comes next. |
| `S3maphoreToggleMusic` | `boolean?` | Enables or disables music. `nil` toggles the current setting. |
| `S3maphoreSetPlaylistActive` | `{ playlist: string, state: boolean }` | Enables or disables a registered playlist, then reevaluates selection. |
| `S3maphoreSpecialTrack` | `{ trackPath: string, reason?: S3maphoreStateChangeReason }` | Plays one VFS track as a one-shot special track. |
| `S3maphoreSetDeathTrack` | `string` | Sets the death-track VFS path if the file exists. |
| `S3maphoreResetDeathTrack` | none | Restores the default death-track path. |

Events sent to the player should use the player's object as the target. The exact call varies with the script context that sends it; from a player script:

```lua
local self = require 'openmw.self'

self.sendEvent(self, 'S3maphoreSetPlaylistActive', {
    playlist = 'my-mod/storm-explore',
    state = true,
})
```

See [Death Track](@/s3maphore/docs/api/death-track.md) for the complete set/reset and save/load contract.

## Notifications

### `S3maphoreTrackChanged`

```lua
S3maphorePlaybackChangeEventData = {
    fadeOut?: number,
    cellId?: string,
    playbackEpoch?: integer,
    playlistId: string,
    reason: S3maphoreStateChangeReason,
    trackName: string,
}
```

Emitted when S3maphore accepts a normal or special track change. `trackName` is the VFS path. `playlistId` identifies the playlist that supplied the track. `fadeOut` is the requested transition duration.

For normal changes, `cellId` and `playbackEpoch` describe the request generation. Treat them as read-only metadata; consumers that defer work can use them to reject stale events. Special-track events do not necessarily carry normal playback sequencing fields.

```lua
local I = require 'openmw.interfaces'

I.S3maphore.addTrackChangedHandler(function(event)
    print(('%s: %s'):format(event.playlistId, event.trackName))
end)
```

### `S3maphoreMusicStopped`

```lua
{ reason: S3maphoreStateChangeReason }
```

Emitted when playback stops because music was disabled or no playlist was valid during resolution.

## Batched combat checks

### `S3maphoreCheckCombat`

`S3maphoreCheckCombat` is an advanced event for sharing S3maphore's actor-combat polling architecture with other mods. It is sent to one nearby actor at a time and has no payload or return value.

The expensive operation here is asking every actor's AI system for its combat targets. Putting that query in an `onUpdate` handler on every actor scales with the number of loaded actors. S3maphore already provides the player-side polling and batching:

1. The player script walks the `nearby.actors` collection from `openmw.nearby` in a round-robin cycle.
2. It sends `S3maphoreCheckCombat` to only a bounded batch of actors.
3. The local actor script checks its AI targets.
4. The actor sends `OMWMusicCombatTargetsChanged` to nearby players only when its target list changes.

The batch size is calculated from the player's `dt` and clamped between 4 and 16 actors. The target is to revisit the actor list roughly every one-third of a second. A downstream mod does not need to send these requests or implement its own scheduler. Add an `S3maphoreCheckCombat` handler to an actor-local script and S3maphore will invoke it as each nearby actor is polled:

```lua
local AI = require('openmw.interfaces').AI

local inCombat = false

local function updateCombatState()
    local newInCombat = #AI.getTargets('Combat') > 0
    if newInCombat ~= inCombat then inCombat = newInCombat end
end

return {
    eventHandlers = {
        S3maphoreCheckCombat = updateCombatState,
    },
}
```

The actor-local systems that care about combat can read `inCombat` or react when that value changes. The event handler's return value is discarded; the useful result is the state update.

This is a direct replacement for **per-actor** `onUpdate`. The downstream script only supplies the actor-side handler; S3maphore supplies the scheduler, round-robin traversal, and bounded request batches. The important rule is that expensive actor queries are event-driven and bounded instead of running once per actor every frame.

The S3maphore actor script skips unnecessary AI queries for dead, out-of-range, idle, unarmed actors. When a query is needed, it uses `AI.getTargets('Combat')`. Results are reported through `OMWMusicCombatTargetsChanged`:

```lua
return {
    eventHandlers = {
        OMWMusicCombatTargetsChanged = function(data)
            local actor = data.actor
            local targets = data.targets
        end,
    },
}
```

`data.actor` is the actor that was checked and `data.targets` is its current combat-target array. Treat both the payload and target array as read-only; the actor script owns the underlying table. The event is sent to nearby players, so a player script can maintain its own combat projection without re-querying every actor.

This contract requires S3maphore's local actor script to be loaded for the actors being checked. `S3maphoreCheckCombat` is deliberately narrow: it carries no custom request data and only asks S3maphore's actor handler to refresh combat state. Use a separate event name for unrelated actor work.

## State reevaluation

### `S3maphoreStateChanged`

The payload is an integer bitmask. It requests playlist reevaluation after one or more of these changes:

| Flag | Value |
| --- | ---: |
| `S3maphore.const.STATE_FLAGS.TOD` | `1` |
| `S3maphore.const.STATE_FLAGS.MOVEMENT` | `2` |
| `S3maphore.const.STATE_FLAGS.SPELL_SCHOOL` | `4` |
| `S3maphore.const.STATE_FLAGS.STANCE` | `8` |

Use bitwise checks when handling a combined value. Most playlist authors should not send this event; S3maphore's own state producers send it when appropriate.

### State-change reasons

`event.reason` uses `I.S3maphore.const.STATE`:

| Reason | Value | Meaning |
| --- | --- | --- |
| `Died` | `DIED` | Death-track playback. |
| `Disabled` | `DSBL` | Playback was disabled. |
| `NoPlaylist` | `NPLS` | No valid playlist was available. |
| `PlaylistChanged` | `PLCH` | The selected playlist changed. |
| `SpecialTrackPlaying` | `SPTR` | A special track was requested. |
| `TrackChanged` | `TRCH` | Normal track sequencing changed the track. |

## Internal synchronization events

These events exist between S3maphore's global and player scripts. They are not a supported integration surface:

| Event | Payload |
| --- | --- |
| `S3maphoreUpdatePresence` | Presence request data |
| `S3maphoreCellPresenceUpdated` | `{ cellId: string, generation: integer }` |
| `S3maphoreWeatherChanged` | Weather record ID |
| `S3maphoreDeathCountIncrement` | Killed actor record ID |
| `S3maphoreClearTargetCache` | Hit actor object |
| `S3maphoreInitializationComplete` | Initialization data |

Do not send these events or depend on their payloads. Use [PlaylistState](@/s3maphore/docs/api/playlist-state.md) and the public interface instead.
