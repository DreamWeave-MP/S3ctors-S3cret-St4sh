---
title: button
description: Build an H3UI text button.
weight: 32
extra:
  kind: api
---

Builds an H3UI text button using OpenMW's built-in box template. `label` creates the default padded text child; custom `content` or `children` replaces it.

## Example

```lua
local async = require 'openmw.async'
local ui = require 'openmw.ui'
local button = require 'scripts.s3.components.button'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    button {
      label = 'Press me',
      events = {
        mouseClick = async:callback(function()
          print('Button pressed')
          return true
        end),
      },
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `label` | string? | Text for the generated button label. |
| `labelProps` | table? | Properties for the generated label. |
| `content` | table? | Custom content; replaces the generated label. |
| `children` | table? | Custom child layouts when `content` is absent. |
| `template` | openmw.ui.Template? | Replaces the default H3UI button template. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md).

Wrap OpenMW callbacks with `async:callback`; H3 passes low-level events through unchanged.

## See also

[toggle](@/h3lp_yours3lf/docs/api/components/toggle.md) · [iconButton](@/h3lp_yours3lf/docs/api/components/icon-button.md) · [dialog](@/h3lp_yours3lf/docs/api/components/dialog.md)
