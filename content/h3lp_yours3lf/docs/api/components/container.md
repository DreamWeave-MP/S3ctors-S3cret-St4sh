---
title: container
description: Group children in a passive OpenMW Container.
weight: 11
extra:
  kind: api
---

Builds a plain `ui.TYPE.Container` that groups child layouts without adding H3UI presentation. A container sizes itself to its children but does not arrange sibling layouts; use `row` or `column` when you need an arrangement.

## Example

```lua
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local column = require 'scripts.s3.components.column'
local container = require 'scripts.s3.components.container'
local text = require 'scripts.s3.components.text'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  props = {
    position = util.vector2(80, 80),
  },
  content = ui.content {
    container {
      children = {
        column {
          children = {
            text {
              text = 'First child',
            },
            text {
              text = 'Second child',
            },
          },
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

[widget](@/h3lp_yours3lf/docs/api/components/widget.md) · [row](@/h3lp_yours3lf/docs/api/components/row.md) · [column](@/h3lp_yours3lf/docs/api/components/column.md)
