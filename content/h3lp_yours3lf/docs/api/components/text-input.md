---
title: textInput
description: Build a plain OpenMW TextEdit line.
weight: 60
extra:
  kind: api
---

Builds a `ui.TYPE.TextEdit`, using OpenMW's `I.MWUI.templates.textEditLine` by default.

## Example

```lua
local async = require 'openmw.async'
local ui = require 'openmw.ui'
local textInput = require 'scripts.s3.components.textInput'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    textInput {
      text = 'Nerevarine',
      events = {
        textChanged = async:callback(function(value)
          print('Name:', value)
          return true
        end),
      },
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `text` | string? | Initial editor text. |
| `template` | openmw.ui.Template? | Replaces the default OpenMW text-edit template. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). Events are passed through unchanged; wrap OpenMW callbacks with `async:callback`.

## See also

[numberInput](@/h3lp_yours3lf/docs/api/components/number-input.md) · [searchInput](@/h3lp_yours3lf/docs/api/components/search-input.md) · [text](@/h3lp_yours3lf/docs/api/components/text.md)
