---
title: React to the Player
description: Use input and engine handlers for specific actions without turning every feature into onUpdate.
weight: 120
extra:
  kind: guide
---

OpenMW calls handlers when something happens. Use that timing instead of asking every frame whether anything might have happened.

## Input is an event-shaped action

This player script reacts to X:

```lua
---@omw-context player

local ui = require 'openmw.ui'

local function onKeyPress(key)
    if key.symbol ~= 'x' then
        return
    end

    ui.showMessage 'You pressed X.'
end

return {
    engineHandlers = {
        onKeyPress = onKeyPress,
    },
}
```

The early return keeps the interesting path visible. A handler can call a function, update state, send an event, or refresh UI.

## Use `onUpdate` only for work that needs a repeated observation

Some facts do not have a convenient event. A cell-tracking feature may compare the current cell with the last one it saw:

```lua
local lastCellId

local function onUpdate()
    local cell = self.cell
    if not cell or cell.id == lastCellId then
        return
    end

    lastCellId = cell.id
    print('Cell changed:', cell.id)
end
```

The comparison is cheap and the real work happens only after a change. Do not perform a complete world scan, rebuild a UI tree, or serialize large tables in every frame just because `onUpdate` exists.

## Callbacks run later

When OpenMW calls a handler, the world may no longer look exactly as it did when the script registered it. Check the state that matters at the boundary: object validity, current cell, active UI ownership, and whether deferred work is still relevant.

For the full handler contract, read [Script Registration and Entry Points](@/cod3x/docs/getting-started/script-registration.md). For the performance rule, read [Every Frame Is a Budget](@/cod3x/docs/anti-patterns/per-frame-everything.md).

You now have enough pieces for a real project. Build it in [Cell Greeter](@/cod3x/docs/zero-to-hero/cell-greeter.md).
