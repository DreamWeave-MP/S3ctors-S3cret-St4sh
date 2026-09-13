---
title: list
description: Build a vertical list from items or child layouts.
weight: 22
extra:
  kind: api
---

Builds a vertical `ui.TYPE.Flex`. Use `items` for a list of layouts, or `children` or `content` when the source is already named that way.

## Example

```lua
local ui = require 'openmw.ui'
local list = require 'scripts.s3.components.list'
local listItem = require 'scripts.s3.components.listItem'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    list {
      items = {
        listItem {
          label = 'First entry',
        },
        listItem {
          label = 'Second entry',
        },
      },
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `items` | table? | Child layouts; used when `content` and `children` are absent. |
| `content` | table? | Child content; takes precedence over `children` and `items`. |
| `children` | table? | Child layouts; takes precedence over `items`. |
| `template` | openmw.ui.Template? | Replaces the default list template. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md).

## See also

[listItem](@/h3lp_yours3lf/docs/api/components/list-item.md) · [grid](@/h3lp_yours3lf/docs/api/components/grid.md) · [column](@/h3lp_yours3lf/docs/api/components/column.md)
