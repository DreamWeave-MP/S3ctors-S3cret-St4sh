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
local H3UI = require('openmw.interfaces').H3UI

local query = ''

local search = H3UI.searchInput {
    value = query,
    clearable = true,
    clearLabel = 'Clear',
    onChange = function(value)
        query = value
    end,
    onCommit = function(value)
        print('Search committed:', value)
    end,
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `value` | string? | Initial editor text. |
| `onChange` | function? | Receives each text change and clear as `''`. |
| `onCommit` | function? | Receives the current text when editing focus is released; clearing also commits immediately. |
| `clearable` | boolean? | Shows the clear button; enabled by default. |
| `clearLabel` | string? | Label for the clear button. |
| `bordered` | boolean? | Draws the active H3UI thin frame around the editor; enabled by default. |
| `inputProps` | table? | Properties for the nested editor. |
| `inputEvents` | table? | Events for the nested editor. |
| `inputExternal` | table? | External properties for the nested editor. |
| `template` | openmw.ui.Template? | Replaces the nested TextEdit template. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). Editor handlers belong in `inputEvents`; row handlers belong in `events`. If filtering requires destroying and rebuilding a mounted root, update the query in `onChange` and rebuild from `onCommit`, deferred by a tick: a synchronous rebuild inside focus loss destroys the element mid-click and eats the click that released focus. Rebuilding from every text change destroys TextEdit focus.

## See also

[textInput](@/h3lp_yours3lf/docs/api/components/text-input.md) · [numberInput](@/h3lp_yours3lf/docs/api/components/number-input.md) · [list](@/h3lp_yours3lf/docs/api/components/list.md)
