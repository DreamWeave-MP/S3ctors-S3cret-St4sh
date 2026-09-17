---
title: row
description: Arrange children horizontally with optional built-in gaps.
weight: 20
extra:
  kind: api
---

Builds a horizontal `ui.TYPE.Flex`. Put child layouts directly in the array portion of the options table; `gap` inserts fixed spacing between them. Explicit `children` or `content` remains available when data is already in that form.

## Example

```lua
local H3UI = require('openmw.interfaces').H3UI

local actions = H3UI.row {
    gap = 6,
    H3UI.button { label = 'Cancel', onActivate = cancel },
    H3UI.button {
        label = 'Apply',
        tone = 'positive',
        onActivate = apply,
    },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| array children | openmw.ui.LayoutOrElement[]? | Direct child layouts. |
| `gap` | number? | Fixed horizontal spacing inserted between children. |
| `content` | table? | Explicit child content; cannot be combined with array children. |
| `children` | table? | Explicit child layouts; cannot be combined with array children. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). The component always sets `props.horizontal = true`.

## See also

[column](@/h3lp_yours3lf/docs/api/components/column.md) · [spacer](@/h3lp_yours3lf/docs/api/components/spacer.md) · [divider](@/h3lp_yours3lf/docs/api/components/divider.md)
