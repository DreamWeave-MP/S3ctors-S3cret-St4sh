---
title: headBlock
description: Draw a scalable vanilla Morrowind title border.
weight: 50
extra:
  kind: api
---

Builds a Widget from the vanilla head-block corner, edge, and center textures. It scales horizontally to its parent and accepts a height of at least 4 pixels. Give it a fixed-width Widget parent; a fitting Container cannot provide that width.

## Example

```lua
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local headBlock = require 'scripts.s3.components.headBlock'

ui.create {
  layer = 'Windows',
  props = {
    size = util.vector2(320, 24),
  },
  content = ui.content {
    headBlock {
      height = 24,
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `height` | number? | Height in pixels; must be at least `4`. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). `props.size` and `props.relativeSize` override the defaults. The parent must provide width when the default relative width is used; use the default Widget with explicit `props.size` for a standalone head block.

## See also

[caption](@/h3lp_yours3lf/docs/api/components/caption.md) · [pinButton](@/h3lp_yours3lf/docs/api/components/pin-button.md) · [window](@/h3lp_yours3lf/docs/api/components/window.md)
