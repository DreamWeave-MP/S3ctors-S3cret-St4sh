---
title: widget
description: Build a passive base Widget layout.
weight: 10
extra:
  kind: api
---

Builds a plain `ui.TYPE.Widget`, optionally containing child layouts. Use it for neutral composition or custom geometry without an OpenMW built-in template.

## Example

```lua
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local widget = require 'scripts.s3.components.widget'
local text = require 'scripts.s3.components.text'

ui.create {
  layer = 'Windows',
  props = {
    size = util.vector2(240, 40),
  },
  content = ui.content {
    widget {
      props = {
        size = util.vector2(240, 40),
      },
      children = {
        text {
          text = 'A neutral widget',
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

[container](@/h3lp_yours3lf/docs/api/components/container.md) · [box](@/h3lp_yours3lf/docs/api/components/box.md) · [column](@/h3lp_yours3lf/docs/api/components/column.md)
