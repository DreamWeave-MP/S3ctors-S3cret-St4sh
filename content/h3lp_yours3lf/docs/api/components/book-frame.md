---
title: bookFrame
description: Frame content with the solid Morrowind book treatment.
weight: 30
extra:
  kind: api
---

Builds a solid H3UI framed body, optionally preceded by a header title. It is a layout, not a window.

## Example

```lua
local ui = require 'openmw.ui'
local H3UI = require('openmw.interfaces').H3UI

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    H3UI.bookFrame {
      title = 'Notes',
      children = {
        H3UI.text {
          text = 'A solid framed page.',
        },
      },
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `title` | string? | Optional heading text. |
| `titleProps` | table? | Properties for the generated heading. |
| `backgroundProps` | table? | Properties for the generated background; H3UI themes use this slot for the configured background color and transparency. |
| `template` | openmw.ui.Template? | Replaces the default solid frame template. |
| `content` | table? | Child content; takes precedence over `children`. |
| `children` | table? | Child layouts used when `content` is absent. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md).

## See also

[box](@/h3lp_yours3lf/docs/api/components/box.md) · [window](@/h3lp_yours3lf/docs/api/components/window.md)
