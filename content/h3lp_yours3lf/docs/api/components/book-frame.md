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
local bookFrame = require 'scripts.s3.components.bookFrame'
local text = require 'scripts.s3.components.text'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    bookFrame {
      title = 'Notes',
      children = {
        text {
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
| `template` | openmw.ui.Template? | Replaces the default solid frame template. |
| `content` | table? | Child content; takes precedence over `children`. |
| `children` | table? | Child layouts used when `content` is absent. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md).

## See also

[dialog](@/h3lp_yours3lf/docs/api/components/dialog.md) · [box](@/h3lp_yours3lf/docs/api/components/box.md) · [window](@/h3lp_yours3lf/docs/api/components/window.md)
