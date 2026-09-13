---
title: box
description: Put content in the shared H3UI box treatment.
weight: 12
extra:
  kind: api
---

Builds an H3UI box around optional content. The default template is OpenMW's `I.MWUI.templates.box`; pass `template` to use another supported template.

## Example

```lua
local ui = require 'openmw.ui'
local box = require 'scripts.s3.components.box'
local text = require 'scripts.s3.components.text'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    box {
      children = {
        text {
          text = 'A reusable framed box',
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

[bookFrame](@/h3lp_yours3lf/docs/api/components/book-frame.md) · [dialog](@/h3lp_yours3lf/docs/api/components/dialog.md) · [tooltip](@/h3lp_yours3lf/docs/api/components/tooltip.md)
