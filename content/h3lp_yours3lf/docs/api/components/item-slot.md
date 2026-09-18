---
title: itemSlot
description: Display an activatable icon slot with an optional count.
weight: 35
extra:
  kind: api
---

Builds a bordered icon slot with an optional count. The H3 frame renders above the icon, and a supplied `props.size` fixes the total slot dimensions so icon/count content cannot resize the slot. It does not inspect inventory or query game state. Use `onActivate` when selecting or using the represented item.

## Example

```lua
local H3UI = require('openmw.interfaces').H3UI

local potion = H3UI.itemSlot {
    resource = {
        path = 'white',
    },
    count = 4,
    selected = selectedItemId == potionId,
    onActivate = function()
        selectPotion()
        return true
    end,
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `resource` | openmw.ui.TextureResource or openmw.ui.TextureResourceOptions | Icon texture resource or options for one. |
| `count` | number? | Optional count rendered over the icon. |
| `selected` | boolean? | Highlights the slot with the active theme color and exposes selected-state styling to H3UI themes. |
| `onActivate` | function? | Runs when the slot is activated. |
| `iconProps` | table? | Properties for the icon. |
| `countProps` | table? | Properties for the count label. |
| `template` | openmw.ui.Template? | Replaces the default H3UI slot frame. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). Count values become text during construction; live inventory changes require an owner update or rebuild.

## See also

[grid](@/h3lp_yours3lf/docs/api/components/grid.md) · [image](@/h3lp_yours3lf/docs/api/components/image.md) · [iconButton](@/h3lp_yours3lf/docs/api/components/icon-button.md)
