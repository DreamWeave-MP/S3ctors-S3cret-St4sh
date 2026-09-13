---
title: Pool
description: Reuse short-lived objects with explicit ownership and release rules.
weight: 30
extra:
  kind: api
---

{{ api_signature(value="Pool.new(capacity, factory?, reset?) → pool") }}

Require `scripts.s3.pool`. A pool keeps reusable objects ready for short bursts of work. It is an optimization for measured allocation pressure, not a replacement for ordinary tables.

## Construction

`capacity` must be a positive integer. Construction immediately creates that many objects. The default factory creates empty tables; the default reset clears their keys in place.

A custom factory takes no arguments and must return a non-nil value. A custom reset receives the released object. Non-table objects require a custom reset.

```lua
local Pool = require 'scripts.s3.pool'
local vectors = Pool.new(4, function()
    return {
        x = 0,
        y = 0,
    }
end, function(vector)
    vector.x = 0
    vector.y = 0
end)

local vector = vectors:acquire()
vector.x = 12
print(vector.x)
vectors:release(vector)
```

{% usage_note(title="Borrowed object · Lifetime ends at release") %}
After `release`, do not read, write, retain, or forward the object. Do not send it into deferred work and then release it. The pool can hand the same object to another caller immediately.
{% end %}

## Members

| Call | Result / behavior |
| --- | --- |
| `pool:acquire()` | Checks out an object; allocates a new one if none are available. |
| `pool:release(object)` | Resets it, then retains it if there is room. Excess objects are dropped. |
| `pool:available()` | Number of idle objects. |
| `pool:capacity()` | Maximum idle objects retained, not a limit on concurrent acquisitions. |
| `pool:allocated()` | Current pool-created objects: idle plus checked out. |
| `pool:stats()` | Four return values: `available, in_use, allocated, capacity`; no result table. |

There is no ownership or double-release check. Release each acquired object exactly once to the pool it came from. Double release can cause two callers to receive the same object; foreign releases also invalidate accounting. Never release `nil`.

See [Pooling and Signals](@/h3lp_yours3lf/docs/examples/pooling-and-signals.md) for synchronous payload reuse and error-safe release.
