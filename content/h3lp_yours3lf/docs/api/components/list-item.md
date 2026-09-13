---
title: listItem
description: Build a padded row for one list entry.
weight: 23
extra:
  kind: api
---

Builds a padded H3UI row. Without `content` or `children`, it creates one normal-text child from `label`.

## Example

```lua
local ui = require 'openmw.ui'
local listItem = require 'scripts.s3.components.listItem'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    listItem {
      name = 'selected_item',
      label = 'A padded entry',
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `label` | string? | Text for the generated label. |
| `labelProps` | table? | Properties for the generated label. |
| `content` | table? | Custom child content; replaces the generated label. |
| `children` | table? | Custom child layouts when `content` is absent. |
| `template` | openmw.ui.Template? | Replaces the default row template. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md).

## See also

[list](@/h3lp_yours3lf/docs/api/components/list.md) · [button](@/h3lp_yours3lf/docs/api/components/button.md) · [text](@/h3lp_yours3lf/docs/api/components/text.md)
