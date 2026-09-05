+++
title = "Rules and Callbacks"
description = "Write fast, readable isValidCallback functions around the PlaylistState and PlaylistRules contracts."
weight = 30

[extra]
api_docs = true
kind = "guide"
+++

Every playlist must provide an `isValidCallback` function. S3maphore invokes it as `isValidCallback(playback)`. In a `Playlists/` file, use the injected `Playback` binding and declare the callback without a parameter. For programmatic registration, use the callback argument because that script does not have the playlist environment. Return `true` when the playlist applies to the current context and `false` or `nil` otherwise.

```lua
local Cells = {
    ['balmora'] = true,
}

return {
    {
        id = 'my-mod/balmora-explore',
        priority = PlaylistPriority.CellExact,
        isValidCallback = function()
            return Playback.state.isExploring
                and Playback.rules.cellNameExact(Cells)
        end,
    },
}
```

## Keep lookup data stable

Declare lookup tables outside the callback. S3maphore caches many rule results by the identity of the input table. Constructing a new table every time the callback runs defeats that cache and creates avoidable garbage.

```lua
local Regions = {
    ['bitter coast region'] = true,
}

local Weather = {
    rain = true,
    thunder = true,
}

isValidCallback = function()
    return Playback.rules.region(Regions)
        and Playback.rules.weatherType(Weather)
end
```

Do not write this instead:

```lua
isValidCallback = function()
    return Playback.rules.region({ ['bitter coast region'] = true })
end
```

## Compose deliberately

Rules are ordinary Lua functions. Use `and` and `or` to compose them, and read `Playback.state` directly when a field is clearer than a rule.

```lua
local TargetTypes = {
    undead = true,
    daedra = true,
}

isValidCallback = function()
    local state = Playback.state
    return (state.isInCombat and Playback.rules.combatTargetType(TargetTypes))
        or (state.cellIsExterior and state.isExploring)
end
```

Use parentheses when mixing `and` and `or` if the intended precedence is not obvious. The callback should be a decision, not a second music manager: avoid mutating game state, starting timers, or doing expensive scans in it.

## What gets reevaluated

S3maphore reevaluates valid playlists when relevant context changes, including cell presence, combat, weather, time, movement, spell school, stance, and playlist activation. It may stop once it finds the winning playlist. Callback cadence is an implementation detail; do not depend on it being once per frame.

For the available values, see [PlaylistState](@/s3maphore/docs/api/playlist-state.md). For the complete function inventory, see [PlaylistRules](@/s3maphore/docs/api/rules/_index.md).
