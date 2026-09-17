---
title: iconButton
description: Build a framed button with an icon and optional label.
weight: 33
extra:
  kind: api
---

Builds an H3UI button with an icon and optional label. Use `onActivate` for the ordinary click action.

## Example

```lua
local H3UI = require('openmw.interfaces').H3UI

local mapButton = H3UI.iconButton {
    label = 'Map',
    resource = {
        path = 'textures/menu_icon_magic.dds',
    },
    onActivate = openMap,
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `resource` | openmw.ui.TextureResource or openmw.ui.TextureResourceOptions | Icon texture resource or options for one. |
| `label` | string? | Optional text beside the icon. |
| `onActivate` | function? | Runs for the normal button activation. |
| `iconProps` | table? | Properties for the icon. |
| `labelProps` | table? | Properties for the label. |
| `template` | openmw.ui.Template? | Replaces the default H3UI button frame. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). Raw `events` remain available for behavior outside the normal activation contract.

## See also

[button](@/h3lp_yours3lf/docs/api/components/button.md) · [image](@/h3lp_yours3lf/docs/api/components/image.md) · [itemSlot](@/h3lp_yours3lf/docs/api/components/item-slot.md)
