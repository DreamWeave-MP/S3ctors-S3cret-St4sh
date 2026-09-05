+++
title = "Interface Control"
description = "Register a playlist and inspect playback from another player script."
weight = 50

[extra]
api_docs = true
kind = "example"
+++

This example registers a playlist from an ordinary player script instead of returning one from a `Playlists/` file. Programmatically registered playlists do not have the [PlaylistEnvironment](@/s3maphore/docs/api/playlist-environment.md)'s `Playback` binding, so their callback uses the `playback` argument supplied by S3maphore.

```lua
local I = require 'openmw.interfaces'
local PlaylistPriority = require 'doc.playlistPriority'

local QuestStages = {
    A1_V_VivecInformants = { min = 50, max = 55 },
}

I.S3maphore.registerPlaylist {
    id = 'my-mod/quest-moment',
    priority = PlaylistPriority.Special,
    tracks = { 'music/my-mod/quest-moment.mp3' },
    playOneTrack = true,
    isValidCallback = function(playback)
        return playback.rules.journal(QuestStages)
    end,
}

I.S3maphore.addTrackChangedHandler(function(event)
    print(('Now playing %s from %s'):format(event.trackName, event.playlistId))
end)

I.S3maphore.setPlaylistActive('my-mod/quest-moment', true)
```

`priority` must be a playlist priority, not an interrupt mode. Choose the value appropriate to the playlist; this example uses `PlaylistPriority.Special` because it is a one-shot quest moment.
