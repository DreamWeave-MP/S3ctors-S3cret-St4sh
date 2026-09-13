---
title: dialog
description: Compose a dialog-style body without owning a window.
weight: 31
extra:
  kind: api
---

Builds a Window-style `ui.TYPE.Widget` with optional title and padding. Give it `props.size` or `props.relativeSize`; a Widget does not size itself to its children. It does not create a window, choose a layer, manage visibility, or manage focus.

## Example

```lua
local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local button = require 'scripts.s3.components.button'
local dialog = require 'scripts.s3.components.dialog'
local text = require 'scripts.s3.components.text'

local element
element = ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  props = {
    visible = true,
  },
  content = ui.content {
    dialog {
      title = 'Confirm action',
      props = {
        position = util.vector2(80, 80),
        size = util.vector2(320, 120),
      },
      children = {
        text {
          text = 'Continue?',
        },
        button {
          label = 'Close',
          events = {
            mouseClick = async:callback(function()
              element.layout.props.visible = false
              element:update()
              return true
            end),
          },
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
| `template` | openmw.ui.Template? | Replaces the default dialog template. |
| `content` | table? | Child content; takes precedence over `children`. |
| `children` | table? | Child layouts used when `content` is absent. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md).

Set `props.size` or `props.relativeSize` when the dialog is mounted as a child of a fitting container; the dialog's Widget wrapper does not infer its size from its body.

## See also

[bookFrame](@/h3lp_yours3lf/docs/api/components/book-frame.md) · [window](@/h3lp_yours3lf/docs/api/components/window.md) · [button](@/h3lp_yours3lf/docs/api/components/button.md)
