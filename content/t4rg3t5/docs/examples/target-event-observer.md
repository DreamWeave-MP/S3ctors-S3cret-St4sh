---
title: Target Event Observer
description: React to T4rg3t5 target transitions from a player script.
weight: 20
extra:
  api_docs: true
  kind: example
---

Listen for `S3TargetLockOnto` when your mod needs to react to target changes without polling.

```lua
---@omw-context player
return {
    eventHandlers = {
        S3TargetLockOnto = function(target)
            if target and target:isValid() then
                print(('Locked onto %s'):format(target.recordId))
            else
                print('Target lock cleared')
            end
        end,
    },
}
```

Need the current target rather than a notification? Ask the [Manager](@/t4rg3t5/docs/api/interface.md).
