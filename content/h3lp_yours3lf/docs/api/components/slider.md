---
title: slider
description: Build a bounded pointer-controlled numeric slider.
weight: 41
extra:
  kind: api
---

Builds a [meter](@/h3lp_yours3lf/docs/api/components/meter.md)-based horizontal track. Pointer presses and drags map to `min..max`, clamp to the range, and optionally round to `step`.

## Example

```lua
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local column = require 'scripts.s3.components.column'
local slider = require 'scripts.s3.components.slider'
local text = require 'scripts.s3.components.text'

local value = 50
local readout = text {
  text = '50%',
}
local element

element = ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    column {
      children = {
        slider {
          value = value,
          min = 0,
          max = 100,
          step = 5,
          props = {
            size = util.vector2(240, 18),
          },
          onChange = function(nextValue)
            value = nextValue
            readout.props.text = tostring(nextValue) .. '%'
            element:update()
          end,
        },
        readout,
      },
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `value` | number? | Initial value; defaults to `min`. |
| `min` | number? | Lower bound; defaults to `0`. |
| `max` | number? | Upper bound; defaults to `1`. |
| `step` | number? | Optional rounding increment. |
| `trackWidth` | number? | Rendered width for relative tracks. |
| `fillProps` | table? | Properties for the filled portion. |
| `emptyProps` | table? | Properties for the empty portion. |
| `onChange` | function? | Receives the normalized value. |
| `template` | openmw.ui.Template? | Replaces the default H3UI meter template. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). Invalid ranges and non-positive steps raise an error during construction.

## See also

[meter](@/h3lp_yours3lf/docs/api/components/meter.md) · [numberInput](@/h3lp_yours3lf/docs/api/components/number-input.md) · [selector](@/h3lp_yours3lf/docs/api/components/selector.md)
