---
title: Build Cell Greeter
description: A small end-to-end mod that records visited cells and shows the result to the player.
weight: 130
extra:
  kind: guide
---

This is the capstone. The mod records how many different cells the player has visited and shows the current cell and total when the player presses X.

It is intentionally small. The point is to connect the boundaries, not to build a framework.

## The project tree

```text
CellGreeter/
├── CellGreeter registration file
└── scripts/
    └── CellGreeter/
        └── player.lua
```

Register the entry point:

```text
PLAYER: scripts/CellGreeter/player.lua
```

Put the directory in an active OpenMW data directory.

The repository contains the checked-in [`CellGreeter` example](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/tree/main/content/cod3x/examples/zero-to-hero) alongside the walkthrough.

## The first working version

```lua
---@omw-context player

local self = require 'openmw.self'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local visited = {}
local currentCellId
local currentCellName = 'Nowhere'
local root

local function checkCell()
    local cell = self.cell
    if not cell or cell.id == currentCellId then
        return
    end

    currentCellId = cell.id
    currentCellName = cell.name
    visited[currentCellId] = true
end

local function makeLayout(visitedCount)
    return {
        type = ui.TYPE.Window,
        layer = 'Windows',
        props = {
            title = 'Cell Greeter',
            position = util.vector2(80, 80),
            size = util.vector2(360, 90),
        },
        content = ui.content {
            {
                type = ui.TYPE.Text,
                props = {
                    text = ('%s — %d cell%s visited'):format(
                        currentCellName,
                        visitedCount,
                        visitedCount == 1 and '' or 's'
                    ),
                },
            },
        },
    }
end

local function showJournal()
    checkCell()

    local visitedCount = 0
    for _ in pairs(visited) do
        visitedCount = visitedCount + 1
    end

    if root then root:destroy() end
    root = ui.create(makeLayout(visitedCount))
end

return {
    engineHandlers = {
        onUpdate = checkCell,

        onKeyPress = function(key)
            if key.symbol == 'x' then
                showJournal()
            end
        end,

        onSave = function()
            return {
                visited = visited,
            }
        end,

        onLoad = function(data)
            visited = data and data.visited or {}
            currentCellId = nil
            currentCellName = 'Nowhere'
            if root then root:destroy() end
            root = nil
        end,
    },
}
```

This version already demonstrates the architecture:

{{ schematic(data_path="data/schematics/cell-greeter-architecture.json") }}

## Keep the UI owned

The window is deliberately plain. `root` owns the live UI element, while `visited` and cell detection remain ordinary Lua state. The next time you improve the window, keep that separation: change the layout without turning the UI element into your source of truth.

The [UI: From Nothing to Something](@/cod3x/docs/getting-started/ui.md) page shows the layout lifecycle; the [UI Recipes](@/h3lp_yours3lf/docs/examples/ui-recipes.md) show the next layer.

## What to inspect when it fails

- No script activity: check the `.omwscripts` registration and data directory.
- No cell count: check that `self.cell` is present and that the script is running as `PLAYER`.
- Count resets after loading: inspect the `onSave` return table and `onLoad` input.
- UI breaks after changing screens: treat the element as an owned runtime object and rebuild it when needed.

Now go to [Where Do I Go From Here?](@/cod3x/docs/zero-to-hero/where-next.md).
