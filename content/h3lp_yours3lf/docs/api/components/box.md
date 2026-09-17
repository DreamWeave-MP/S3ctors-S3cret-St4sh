---
title: box
description: Put content in the shared H3UI box treatment.
weight: 12
extra:
  kind: api
---

Builds an H3UI box around optional content using the active appearance's thin frame. Pass `template` to use another supported template.

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
| `content` | table? | Child content; takes precedence over `children`. |
| `children` | table? | Child layouts used when `content` is absent. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md).

## See also

[bookFrame](@/h3lp_yours3lf/docs/api/components/book-frame.md) · [tooltip](@/h3lp_yours3lf/docs/api/components/tooltip.md)
