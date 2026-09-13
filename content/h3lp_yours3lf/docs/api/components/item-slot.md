---
title: itemSlot
description: Display an icon in a bordered slot with an optional count.
weight: 35
extra:
  kind: api
---

Builds a bordered icon slot with an optional normal-text count. It does not inspect inventory or query game state.

## Example

```lua
local ui = require 'openmw.ui'
local itemSlot = require 'scripts.s3.components.itemSlot'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    itemSlot {
      resource = {
        path = 'white',
      },
      count = 4,
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `resource` | openmw.ui.TextureResource or openmw.ui.TextureResourceOptions | Icon texture resource or options for one. |
| `count` | number? | Optional count rendered over the icon. |
| `iconProps` | table? | Properties for the icon. |
| `countProps` | table? | Properties for the count label. |
| `template` | openmw.ui.Template? | Replaces the default H3UI slot template. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). Count values become text during construction; live inventory changes require an owner update or rebuild.

## See also

[grid](@/h3lp_yours3lf/docs/api/components/grid.md) · [image](@/h3lp_yours3lf/docs/api/components/image.md) · [iconButton](@/h3lp_yours3lf/docs/api/components/icon-button.md)
