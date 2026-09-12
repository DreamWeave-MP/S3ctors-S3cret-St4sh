---
title: Pooling and Signals
description: Borrow an event payload, consume it synchronously, and release it safely.
weight: 10
extra:
  kind: example
---

Use this pattern only when profiling identifies repeated payload allocations as a problem. For occasional notifications, an ordinary table and [Signal](@/h3lp_yours3lf/docs/api/modules/signal.md) are simpler.

```lua
local Pool = require 'scripts.s3.pool'
local Signal = require 'scripts.s3.signal'

local payloads = Pool.new(8)
local changed = Signal.new()
local total = 0

local handle = changed:connect(function(data)
    total = total + data.amount
end)

local function publish(amount)
    local data = payloads:acquire()
    data.amount = amount
    local ok, err = pcall(changed.fire, changed, data)
    payloads:release(data)
    if not ok then error(err, 0) end
end

publish(3)
publish(4)
assert(total == 7)
assert(payloads:available() == 8)
handle:disconnect()
```

The listener keeps a number, not the payload. `fire` completes synchronously, so the producer can release the table afterward. The protected call ensures release still happens if a listener raises; the error is then rethrown, not swallowed. This cleanup guarantee has overhead—measure the whole pattern, not just table allocations.

{% usage_note(title="Do not retain the payload") %}
A listener must not store `data`, capture it for a timer, or forward it across an OpenMW event boundary and assume it remains unchanged. Copy the needed values into independently owned data before returning if work must outlive this dispatch.
{% end %}

The pool's default reset clears released tables. Populate every needed field on each acquisition. Capacity limits idle objects retained, not total acquisitions; exhaustion allocates rather than blocking.

Read [Pool](@/h3lp_yours3lf/docs/api/modules/pool.md) for accounting and release constraints, [Signal](@/h3lp_yours3lf/docs/api/modules/signal.md) for listener behavior, and [State and Context](@/h3lp_yours3lf/docs/concepts/state-and-context.md) before introducing deferred work.
