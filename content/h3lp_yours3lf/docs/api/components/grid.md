---
title: grid
description: Arrange items into fixed-column horizontal rows.
weight: 24
extra:
  kind: api
---

Builds a vertical Flex containing horizontal Flex rows. `items` are assigned in order; `columns` defaults to `1`, and values below `1` are treated as `1`.

## Example

```lua
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local grid = require 'scripts.s3.components.grid'
local itemSlot = require 'scripts.s3.components.itemSlot'

local iconSize = util.vector2(72, 72)
local red = util.color.rgb(1, 0, 0)
local green = util.color.rgb(0, 1, 0)
local blue = util.color.rgb(0, 0, 1)

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    grid {
      columns = 3,
      items = {
        itemSlot {
          resource = { path = 'white' },
          count = 1,
          iconProps = { size = iconSize, color = red },
        },
        itemSlot {
          resource = { path = 'white' },
          count = 2,
          iconProps = { size = iconSize, color = green },
        },
        itemSlot {
          resource = { path = 'white' },
          count = 3,
          iconProps = { size = iconSize, color = blue },
        },
      },
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `items` | table | Child layouts assigned in order. |
| `columns` | integer? | Items per row; defaults to `1`. |
| `rowProps` | table? | Properties copied to each generated row. |
| `template` | openmw.ui.Template? | Replaces the default grid template. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md).

## See also

[list](@/h3lp_yours3lf/docs/api/components/list.md) · [itemSlot](@/h3lp_yours3lf/docs/api/components/item-slot.md) · [row](@/h3lp_yours3lf/docs/api/components/row.md)
