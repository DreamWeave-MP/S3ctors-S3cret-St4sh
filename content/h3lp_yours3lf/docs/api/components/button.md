---
title: button
description: Build an H3UI text button with a semantic activation callback.
weight: 32
extra:
  kind: api
---

Builds a framed H3UI text button. `label` creates the default text child; custom `content` or `children` replaces it. Prefer `onActivate` for the normal click action and use raw `events` only for additional OpenMW event behavior.

## Example

```lua
local H3UI = require('openmw.interfaces').H3UI

local deleteButton = H3UI.button {
    label = 'Delete',
    tone = 'negative',
    onActivate = function()
        deleteSelected()
        return true
    end,
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `label` | string? | Text for the generated button label. |
| `onActivate` | function? | Runs for the normal button activation. |
| `labelProps` | table? | Properties for the generated label. |
| `content` | table? | Custom content; replaces the generated label. |
| `children` | table? | Custom child layouts when `content` is absent. |
| `template` | openmw.ui.Template? | Replaces the default H3UI button frame. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). If both `events.mouseClick` and `onActivate` are present, H3 composes them rather than discarding the caller event.

## See also

[toggle](@/h3lp_yours3lf/docs/api/components/toggle.md) · [iconButton](@/h3lp_yours3lf/docs/api/components/icon-button.md)
