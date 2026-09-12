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

Current consumers include [Static Switching System replacements](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content%2Fstatic_switching_system%2FScripts%2FstaticSwitcher%2FstaticReplacements.lua), its [module catalog](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content%2Fstatic_switching_system%2FScripts%2FstaticSwitcher%2FmoduleCatalog.lua), and [S3maphore's static collection](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content%2Fs3maphore%2F00%20Core%2Fscripts%2Fs3%2Fmusic%2FstaticCollection.lua).
