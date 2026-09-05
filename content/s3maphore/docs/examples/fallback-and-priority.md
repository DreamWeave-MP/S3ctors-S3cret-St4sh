+++
title = "Fallback and Priority"
description = "Let a specific playlist yield to a known backup without duplicating its tracks."
weight = 40

[extra]
api_docs = true
kind = "example"
+++

Lower priority numbers are considered first. A fallback is a separate choice: when the selected playlist's `playlistChance` succeeds, S3maphore chooses an active playlist from its fallback list instead.

```lua
local Ashlands = {
    ['ashlands region'] = true,
}

---@type S3maphorePlaylist[]
return {
    {
        id = 'my-mod/ashlands-battle',
        priority = PlaylistPriority.BattleMod,
        randomize = true,
        fallback = {
            playlistChance = 0.25,
            playlists = { 'Battle' },
        },
        isValidCallback = function()
            return Playback.state.isInCombat
                and Playback.rules.region(Ashlands)
        end,
    },
}
```

Keep fallback playlists registered and active, and make sure they have tracks. S3maphore randomly chooses one fallback entry when the chance succeeds; if that entry is inactive, it returns to the original playlist instead of trying another entry. A fallback list with no explicit `playlistChance` uses a 50% chance. Nested fallback chains are supported up to a depth of 10, but keep them shallow and intentional.

`INTERRUPT.Override` is forceful: it can interrupt a playlist even when the current playlist is using `INTERRUPT.Never`. Use it for deliberate transitions such as a boss or death cue, not as a substitute for choosing a useful priority.
