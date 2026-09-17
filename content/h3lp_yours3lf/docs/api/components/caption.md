---
title: caption
description: Build a centered Morrowind title strip with optional controls.
weight: 51
extra:
  kind: api
---

{% usage_note(title="Advanced building block") %}
This module is documented for H3 component and chrome authors. Normal mod UI should use the constructors exposed by `I.H3UI`; this primitive is not part of the application-facing constructor catalog.
{% end %}

Builds a horizontal title strip from head blocks and centered text. It can append a pin control and/or close button; it does not close a parent window. Give it a fixed-width Widget parent because its default width is relative.

## Example

```lua
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local caption = require 'scripts.s3.components.caption'

ui.create {
  layer = 'Windows',
  props = {
    size = util.vector2(320, 20),
  },
  content = ui.content {
    caption {
      text = 'Inventory',
      pinnable = true,
      closable = true,
      onPin = function(pinned)
        print('Pinned:', pinned)
      end,
      onClose = function()
        print('Closed')
      end,
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `text` | string | Caption text. |
| `pinnable` | boolean? | Adds a pin control. |
| `pinned` | boolean? | Initial pin state. |
| `onPin` | function? | Receives the new pin state. |
| `closable` | boolean? | Adds a close control. |
| `onClose` | function? | Runs when close is pressed. |
| `closeLabel` | string? | Accessible close-button label. |
| `height` | number? | Strip height; defaults to `20`. Captions with pin or close controls require at least `20`; captions without controls require at least `4`. |
| `textProps` | table? | Properties for the caption text. |
| `pinProps` | table? | Properties for the pin control. |
| `closeProps` | table? | Properties for the close control. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). The default relative width requires a parent with explicit width; use the default Widget with `props.size` for a standalone caption.

## See also

[headBlock](@/h3lp_yours3lf/docs/api/components/head-block.md) · [pinButton](@/h3lp_yours3lf/docs/api/components/pin-button.md) · [window](@/h3lp_yours3lf/docs/api/components/window.md)
