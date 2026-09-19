---
title: tabs
description: Build a selectable tab strip without owning page content.
weight: 43
extra:
  kind: api
---

Builds a horizontal row of buttons. The selected tab gets its selected button and label properties plus the default `[ label ]` decoration. It does not create, hide, or update page content.

## Example

```lua
local ui = require 'openmw.ui'
local I = require 'openmw.interfaces'

local pages = {
  'General',
  'Advanced',
}
local element
local H3UI = I.H3UI.scope {
  invalidate = function()
    if element and element.layout then element:update() end
  end,
}
local page = H3UI.text {
  text = pages[1],
}

element = ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    H3UI.column {
      children = {
        H3UI.tabs {
          items = pages,
          onSelect = function(_, label)
            page.props.text = 'Showing ' .. label
          end,
        },
        page,
      },
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `items` | table | Tab labels or value entries. |
| `selected` | integer? | Initial selected index. |
| `onSelect` | function? | Receives the index and selected item. |
| `buttonProps` | table? | Base button properties. |
| `selectedProps` | table? | Properties merged onto the selected button. |
| `labelProps` | table? | Base label properties. |
| `selectedLabelProps` | table? | Properties merged onto the selected label. |
| `selectedPrefix` | string? | Prefix for the selected label. |
| `selectedSuffix` | string? | Suffix for the selected label. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). Page content and durable selection remain caller-owned.

## See also

[selector](@/h3lp_yours3lf/docs/api/components/selector.md) · [button](@/h3lp_yours3lf/docs/api/components/button.md) · [window](@/h3lp_yours3lf/docs/api/components/window.md)
