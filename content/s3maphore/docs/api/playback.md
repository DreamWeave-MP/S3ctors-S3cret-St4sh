+++
title = "Playback"
description = "The state and rules exposed to playlist validity callbacks."
weight = 20

[extra]
api_docs = true
kind = "api"
+++

## `Playback`

{{ api_signature(value="Playback -> { state: PlaylistState, rules: PlaylistRules }") }}

S3maphore invokes validity callbacks as `isValidCallback(playback)`. Playlist files receive the same context as the injected `Playback` binding from the [PlaylistEnvironment](@/s3maphore/docs/api/playlist-environment.md), so they normally declare `function()` and close over `Playback`. Programmatically registered playlists can use the callback argument directly. The context contains the current state and built-in rule functions; do not assume a particular callback cadence. See [PlaylistState](@/s3maphore/docs/api/playlist-state.md) for every state field and [PlaylistRules](@/s3maphore/docs/api/rules/_index.md) for the complete rule inventory.

### Example

```lua
isValidCallback = function()
    return Playback.state.cellIsExterior
        and not Playback.state.isInCombat
        and Playback.rules.timeOfDay(6, 18)
end
```

`state` includes values such as `cellName`, `cellIsExterior`, `isInCombat`, `weather`, `nearestRegion`, and `currentGrid`. See [PlaylistState](@/s3maphore/docs/api/playlist-state.md) for the complete field list and [PlaylistEnvironment](@/s3maphore/docs/api/playlist-environment.md) for every binding available to playlist files.
