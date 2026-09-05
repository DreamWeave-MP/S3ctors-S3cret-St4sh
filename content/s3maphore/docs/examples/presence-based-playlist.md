+++
title = "Presence-Based Playlist"
description = "Select music from the objects and content files found around the player."
weight = 20

[extra]
api_docs = true
kind = "example"
+++

This example uses two independent presence checks: a record lookup and a static content-file lookup. The reusable tables stay outside the callback so S3maphore can cache the result.

```lua
local DwemerObjects = {
    ['dwrv_ruin_scaffold_01'] = true,
}

local DwemerStatics = {
    ['morrowind.esm'] = true,
    ['tamriel rebuilt.esm'] = true,
}

---@type S3maphorePlaylist[]
return {
    {
        id = 'my-mod/dwemer-explore',
        priority = PlaylistPriority.Tileset,
        randomize = true,
        isValidCallback = function()
            return Playback.state.isExploring
                and Playback.rules.objectExact(DwemerObjects)
                and Playback.rules.staticContentFile(DwemerStatics)
        end,
    },
}
```

Use `typeCount` when the number of instances matters, `cellContainsTagged` when FlexTag should identify records, and `contentTag` when FlexTag should identify the content file. See [Presence and Content Rules](@/s3maphore/docs/api/rules/presence.md).
