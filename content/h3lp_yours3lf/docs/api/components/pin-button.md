---
title: pinButton
description: Build the fixed-size Morrowind pinned-state control.
weight: 52
extra:
  kind: api
---

Builds the vanilla up/down pin control. It is fixed at 19×19 pixels and changes its skin when clicked.

## Example

```lua
local ui = require 'openmw.ui'
local pinButton = require 'scripts.s3.components.pinButton'

local pinned = false
local element

element = ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    pinButton {
      pinned = pinned,
      onToggle = function(value)
        pinned = value
        print('Pinned:', value)
        element:update()
      end,
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `pinned` | boolean? | Initial pin state; defaults to `false`. |
| `onToggle` | function? | Receives the new pin state. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). A supplied `props.size` must be exactly 19×19. The component does not update the mounted element or persist the pin state.

## See also

[caption](@/h3lp_yours3lf/docs/api/components/caption.md) · [window](@/h3lp_yours3lf/docs/api/components/window.md) · [toggle](@/h3lp_yours3lf/docs/api/components/toggle.md)
