+++
title = "Playlist Specification"
description = "Fields accepted by a S3maphore playlist."
weight = 10

[extra]
api_docs = true
kind = "api"
+++

Every playlist requires a string `id`, a numeric `priority`, and an `isValidCallback`. The remaining fields are optional and describe how the playlist behaves.

## Basic fields

| Field | Type | Purpose |
| --- | --- | --- |
| `id` | `string` | Stable playlist name and, when tracks are omitted, the folder name to scan. |
| `priority` | `PlaylistPriority` | Position in playlist resolution. |
| `tracks` | `string[]?` | Explicit VFS paths to tracks. |
| `active` | `boolean?` | Whether the playlist can be selected. Defaults to `true`. |
| `randomize` | `boolean?` | Whether tracks are played in random order. |
| `cycleTracks` | `boolean?` | Whether the playlist repeats after its tracks finish. |
| `playOneTrack` | `boolean?` | Deactivates the playlist after one track. |
| `isValidCallback` | `fun(playback) → boolean?` | Required validity test for the current state. File-based playlists normally omit the parameter and use the injected `Playback`; programmatic registrations use `playback`. |
| `fadeOut` | `number?` | Fade duration between tracks. |
| `interruptMode` | `InterruptMode?` | Controls whether another playlist may interrupt this one. |
| `fallback` | `PlaylistFallback?` | Adds fallback playlists or tracks. |
| `exclusions` | `S3maphorePlaylistExclusions?` | Removes tracks or playlist folders from discovery. |
| `silenceBetweenTracks` | `PlaylistSilenceParams?` | Optional playlist-specific silence interval and chance. |

`silenceBetweenTracks` accepts `min`, `max`, and `chance`:

```lua
silenceBetweenTracks = {
    min = 5,
    max = 20,
    chance = 0.5,
},
```

`min` and `max` are durations in seconds. They default to `0` and `30` when a playlist-specific silence roll succeeds. `chance` defaults to `1`; if that roll fails, S3maphore can still fall through to the global silence chance.

## Fallbacks

`fallback` can borrow another registered playlist or add extra tracks to the current playlist:

| Field | Type | Purpose |
| --- | --- | --- |
| `playlistChance` | `number?` | Chance of selecting a fallback playlist instead of the current playlist. Defaults to `0.5`. |
| `playlists` | `string[]?` | Registered playlist IDs from which to select fallback tracks. |
| `tracks` | `string[]?` | Relative track paths to add under `music/`, such as `explore/extra.mp3`. |

Fallback playlist resolution supports nested chains up to depth 10. An inactive or empty fallback returns control to the original playlist.

## Exclusions

`exclusions` removes tracks or playlist folders from automatic folder discovery. The `music/` prefix is inferred, so the values use the same IDs and relative paths as playlist definitions:

| Field | Type | Purpose |
| --- | --- | --- |
| `playlists` | `string[]?` | Playlist subdirectories to ignore. |
| `tracks` | `string[]?` | Explicit tracks to ignore. |

For example, `tracks = { 'explore/nerevar_rising.mp3' }` excludes `music/explore/nerevar_rising.mp3`.

## Folder-derived tracks

If `tracks` is omitted, S3maphore uses the playlist `id` to locate a folder. This keeps playlist definitions short and lets music packs add tracks without editing Lua.

```lua
return {
    {
        id = 'my-mod/explore',
        priority = PlaylistPriority.Explore,
        randomize = true,
        isValidCallback = function()
            return not Playback.state.isInCombat
        end,
    },
}
```
