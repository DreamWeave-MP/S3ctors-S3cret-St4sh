---
title: numberInput
description: Edit a number with commit-time clamping and stepping.
weight: 45
extra:
  kind: api
---

Builds a TextEdit that preserves raw text while editing and normalizes it on focus loss. Invalid text reverts to the last value; `integer = true` rounds to integral values.

## Example

```lua
local ui = require 'openmw.ui'
local numberInput = require 'scripts.s3.components.numberInput'

local amount = 20
local element

element = ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    numberInput {
      value = amount,
      min = 5,
      max = 100,
      step = 5,
      integer = true,
      onChange = function(value)
        amount = value
        print('Changed:', value)
      end,
      onCommit = function(value)
        print('Committed:', value)
        element:update()
      end,
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `value` | number | Initial numeric value. |
| `min` | number? | Lower bound. |
| `max` | number? | Upper bound. |
| `step` | number? | Commit-time increment. |
| `integer` | boolean? | Round committed values to integers. |
| `onChange` | function? | Runs when the committed number changes. |
| `onCommit` | function? | Runs after every focus-loss commit. |
| `template` | openmw.ui.Template? | Replaces the default text-edit template. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). Integer `min`, `max`, and `step` must themselves be integral.

## See also

[textInput](@/h3lp_yours3lf/docs/api/components/text-input.md) · [slider](@/h3lp_yours3lf/docs/api/components/slider.md) · [searchInput](@/h3lp_yours3lf/docs/api/components/search-input.md)
