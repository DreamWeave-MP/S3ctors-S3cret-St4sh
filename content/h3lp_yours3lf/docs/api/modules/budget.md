---
title: Budget
description: Spread measured work across frames using a wall-clock execution budget.
weight: 46
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.budget' → budget; budget(seconds) → begin, remaining, spent") }}

You have 800 expensive things to rebuild and do not want to eat the entire frame doing it. Budget tells your loop when its time slice is spent. Keep your own cursor and continue next frame.

{% usage_note(title="OpenMW runtime · You supply the loop") %}
This helper uses the real-time clock from `openmw.core`. It does not register `onUpdate`, yield work, or remember a budget window across saves. Call `begin()` at the start of each window and poll `spent()` or `remaining()` yourself.
{% end %}

```lua
local budget = require 'scripts.s3.budget'
local beginWork, _, budgetSpent = budget(0.001)
local pendingObjects = {}
local nextObject = 1

local function rebuildObjects(objects)
    pendingObjects = objects
    nextObject = 1
end

local function onUpdate()
    if nextObject > #pendingObjects then return end

    beginWork()

    while nextObject <= #pendingObjects and not budgetSpent() do
        rebuildObject(pendingObjects[nextObject])
        nextObject = nextObject + 1
    end
end

return {
    eventHandlers = {
        MyModRebuildObjects = rebuildObjects,
    },
    engineHandlers = {
        onUpdate = onUpdate,
    },
}
```

Call `rebuildObjects(objects)` when the backlog changes. The cursor matters: restarting `ipairs(pendingObjects)` every frame would redo the same work.

`seconds` must be positive. Before the first `beginWork()`, `remaining()` is the full budget and `budgetSpent()` is false; each new begin starts a window.

| Function | Result |
| --- | --- |
| `begin()` | Records the current wall-clock start. |
| `remaining()` | Remaining seconds, clamped to zero; full budget before `begin()`. |
| `spent()` | Whether elapsed execution time has reached the budget; false before `begin()`. |

The budget measures code execution between calls, not the duration of the previous frame. It cannot interrupt one indivisible operation, and it does not guarantee that `rebuildObject` itself fits inside the remaining time.

Use Budget when profiling shows that bounded incremental work matters. A simple item count or ordinary `onUpdate` loop is clearer when time pressure is not the problem.
