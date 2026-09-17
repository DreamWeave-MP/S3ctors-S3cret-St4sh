---
title: spacer
description: Add fixed space or flexible empty room to a layout.
weight: 25
extra:
  kind: api
---

Builds an empty `ui.TYPE.Widget`. Use `spacer(8)` for an 8×8 square, `spacer(12, 4)` for width and height, or an options table for full control.

## Example

```lua
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local H3UI = require('openmw.interfaces').H3UI

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    H3UI.row {
      props = {
        size = util.vector2(240, 24),
      },
      children = {
        H3UI.text {
          text = 'Left',
        },
        H3UI.spacer {
          grow = 1,
        },
        H3UI.text {
          text = 'Right',
        },
      },
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `width` | number | Width for numeric shorthand. |
| `height` | number? | Height for numeric shorthand; defaults to `width`. |
| `grow` | number? | Flexible growth when `external` is absent. |
| `stretch` | number? | Flexible stretch when `external` is absent. |

The table form also accepts common layout fields, documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). A growing spacer needs remaining space from its parent; give the row an explicit size or place it in a larger fixed-size layout.

## See also

[row](@/h3lp_yours3lf/docs/api/components/row.md) · [column](@/h3lp_yours3lf/docs/api/components/column.md) · [widget](@/h3lp_yours3lf/docs/api/components/widget.md)
