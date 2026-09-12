---
title: szudzik
description: Map signed integer coordinate pairs to one integer key and recover them later.
weight: 72
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.szudzik' → { getIndex, unpair }") }}

Use Szudzik pairing when a sparse grid or coordinate map needs one numeric key instead of nested tables. The mapping is reversible for integer coordinates and allocates no tables.

```lua
local szudzik = require 'scripts.s3.szudzik'

local key = szudzik.getIndex(cell.gridX, cell.gridY)
occupied[key] = true

local x, y = szudzik.unpair(key)
```

| Function | Behavior |
| --- | --- |
| `getIndex(x, y)` | Return one integer key for the signed integer pair. |
| `unpair(z)` | Return the original `x, y` pair for a key produced by `getIndex`. |

Inputs are expected to be integers. The module performs no type or range validation; fractional, negative-key, or otherwise invalid inputs can produce meaningless results.
