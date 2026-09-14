---
title: searchInput
description: Build a text search field with an optional clear button.
weight: 46
extra:
  kind: api
---

Builds a row containing a bordered TextEdit named `input` and, by default, a clear button named `clear`. OpenMW TextEdit has no placeholder property; provide placeholder-like text separately.

## Example

```lua
local ui = require 'openmw.ui'
local searchInput = require 'scripts.s3.components.searchInput'

local query = ''
local element

element = ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    searchInput {
      value = query,
      clearable = true,
      clearLabel = 'Clear',
      onChange = function(value)
        query = value
        print('Search:', query)
        element:update()
      end,
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `value` | string? | Initial editor text. |
| `onChange` | function? | Receives text changes and clear as `''`. |
| `clearable` | boolean? | Shows the clear button; enabled by default. |
| `clearLabel` | string? | Label for the clear button. |
| `bordered` | boolean? | Draws top, left, and bottom borders around the editor; enabled by default. |
| `inputProps` | table? | Properties for the nested editor. |
| `inputEvents` | table? | Events for the nested editor. |
| `inputExternal` | table? | External properties for the nested editor. |
| `template` | openmw.ui.Template? | Replaces the default row template. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). Editor handlers belong in `inputEvents`; row handlers belong in `events`.

## See also

[textInput](@/h3lp_yours3lf/docs/api/components/text-input.md) · [numberInput](@/h3lp_yours3lf/docs/api/components/number-input.md) · [list](@/h3lp_yours3lf/docs/api/components/list.md)
