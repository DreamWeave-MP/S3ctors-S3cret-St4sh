---
title: divider
description: Draw a theme-aware horizontal or vertical separator.
weight: 26
extra:
  kind: api
---

Builds a one-pixel theme-aware separator by default. A divider stretches across its parent on the divider axis unless `length` is supplied.

## Example

```lua
local H3UI = require('openmw.interfaces').H3UI

local section = H3UI.column {
    gap = 4,
    H3UI.text { text = 'Spells', tone = 'accent' },
    H3UI.divider(),
    H3UI.text 'Detect Creature',
}
```

For a vertical separator:

```lua
H3UI.divider {
    orientation = 'vertical',
    thickness = 1,
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `orientation` | `'horizontal'` or `'vertical'`? | Divider direction; defaults to `horizontal`. |
| `thickness` | number? | Positive thickness; defaults to `1`. |
| `length` | number? | Fixed length. Omit to stretch across the parent axis. |
| `color` | openmw.util.Color? | Override the active H3UI chrome-border color. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md).

## See also

[row](@/h3lp_yours3lf/docs/api/components/row.md) · [column](@/h3lp_yours3lf/docs/api/components/column.md) · [box](@/h3lp_yours3lf/docs/api/components/box.md)
