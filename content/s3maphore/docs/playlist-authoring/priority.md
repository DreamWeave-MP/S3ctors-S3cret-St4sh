+++
title = "Priority and Interruption"
description = "Resolve competing playlists without relying on special-case magic."
weight = 20

[extra]
api_docs = true
kind = "guide"
+++

You are in the right place when two playlists can both play and you need to decide which one wins. Priority determines which valid playlist is preferred. Interrupt mode determines whether that newly preferred playlist may replace the track that is already playing.

You do not need to memorize the numbers. Start with a named `PlaylistPriority` value, then choose a named `INTERRUPT` value only when the default behavior is not what you want. Lower priority numbers are considered first.

## Every `PlaylistPriority` value

| Value | Number | Typical use |
| --- | ---: | --- |
| `PlaylistPriority.Special` | `50` | One-shot, quest, boss, or other deliberate special music. |
| `PlaylistPriority.BattleMod` | `190` | Modded or more specific combat music. |
| `PlaylistPriority.BattleVanilla` | `200` | Vanilla-style combat music. |
| `PlaylistPriority.TimeOfDay` | `300` | Music selected by time of day. |
| `PlaylistPriority.MerchantType` | `350` | Music tied to nearby merchant services. |
| `PlaylistPriority.Class` | `375` | Music tied to an actor class or similar category. |
| `PlaylistPriority.Faction` | `400` | Music tied to a faction. |
| `PlaylistPriority.CellExact` | `500` | Music for specific named cells. |
| `PlaylistPriority.Tileset` | `600` | Music identified by dungeon or architectural tiles. |
| `PlaylistPriority.CellMatch` | `700` | Music for a family of matching cells. |
| `PlaylistPriority.City` | `800` | Music for a city or settlement. |
| `PlaylistPriority.Region` | `900` | Music for a broad region. |
| `PlaylistPriority.Explore` | `1000` | General exploration music. |
| `PlaylistPriority.Never` | `math.huge` | Sentinel / lowest-priority fallback. If used, set `interruptMode` explicitly. |

The priority value also determines which resolution deck a playlist enters: Explore, Battle, or Special. Keep a playlist in the band that matches its purpose. See [Playlist Specification](@/s3maphore/docs/playlist-authoring/specification.md) for the other fields and [PlaylistEnvironment](@/s3maphore/docs/api/playlist-environment.md) for the injected `PlaylistPriority` value.

When two playlists have the same priority, registration order breaks the tie. For playlists loaded from files, that means the VFS file order followed by the order of the playlist tables returned by each file. Do not rely on that as a hidden override; use a more specific priority when one playlist should reliably win.

## Automatic interrupt modes

If `interruptMode` is omitted, S3maphore assigns it from the priority band:

| Priority range | Default |
| --- | --- |
| `<= PlaylistPriority.Special` | `INTERRUPT.Never` |
| `<= PlaylistPriority.BattleVanilla` | `INTERRUPT.Other` |
| `<= PlaylistPriority.Explore` | `INTERRUPT.Me` |
| `> PlaylistPriority.Explore` | No automatic assignment; avoid this range unless you also set `interruptMode`. |

This default is a convenience, not a rule. Set `interruptMode` explicitly when the playlist's interruption behavior matters. `Override` is never assigned automatically.

## Every `INTERRUPT` value

| Value | Number | Meaning |
| --- | ---: | --- |
| `INTERRUPT.Me` | `0` | Normal exploration-style interruption behavior. |
| `INTERRUPT.Other` | `1` | Normal battle-style interruption behavior. |
| `INTERRUPT.Never` | `2` | Do not interrupt the track already playing. |
| `INTERRUPT.Override` | `3` | Bypass the normal interruption gate and replace the current track when selected. |

`INTERRUPT.Override` is for deliberate moments such as quest stages, boss entrances, and one-shot cues. It bypasses the interruption gate, but the playlist must still be active, have tracks, pass its callback, and win normal priority resolution. In other words, Override is a permission to interrupt, not a shortcut around playlist selection.

Keep the journal lookup outside the callback. The same rule tables are used as cache keys by S3maphore. Playlist callbacks use the `Playback` binding from the [PlaylistEnvironment](@/s3maphore/docs/api/playlist-environment.md).

```lua
local QuestStages = {
    MyQuest = { min = 10 },
}

return {
    {
        id = 'my-mod/boss-entrance',
        priority = PlaylistPriority.Special,
        interruptMode = INTERRUPT.Override,
        playOneTrack = true,
        tracks = {
            'music/my-mod/boss-entrance.mp3',
        },
        isValidCallback = function()
            return Playback.rules.journal(QuestStages)
        end,
    },
}
```
