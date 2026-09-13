---
title: column
description: Arrange children in a vertical Flex layout.
weight: 21
extra:
  kind: api
---

Builds a `ui.TYPE.Flex` with `props.horizontal = false`. The component's orientation overrides `props.horizontal`.

## Example

```lua
local ui = require 'openmw.ui'
local column = require 'scripts.s3.components.column'
local text = require 'scripts.s3.components.text'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    column {
      children = {
        text {
          text = 'Top',
        },
        text {
          text = 'Bottom',
        },
      },
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `content` | table? | Child content; takes precedence over `children`. |
| `children` | table? | Child layouts used when `content` is absent. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md).

## See also

[row](@/h3lp_yours3lf/docs/api/components/row.md) · [list](@/h3lp_yours3lf/docs/api/components/list.md) · [window](@/h3lp_yours3lf/docs/api/components/window.md)
