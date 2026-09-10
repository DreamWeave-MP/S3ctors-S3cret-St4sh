---
title: Interface Control
description: Configure T4rg3t5 and query its live target state from a player script.
weight: 10
extra:
  api_docs: true
  kind: example
---

The [Manager](@/t4rg3t5/docs/api/interface.md) is T4rg3t5's live player interface. Settings written through it take effect immediately.

```lua
---@omw-context player
local I = require 'openmw.interfaces'

local Manager = I.S3LockOn and I.S3LockOn.Manager

local function enableLineOfSightLock()
    if not Manager then return false end

    Manager.TargetLockToggle = true
    Manager.CheckLOS = true
    Manager.ThirdPersonLockCamera = true
    return true
end

local function acquireNearestTarget()
    if not Manager then return end
    return Manager.selectNearestTarget()
end

local function readCurrentTarget()
    if not Manager then return end

    local target = Manager.getTargetObject()
    if not target or not target:isValid() then return end
    return target
end
```

Call these from an explicit action, not `onFrame`. T4rg3t5 already owns target acquisition; no need to help it 60 times a second.

For lock state, use `getTargetObject()`. Marker visibility is just presentation.
