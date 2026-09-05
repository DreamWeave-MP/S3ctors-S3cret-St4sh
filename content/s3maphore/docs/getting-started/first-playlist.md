+++
title = "Create Your First Playlist"
description = "A friendly first playlist you can copy, adapt, and make your own."
weight = 20

[extra]
api_docs = true
kind = "guide"
+++

Welcome! You do not need to be a Lua expert to make a S3maphore playlist. Think of a playlist as three simple decisions:

1. **Which folder contains the music?** Your lowercase `id` answers this automatically.
2. **How important is this music?** `priority` decides which valid playlist wins.
3. **When should it play?** `isValidCallback` answers a small yes-or-no question.

Create a Lua file under your `Playlists/` directory. The file returns an array because one file may register several playlists. For your first playlist, you can copy this exactly:

```lua
local BalmoraCells = {
    ['balmora'] = true,
    ['balmora, eight plates'] = true,
}

return {
    {
        id = 'my-mod/balmora',
        priority = PlaylistPriority.CellExact,
        randomize = true,
        isValidCallback = function()
            return Playback.rules.cellNameExact(BalmoraCells)
        end,
    },
}
```

That is a complete playlist. Put your audio files in `music/my-mod/balmora/` and S3maphore finds them automatically because the folder is derived from the lowercase `id`. You can add as many tracks as you like without editing this Lua file. Keep playlist IDs lowercase from the beginning: IDs are also folder names, lookup keys, and persistent activation-state keys.

The callback uses the `Playback` binding supplied by the [PlaylistEnvironment](@/s3maphore/docs/api/playlist-environment.md). `Playback.rules.cellNameExact(BalmoraCells)` asks whether the player is in one of the cells listed above. If the answer is true, this playlist is eligible; if not, S3maphore moves on to the next playlist.

The `tracks` field is optional. Use it only when you want to list exact VFS files instead of letting the playlist ID select a folder. If you do provide `tracks`, every path must point to a real installed audio file.

## Next steps

- Add more cells or replace the cell rule with another built-in rule.
- Put a second track in `music/my-mod/balmora/` and watch it join the playlist automatically.
- Move the playlist priority to match the kind of music it provides.
- Add `fallback` behavior when the playlist should borrow tracks from another group.
- Read [Playlist Specification](@/s3maphore/docs/playlist-authoring/specification.md) when you need the complete field list.
- Read [PlaylistEnvironment](@/s3maphore/docs/api/playlist-environment.md) when you need the names available without `require`.
