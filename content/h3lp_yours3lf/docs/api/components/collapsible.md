---
title: collapsible
description: Build an expandable disclosure header and body.
weight: 44
extra:
  kind: api
---

Builds a vertical column containing a header button and body column. Body visibility follows `expanded`, which defaults to `false`.

## Example

```lua
local ui = require 'openmw.ui'
local collapsible = require 'scripts.s3.components.collapsible'
local text = require 'scripts.s3.components.text'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    collapsible {
      title = 'Advanced options',
      expanded = false,
      children = {
        text {
          text = 'These options are currently visible.',
        },
      },
      onToggle = function(expanded)
        print('Expanded:', expanded)
      end,
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `title` | string | Header text. |
| `expanded` | boolean? | Initial body visibility; defaults to `false`. |
| `onToggle` | function? | Receives the new expanded state. |
| `content` | table? | Body content; takes precedence over `children`. |
| `children` | table? | Body layouts used when `content` is absent. |
| `headerProps` | table? | Properties for the header button. |
| `headerLabelProps` | table? | Properties for the header label. |
| `expandedPrefix` | string? | Prefix for the expanded header. |
| `collapsedPrefix` | string? | Prefix for the collapsed header. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). Call the owning element's `update()` when the mounted tree needs refreshing.

## See also

[toggle](@/h3lp_yours3lf/docs/api/components/toggle.md) · [column](@/h3lp_yours3lf/docs/api/components/column.md) · [dialog](@/h3lp_yours3lf/docs/api/components/dialog.md)
