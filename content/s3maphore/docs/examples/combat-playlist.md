+++
title = "Contextual Combat Playlist"
description = "A combat playlist that narrows its target and keeps its lookup data reusable."
weight = 10

[extra]
api_docs = true
kind = "example"
+++

```lua
local TargetTypes = {
    undead = true,
    daedra = true,
}

---@type S3maphorePlaylist[]
return {
    {
        id = 'my-mod/undead-battle',
        priority = PlaylistPriority.BattleMod,
        randomize = true,
        isValidCallback = function()
            return Playback.state.isInCombat
                and Playback.rules.combatTargetType(TargetTypes)
        end,
    },
}
```

Because the playlist has no explicit `tracks` field, S3maphore looks for tracks under the folder derived from its `id`. See [combat rules](@/s3maphore/docs/api/rules/combat.md) for the other target predicates and [PlaylistState](@/s3maphore/docs/api/playlist-state.md) for the values available to the callback.
