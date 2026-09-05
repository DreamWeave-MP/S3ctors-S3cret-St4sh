+++
title = "I.S3maphore"
description = "The player-scoped interface for controlling and inspecting S3maphore."
weight = 50

[extra]
api_docs = true
kind = "interface"
+++

S3maphore registers `I.S3maphore` in the OpenMW `Player` context. Other scripts can obtain it with `require 'openmw.interfaces'` after the player script has initialized.

```lua
local I = require 'openmw.interfaces'
local S3maphore = I.S3maphore
```

## Playback control

| Member | Signature | Behavior |
| --- | --- | --- |
| `skipTrack` | `fun()` | Stops the current track. Normal resolution chooses the next track or playlist. |
| `playSpecialTrack` | `fun(trackPath, reason?)` | Plays one VFS track as a one-off special track. |
| `overrideMusicEnabled` | `fun(enabled?)` | Sets whether music playback is enabled. With `nil`, toggles the current value. |
| `getEnabled` | `fun() → boolean` | Returns whether music playback is enabled. |
| `setPlaylistActive` | `fun(id, state)` | Enables or disables a registered playlist. |
| `getDeathTrack` | `fun() → string` | Returns the currently configured death-track VFS path. |
| `setDeathTrack` | `fun(path: string)` | Sets the death-track VFS path when the file exists. |
| `resetDeathTrack` | `fun()` | Restores the default death-track path. |

## Inspection

| Member | Signature | Behavior |
| --- | --- | --- |
| `getCurrentPlaylist` | `fun() → ReadOnlyTable?` | Read-only snapshot of the playlist that supplied the current track, or `nil`. |
| `getCurrentTrack` | `fun() → string?` | Current VFS track path, or `nil`. |
| `getCurrentTrackInfo` | `fun() → PlaylistMetadata?, TrackMetadata?` | Metadata for the current playlist and track. Returns `nil, nil` when stopped. See [Playlist and Track Metadata](@/s3maphore/docs/api/metadata.md). |
| `getRegisteredPlaylists` | `fun() → ReadOnlyTable` | Read-only map of registered playlist definitions. |
| `listPlaylistFiles` | `fun() → ReadOnlyTable` | Read-only list of recognized `.lua` playlist files under `Playlists/`. |
| `listPlaylistsByPriority` | `fun() → string` | Formatted priority listing, mainly for the `luap` console. |
| `getState` | `fun() → ReadOnlyTable` | Read-only `PlaylistState` snapshot. |
| `silenceTime` | `fun() → number` | Remaining silence interval in seconds. |

## Registration and callbacks

| Member | Signature | Behavior |
| --- | --- | --- |
| `registerPlaylist` | `fun(playlist: S3maphorePlaylist)` | Initializes missing fields, discovers folder-derived tracks, assigns registration order, persists activation state, and sorts the playlist into its priority group. |
| `addTrackChangedHandler` | `fun(handler: TrackChangedHandler)` | Registers a callback receiving `S3maphorePlaybackChangeEventData` whenever S3maphore accepts a track change. |

Handlers should return quickly and treat event data as read-only.

## State, rules, and metadata

| Member | Meaning |
| --- | --- |
| `state` | Live read-only [PlaylistState](@/s3maphore/docs/api/playlist-state.md) proxy. |
| `rules` | Complete [PlaylistRules](@/s3maphore/docs/api/rules/_index.md) table. |
| `playlistMetadata` | Metadata registry for playlist names and track information. See [Playlist and Track Metadata](@/s3maphore/docs/api/metadata.md). |
| `playlistTimeOfDay()` | Current `TimeOfDay` bucket. |
| `isInCombat()` | Raw combat state, independent of `BattleEnabled`. |
| `actorIsInCombat(actorId)` | Raw combat tracking query for an actor ID. |
| `getCombatTargets()` | Live read-only array of current combat targets. |

## Constants

`S3maphore.const` is read-only and contains:

| Table | Values |
| --- | --- |
| `STATE` | `Died`, `Disabled`, `NoPlaylist`, `PlaylistChanged`, `SpecialTrackPlaying`, `TrackChanged` |
| `TIME_MAP` | `night`, `morning`, `afternoon`, `evening` by numeric time bucket |
| `INTERRUPT` | `Me = 0`, `Other = 1`, `Never = 2`, `Override = 3` |
| `STATE_FLAGS` | `TOD = 1`, `MOVEMENT = 2`, `SPELL_SCHOOL = 4`, `STANCE = 8` |

## Example: inspect and control playback

```lua
local I = require 'openmw.interfaces'
local S3maphore = I.S3maphore

local current = S3maphore.getCurrentTrack()
if current then
    print(('Playing %s'):format(current))
end

S3maphore.addTrackChangedHandler(function(event)
    print(('S3maphore selected %s from %s'):format(event.trackName, event.playlistId))
end)

S3maphore.setPlaylistActive('my-mod/storm-explore', true)
```

For death-track control, use the dedicated [Death Track](@/s3maphore/docs/api/death-track.md) reference rather than `playSpecialTrack`.
