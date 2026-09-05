+++
title = "PlaylistEnvironment"
description = "The names and services injected into every S3maphore playlist file."
weight = 15

[extra]
api_docs = true
kind = "api"
+++

S3maphore loads every Lua file under its `Playlists/` VFS directory inside a dedicated `PlaylistEnvironment`. These names are available at the top level of the file; do not require them or prefix them with a module name.

The most important binding is the capitalized `Playback` value. Validity callbacks in playlist files should take no formal parameter and close over this binding:

```lua
local Cells = {
    ['balmora'] = true,
}

return {
    {
        id = 'my-mod/balmora',
        priority = PlaylistPriority.CellExact,
        isValidCallback = function()
            return Playback.state.isExploring
                and Playback.rules.cellNameExact(Cells)
        end,
    },
}
```

S3maphore invokes validity callbacks as `isValidCallback(playback)`. Playlist files also receive the same playback context as the injected `Playback` binding, so file-based playlists can omit the formal parameter and use `Playback` directly. Playlists registered programmatically through `I.S3maphore.registerPlaylist` do not run inside this environment; their callbacks should use the supplied `playback` argument.

## `Playback`

{{ api_signature(value="Playback -> { state: PlaylistState, rules: PlaylistRules }") }}

`Playback.state` is the live playlist state described by [PlaylistState](@/s3maphore/docs/api/playlist-state.md). It is a read-only usage contract: read it, but do not mutate it or retain assumptions about its nested table identity. S3maphore updates this state as the player, cell, combat, weather, and presence context changes.

`Playback.rules` is the complete set of cached predicates described by [PlaylistRules](@/s3maphore/docs/api/rules/_index.md). Keep rule input tables outside callbacks so those lookups can reuse their cache entries.

The `Playback` binding is specific to a playlist file. A normal player script registered through `I.S3maphore` does not run inside this environment; that script should use the public interface's `state` and `rules` fields instead.

## Playback controls

These functions are available to playlist files and are also exposed through the S3maphore interface:

| Name | Signature | Behavior |
| --- | --- | --- |
| `playSpecialTrack` | `playSpecialTrack(trackPath, reason?)` | Plays an existing VFS track through the built-in `Special` playlist. Does nothing when music is disabled. |
| `skipTrack` | `skipTrack()` | Stops the current track so normal resolution can choose the next track or playlist. |
| `setPlaylistActive` | `setPlaylistActive(id, state)` | Enables or disables a registered playlist and stores that activation state. Errors when the ID is not registered. |
| `timeOfDay` | `timeOfDay() -> TimeOfDay` | Returns the current `night`, `morning`, `afternoon`, or `evening` bucket. |

These are actions, not validity queries. Do not call them from `isValidCallback`; callbacks can be reevaluated repeatedly and should only make a cheap decision. Use them during explicit scripted actions or through the [S3maphore interface](@/s3maphore/docs/api/interface.md).

## Constants and lookup data

### `INTERRUPT`

`INTERRUPT` controls how a selected playlist may interrupt the track already playing:

| Name | Meaning |
| --- | --- |
| `Me` | The playlist may interrupt the same archetype. |
| `Other` | The playlist may interrupt a different archetype. |
| `Never` | The playlist does not interrupt the current track. |
| `Override` | The playlist bypasses the normal interruption gate. |

See [Priority and Interruption](@/s3maphore/docs/playlist-authoring/priority.md) for resolution order and safe use of `Override`.

### `PlaylistPriority`

`PlaylistPriority` contains the standard priority bands used during playlist selection. Lower numbers are considered first:

`Never`, `Explore`, `Region`, `City`, `CellMatch`, `Tileset`, `CellExact`, `Faction`, `Class`, `MerchantType`, `TimeOfDay`, `BattleVanilla`, `BattleMod`, and `Special`.

Use these named values rather than copying numbers. Their current values and ordering are documented in [Priority and Interruption](@/s3maphore/docs/playlist-authoring/priority.md).

### `Tilesets`

`Tilesets` contains reusable record-ID maps for the built-in tileset categories:

`Ayleid`, `Barrows`, `Cave`, `Crypt`, `Daedric`, `Dwemer`, and `Ice`.

Pass one of these maps to [presence rules](@/s3maphore/docs/api/rules/presence.md), normally through `Playback.rules.objectExact`:

```lua
isValidCallback = function()
    return Playback.rules.objectExact(Tilesets.Dwemer)
end
```

## `I`

`I` is the result of `require 'openmw.interfaces'`. It lets a playlist inspect or control interfaces registered by other scripts. S3maphore's own public interface is available as `I.S3maphore`; see [Interface](@/s3maphore/docs/api/interface.md) for its methods and state.

Prefer `Playback.state` and `Playback.rules` for playlist validity. Use `I` when the decision depends on another mod's interface or when a playlist file needs to invoke an explicit S3maphore control.

## Lua facilities

The environment also provides:

| Name | Purpose |
| --- | --- |
| `require` | Load an available Lua module. |
| `math` | Lua math library. |
| `string` | Lua string library. |
| `table` | Lua table library. |
| `ipairs` | Iterate array-like tables. |
| `pairs` | Iterate table keys. |
| `print` | S3maphore's debug-aware print function. |

`print` is routed through S3maphore's debug logging rather than acting like an unrestricted console logger. Keep playlist files self-contained and use the documented environment instead of assuming unrelated globals are available.

## File contract

A playlist file is evaluated once while S3maphore loads its playlist collection. It must return an array of playlist tables. One file may return several playlists:

```lua
return {
    {
        id = 'my-mod/explore',
        priority = PlaylistPriority.Explore,
        isValidCallback = function()
            return not Playback.state.isInCombat
        end,
    },
    {
        id = 'my-mod/battle',
        priority = PlaylistPriority.BattleMod,
        isValidCallback = function()
            return Playback.state.isInCombat
        end,
    },
}
```

For the fields on each returned playlist, see [Playlist Specification](@/s3maphore/docs/playlist-authoring/specification.md). For a complete authoring walkthrough, start with [Create Your First Playlist](@/s3maphore/docs/getting-started/first-playlist.md).
