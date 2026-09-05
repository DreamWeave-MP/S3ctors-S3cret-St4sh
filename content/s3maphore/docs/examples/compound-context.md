+++
title = "Compound Context Playlist"
description = "Combine location, weather, presence, and combat state without making the callback opaque."
weight = 30

[extra]
api_docs = true
kind = "example"
+++

Break a complicated decision into named lookup data and a short callback. This pattern is easier to audit when the music pack grows.

```lua
local Regions = {
    ['ashlands region'] = true,
    ['red mountain region'] = true,
}

local Weather = {
    rain = true,
    thunder = true,
}

local AshlandTags = { 'ashlands' }
local ExposedExterior = {
    type = 'Static',
    min = 1,
}

---@type S3maphorePlaylist[]
return {
    {
        id = 'my-mod/storms-over-ashlands',
        priority = PlaylistPriority.Region,
        randomize = true,
        isValidCallback = function()
            local state = Playback.state
            return state.isExploring
                and state.cellIsExterior
                and Playback.rules.region(Regions)
                and Playback.rules.weatherType(Weather)
                and Playback.rules.typeCount(ExposedExterior)
                and Playback.rules.cellHasTag(AshlandTags)
        end,
    },
}
```

`cellHasTag` requires FlexTag. If that optional integration is not installed, use `cellNameExact`, `region`, or `staticContentFile` instead. See [PlaylistState](@/s3maphore/docs/api/playlist-state.md) for the state values and [all rules](@/s3maphore/docs/api/rules/_index.md) for their dependency behavior.
