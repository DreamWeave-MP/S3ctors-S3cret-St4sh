---
title: Put a Black Square on the Screen
summary: The smallest useful OpenMW UI example.
description: Create one visible UI element before learning a component framework.
weight: 5
extra:
  kind: example
---

Start with the smallest thing that proves your player/menu script can create UI.

```lua
---@omw-context player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local square = ui.create {
  type = ui.TYPE.Widget,
  layer = 'Windows',
  props = {
    position = util.vector2(100, 100),
    size = util.vector2(128, 128),
    color = util.color.rgb(0, 0, 0),
  },
}
```

Keep `square` if you intend to mutate or destroy it later.

This example is intentionally boring. Once you understand creation/lifetime, move to [UI: From Nothing to Something](@/cod3x/docs/getting-started/ui.md) and H3's component documentation for Morrowind-style windows and reusable layout primitives.
