---
title: caption
description: Build a centered Morrowind title strip with optional controls.
weight: 51
extra:
  kind: api
---

Builds a horizontal title strip from head blocks and centered text. It can append a pin control and/or close button; it does not close a parent window. Give it a fixed-width Widget parent because its default width is relative.

## Example

```lua
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local caption = require 'scripts.s3.components.caption'

ui.create {
  layer = 'Windows',
  props = {
    size = util.vector2(320, 20),
  },
  content = ui.content {
    caption {
      text = 'Inventory',
      pinnable = true,
      closable = true,
      onPin = function(pinned)
        print('Pinned:', pinned)
      end,
      onClose = function()
        print('Closed')
      end,
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `text` | string | Caption text. |
| `pinnable` | boolean? | Adds a pin control. |
| `pinned` | boolean? | Initial pin state. |
| `onPin` | function? | Receives the new pin state. |
| `closable` | boolean? | Adds a close control. |
| `onClose` | function? | Runs when close is pressed. |
| `closeLabel` | string? | Accessible close-button label. |
| `height` | number? | Strip height; controls need at least `19`. |
| `textProps` | table? | Properties for the caption text. |
| `pinProps` | table? | Properties for the pin control. |
| `closeProps` | table? | Properties for the close control. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). The default relative width requires a parent with explicit width; use the default Widget with `props.size` for a standalone caption.

## See also

[headBlock](@/h3lp_yours3lf/docs/api/components/head-block.md) · [pinButton](@/h3lp_yours3lf/docs/api/components/pin-button.md) · [window](@/h3lp_yours3lf/docs/api/components/window.md)
