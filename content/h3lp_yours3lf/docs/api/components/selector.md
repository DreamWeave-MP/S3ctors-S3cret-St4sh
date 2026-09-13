---
title: selector
description: Choose one item with previous and next buttons.
weight: 42
extra:
  kind: api
---

Builds a horizontal row containing previous, value, and next controls. Items may be strings or `{ label, value }` tables; the callback receives the original item.

## Example

```lua
local ui = require 'openmw.ui'
local selector = require 'scripts.s3.components.selector'

local modes = {
  'Compact',
  'Balanced',
  'Verbose',
}
local selected = 2
local element

element = ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    selector {
      items = modes,
      selected = selected,
      onSelect = function(index, item)
        selected = index
        print('Mode:', item)
        element:update()
      end,
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `items` | table | Strings or `{ label, value }` entries. |
| `selected` | integer? | Initial selected index. |
| `onSelect` | function? | Receives the index and original item. |
| `emptyLabel` | string? | Text shown when there are no items. |
| `buttonProps` | table? | Properties for previous and next buttons. |
| `iconProps` | table? | Properties for arrow icons. |
| `labelProps` | table? | Properties for the selected value. |
| `labelTemplate` | openmw.ui.Template? | Template for the selected value. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). Empty and one-item lists are valid and cannot move.

## See also

[tabs](@/h3lp_yours3lf/docs/api/components/tabs.md) · [button](@/h3lp_yours3lf/docs/api/components/button.md) · [list](@/h3lp_yours3lf/docs/api/components/list.md)
