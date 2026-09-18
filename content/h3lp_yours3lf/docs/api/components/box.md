---
title: box
description: Put content in the shared H3UI box treatment.
weight: 12
extra:
  kind: api
---

Builds an H3UI box around optional content using the active appearance's thin frame. H3 renders the frame above child content so images cannot cover the border. Supplying fixed `size` or `relativeSize` geometry keeps the framed surface at that geometry instead of allowing child content to resize it. Pass `template` to replace the H3 frame entirely.

## Example

```lua
local ui = require 'openmw.ui'
local H3UI = require('openmw.interfaces').H3UI

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    H3UI.box {
      children = {
        H3UI.text {
          text = 'A reusable framed H3UI.box',
        },
      },
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `template` | openmw.ui.Template? | Replaces the default OpenMW box template. |
| `padding` | number? | Empty space between the frame and the content on all four sides; defaults to `4`. |
| `content` | table? | Child content; takes precedence over `children`. |
| `children` | table? | Child layouts used when `content` is absent. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md).

## See also

[bookFrame](@/h3lp_yours3lf/docs/api/components/book-frame.md) · [tooltip](@/h3lp_yours3lf/docs/api/components/tooltip.md)
