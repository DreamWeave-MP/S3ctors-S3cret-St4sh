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
local row = require 'scripts.s3.components.row'
local spacer = require 'scripts.s3.components.spacer'
local text = require 'scripts.s3.components.text'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    row {
      props = {
        size = util.vector2(240, 24),
      },
      children = {
        text {
          text = 'Left',
        },
        spacer {
          grow = 1,
        },
        text {
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
