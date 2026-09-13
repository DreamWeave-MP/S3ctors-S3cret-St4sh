---
title: meter
description: Show a bounded horizontal fill and empty indicator.
weight: 34
extra:
  kind: api
---

Builds a bordered Widget with fill and empty Image children. `value / max` is clamped to `0..1`; `max <= 0` produces an empty meter.

## Example

```lua
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local meter = require 'scripts.s3.components.meter'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    meter {
      value = 65,
      max = 100,
      props = {
        size = util.vector2(240, 18),
      },
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `value` | number? | Current fill value; defaults to `0`. |
| `max` | number? | Full-scale value; defaults to `1`. |
| `fillProps` | table? | Properties for the filled image. |
| `emptyProps` | table? | Properties for the empty image. |
| `template` | openmw.ui.Template? | Replaces the default H3UI meter template. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). The ratio is calculated during construction; rebuild or update child image layouts when it changes.

## See also

[slider](@/h3lp_yours3lf/docs/api/components/slider.md) · [itemSlot](@/h3lp_yours3lf/docs/api/components/item-slot.md) · [image](@/h3lp_yours3lf/docs/api/components/image.md)
