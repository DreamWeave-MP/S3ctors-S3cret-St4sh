---
title: row
description: Arrange children in a horizontal Flex layout.
weight: 20
extra:
  kind: api
---

Builds a `ui.TYPE.Flex` with `props.horizontal = true`. The component's orientation overrides `props.horizontal`.

## Example

```lua
local ui = require 'openmw.ui'
local row = require 'scripts.s3.components.row'
local text = require 'scripts.s3.components.text'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    row {
      children = {
        text {
          text = 'Left',
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
| `content` | table? | Child content; takes precedence over `children`. |
| `children` | table? | Child layouts used when `content` is absent. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md).

## See also

[column](@/h3lp_yours3lf/docs/api/components/column.md) · [spacer](@/h3lp_yours3lf/docs/api/components/spacer.md) · [list](@/h3lp_yours3lf/docs/api/components/list.md)
