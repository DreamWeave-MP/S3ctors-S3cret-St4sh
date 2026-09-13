---
title: iconButton
description: Build an H3UI button with a caller-provided icon and optional label.
weight: 33
extra:
  kind: api
---

Builds an H3UI button with a centered row containing an image and, optionally, a label. Pass a texture resource or texture options for the icon.

## Example

```lua
local async = require 'openmw.async'
local ui = require 'openmw.ui'
local iconButton = require 'scripts.s3.components.iconButton'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    iconButton {
      label = 'Map',
      resource = {
        path = 'white',
      },
      events = {
        mouseClick = async:callback(function()
          print('Map pressed')
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
| `resource` | openmw.ui.TextureResource or openmw.ui.TextureResourceOptions | Icon texture resource or options for one. |
| `label` | string? | Optional text beside the icon. |
| `iconProps` | table? | Properties for the icon. |
| `labelProps` | table? | Properties for the label. |
| `template` | openmw.ui.Template? | Replaces the default H3UI button template. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). Wrap OpenMW callbacks with `async:callback`.

## See also

[button](@/h3lp_yours3lf/docs/api/components/button.md) · [image](@/h3lp_yours3lf/docs/api/components/image.md) · [itemSlot](@/h3lp_yours3lf/docs/api/components/item-slot.md)
