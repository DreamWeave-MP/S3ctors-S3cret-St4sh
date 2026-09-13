---
title: text
description: Add Morrowind-styled text to a layout.
weight: 13
extra:
  kind: api
---

Builds a `ui.TYPE.Text` layout and supplies `props.text`. Without a template, H3 applies Morrowind's normal text color and size.

## Example

```lua
local ui = require 'openmw.ui'
local text = require 'scripts.s3.components.text'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    text {
      text = 'Hello from H3',
      props = {
        textAlignH = ui.ALIGNMENT.Center,
      },
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `text` | string? | Initial text; copied to `props.text`. |
| `template` | openmw.ui.Template? | Replaces the default text template. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md).

## See also

[textInput](@/h3lp_yours3lf/docs/api/components/text-input.md) · [caption](@/h3lp_yours3lf/docs/api/components/caption.md) · [listItem](@/h3lp_yours3lf/docs/api/components/list-item.md)
