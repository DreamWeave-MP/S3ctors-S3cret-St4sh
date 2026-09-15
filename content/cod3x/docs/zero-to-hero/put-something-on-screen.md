---
title: Put Something on the Screen
description: Start with a message, then understand the layout and ownership behind real UI.
weight: 110
extra:
  kind: guide
---

The fastest UI is a message:

```lua
---@omw-context player

local ui = require 'openmw.ui'

ui.showMessage 'The script is alive.'
```

That proves your player script reached the line. It is a useful first test, not a complete UI architecture.

## The black rectangle

OpenMW's lower-level UI API takes a layout table and creates an element:

```lua
local util = require 'openmw.util'

local element = ui.create {
    type = ui.TYPE.Image,
    layer = 'Windows',
    props = {
        resource = ui.texture { path = 'white' },
        position = util.vector2(40, 40),
        size = util.vector2(200, 100),
        color = util.color.rgb(0, 0, 0),
    },
}
```

The layout describes what should exist. `ui.create` mounts a root element. Keep the returned element if you need to update or destroy it later.

## UI is a projection of state

Do not scatter individual UI mutations through every callback. Keep the state in Lua and rebuild or update the owned element when that state changes:

```lua
local enabled = true
local element

local function buildLayout()
    return {
        type = ui.TYPE.Container,
        layer = 'Windows',
        content = ui.content {
            {
                type = ui.TYPE.Text,
                props = { text = enabled and 'Enabled' or 'Disabled' },
            },
        },
    }
end

element = ui.create(buildLayout())
```

When the layout becomes larger than a tiny example, use an H3UI component or recipe rather than inventing a framework for one window.

Read [UI: From Nothing to Something](@/cod3x/docs/getting-started/ui.md), [H3UI and Styling](@/h3lp_yours3lf/docs/concepts/h3ui.md), and the [UI Recipes](@/h3lp_yours3lf/docs/examples/ui-recipes.md).

Next, connect visible behavior to player input in [React to the Player](@/cod3x/docs/zero-to-hero/react-to-the-player.md).
