---
title: toggle
description: Build a state-labelled yes/no button.
weight: 40
extra:
  kind: api
---

Builds an H3UI button whose label reflects a boolean value. `value` defaults to `false`; labels default to `On` and `Off`.

## Example

```lua
local ui = require 'openmw.ui'
local column = require 'scripts.s3.components.column'
local toggle = require 'scripts.s3.components.toggle'
local text = require 'scripts.s3.components.text'

local enabled = true
local status = text {
  text = 'Enabled',
}
local element

element = ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    column {
      children = {
        toggle {
          label = 'Sound',
          value = enabled,
          onChange = function(value)
            enabled = value
            status.props.text = value and 'Enabled' or 'Disabled'
            element:update()
          end,
        },
        status,
      },
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `value` | boolean? | Initial state; defaults to `false`. |
| `onChange` | function? | Receives the new boolean value. |
| `label` | string | Base label for the control. |
| `onLabel` | string? | Label suffix for the enabled state. |
| `offLabel` | string? | Label suffix for the disabled state. |
| `labelProps` | table? | Properties for the generated label. |
| `template` | openmw.ui.Template? | Replaces the default H3UI button template. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). `onChange` runs after the label changes.

## See also

[button](@/h3lp_yours3lf/docs/api/components/button.md) · [slider](@/h3lp_yours3lf/docs/api/components/slider.md) · [collapsible](@/h3lp_yours3lf/docs/api/components/collapsible.md)
