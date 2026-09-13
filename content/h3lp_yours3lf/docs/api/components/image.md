---
title: image
description: Place a caller-provided texture resource in a layout.
weight: 14
extra:
  kind: api
---

Builds a `ui.TYPE.Image` layout. Pass a texture resource or `openmw.ui.TextureResourceOptions`; H3 converts option tables with `ui.texture`.

## Example

```lua
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local image = require 'scripts.s3.components.image'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    image {
      resource = {
        path = 'white',
      },
      props = {
        size = util.vector2(32, 32),
      },
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `resource` | openmw.ui.TextureResource or openmw.ui.TextureResourceOptions | Texture resource or options for one; takes precedence over `props.resource`. |
| `template` | openmw.ui.Template? | Replaces the default image template. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md).

## See also

[iconButton](@/h3lp_yours3lf/docs/api/components/icon-button.md) · [itemSlot](@/h3lp_yours3lf/docs/api/components/item-slot.md) · [headBlock](@/h3lp_yours3lf/docs/api/components/head-block.md)
