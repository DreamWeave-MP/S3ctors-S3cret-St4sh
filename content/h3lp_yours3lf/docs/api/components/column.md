---
title: column
description: Arrange children vertically with optional built-in gaps.
weight: 21
extra:
  kind: api
---

Builds a vertical `ui.TYPE.Flex`. Put child layouts directly in the array portion of the options table; `gap` inserts fixed spacing between them. Explicit `children` or `content` remains available when data is already in that form.

## Example

```lua
local H3UI = require('openmw.interfaces').H3UI

local panel = H3UI.column {
    gap = 8,
    H3UI.text 'Settings',
    H3UI.toggle {
        label = 'Enabled',
        value = true,
    },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| array children | openmw.ui.LayoutOrElement[]? | Direct child layouts. |
| `gap` | number? | Fixed vertical spacing inserted between children. |
| `content` | table? | Explicit child content; cannot be combined with array children. |
| `children` | table? | Explicit child layouts; cannot be combined with array children. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). The component always sets `props.horizontal = false`.

## See also

[row](@/h3lp_yours3lf/docs/api/components/row.md) · [spacer](@/h3lp_yours3lf/docs/api/components/spacer.md) · [window](@/h3lp_yours3lf/docs/api/components/window.md)
