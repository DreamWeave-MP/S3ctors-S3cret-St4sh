---
title: listItem
description: Build an activatable padded list row with optional right-aligned secondary text.
weight: 23
extra:
  kind: api
---

Builds a padded H3UI list row. Without custom `content` or `children`, `label` creates the primary text and `secondary` optionally creates a right-aligned secondary value. This covers common Morrowind-style rows such as spell name plus `Cost/Chance` without forcing every caller to rebuild the same spacer/alignment structure.

## Example

```lua
local H3UI = require('openmw.interfaces').H3UI

local spell = H3UI.listItem {
    label = 'Detect Creature',
    secondary = '19/63',
    onActivate = function()
        selectSpell('Detect Creature')
        return true
    end,
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `label` | string? | Text for the generated primary label. |
| `secondary` | string or number? | Right-aligned secondary value. |
| `onActivate` | function? | Runs when the row is activated. |
| `labelProps` | table? | Properties for the generated primary label. |
| `secondaryProps` | table? | Properties for the generated secondary text. |
| `content` | table? | Custom child content; replaces generated label/secondary content. |
| `children` | table? | Custom child layouts when `content` is absent. |
| `template` | openmw.ui.Template? | Replaces the default row template. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md).

The H3UI style adapter exposes `label` and `secondary` slots for the generated text.

## See also

[list](@/h3lp_yours3lf/docs/api/components/list.md) · [button](@/h3lp_yours3lf/docs/api/components/button.md) · [text](@/h3lp_yours3lf/docs/api/components/text.md)
