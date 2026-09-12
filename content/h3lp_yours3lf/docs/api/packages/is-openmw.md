---
title: isOpenMW
description: Detect whether the OpenMW Lua runtime is available.
weight: 5
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.isOpenMW' → boolean") }}

Use this small compatibility probe when one shared Lua file can run under OpenMW and another runtime, but an OpenMW-only import must be guarded.

```lua
local isOpenMW = require 'scripts.s3.isOpenMW'

if isOpenMW then
    local core = require 'openmw.core'
    print('OpenMW time:', core.getSimulationTime())
else
    print('OpenMW Lua is not available')
end
```

The module calls `pcall(require, 'openmw.core')` once while loading and returns only that boolean. It never propagates an OpenMW import failure or has engine side effects. The result does not identify an OpenMW version or prove that another context-specific module is legal.

Use the result before requiring context-specific OpenMW modules. If the file is already an OpenMW-only script, an `---@omw-context` annotation and a direct require are clearer than a compatibility branch.
