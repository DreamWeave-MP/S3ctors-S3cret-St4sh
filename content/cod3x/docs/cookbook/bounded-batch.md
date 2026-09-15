---
title: Spread Polling Across Frames
description: Bound per-frame work while keeping an explicit freshness target.
weight: 20
extra:
  kind: example
---

When every target must eventually be checked but not every target must be fresh on every frame, maintain a cursor and process a bounded batch.

```lua
local currentIndex = 1
local MAX_PER_FRAME = 8

local function pollBatch(items)
  local count = #items
  if count == 0 then return end

  for _ = 1, math.min(MAX_PER_FRAME, count) do
    if currentIndex > count then currentIndex = 1 end

    poll(items[currentIndex])
    currentIndex = currentIndex + 1
  end
end
```

Production systems should choose the batch from a documented latency/budget target when practical. Reset the cursor when the underlying collection changes in a way that invalidates traversal assumptions.

See [Every Frame Is a Budget, Not an Invitation](@/cod3x/docs/anti-patterns/per-frame-everything.md).
