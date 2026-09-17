---
title: textInput
description: Build a plain H3UI text-edit line with a semantic change callback.
weight: 60
extra:
  kind: api
---

Builds a plain `ui.TYPE.TextEdit` with H3UI text appearance and a 150-pixel default width. `onChange` is the normal application callback for edited text; raw `events` remain available for lower-level TextEdit behavior.

## Example

```lua
local H3UI = require('openmw.interfaces').H3UI

local nameInput = H3UI.textInput {
    text = 'Nerevarine',
    onChange = function(value)
        characterName = value
    end,
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `text` | string? | Initial editor text. |
| `onChange` | function? | Receives the current editor text after it changes. |
| `template` | openmw.ui.Template? | Replaces the default OpenMW text-edit template. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md).

## See also

[numberInput](@/h3lp_yours3lf/docs/api/components/number-input.md) · [searchInput](@/h3lp_yours3lf/docs/api/components/search-input.md) · [text](@/h3lp_yours3lf/docs/api/components/text.md)
