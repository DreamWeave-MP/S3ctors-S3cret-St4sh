---
title: Reject Stale Deferred Work
description: Attach a generation to work that can outlive the state that requested it.
weight: 30
extra:
  kind: example
---

```lua
local generation = 0

local function requestRefresh()
  generation = generation + 1
  local requestGeneration = generation

  sendRequest {
    generation = requestGeneration,
  }
end

local function onRefreshComplete(result)
  if result.generation ~= generation then return end

  applyResult(result)
end
```

Increment the generation at every transition that makes older work invalid.

See [Paid For With Blood — Generations for Deferred Work](@/cod3x/docs/paid-for-with-blood/generation-counters.md).
