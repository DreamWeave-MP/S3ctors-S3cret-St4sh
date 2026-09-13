---
title: tooltip
description: Build boxed explanatory content without positioning it.
weight: 61
extra:
  kind: api
---

Builds a transparent H3UI box with padding and a paragraph-text child by default. It is content, not a tooltip manager.

## Example

```lua
local ui = require 'openmw.ui'
local tooltip = require 'scripts.s3.components.tooltip'
local util = require 'openmw.util'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    tooltip {
      text = 'This explains the item under the pointer.',
      props = {
        position = util.vector2(100, 100),
      },
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `text` | string? | Text for the generated paragraph. |
| `textProps` | table? | Properties for the generated paragraph. |
| `template` | openmw.ui.Template? | Replaces the default transparent box template. |
| `content` | table? | Custom child content; replaces generated text. |
| `children` | table? | Custom child layouts used when `content` is absent. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md).

## See also

[dialog](@/h3lp_yours3lf/docs/api/components/dialog.md) · [text](@/h3lp_yours3lf/docs/api/components/text.md) · [window](@/h3lp_yours3lf/docs/api/components/window.md)
