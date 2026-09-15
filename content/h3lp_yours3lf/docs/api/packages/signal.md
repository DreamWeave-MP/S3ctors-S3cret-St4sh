---
title: Signal
description: Synchronous listeners with priorities, explicit disconnection, and borrowed payloads.
weight: 20
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.signal' → Signal; Signal.new() → signal") }}

A Signal connects one producer to several listeners in the same Lua execution environment. Calling `fire` runs those listeners before returning. It does not send an OpenMW event or cross script-context boundaries.

{% usage_note(title="Plain Lua coordination") %}
This module has no OpenMW imports. A signal only reaches listeners connected to that particular instance; constructing another signal elsewhere does not connect the two.
{% end %}

## Example

```lua
local Signal = require 'scripts.s3.signal'
local changed = Signal.new()
local handle = changed:connect(function(value)
    print('value changed: ' .. value)
end)

changed:fire('ready')
handle:disconnect()
changed:fire('not delivered')
```

Only `value changed: ready` is printed. Keep the handle when you need to remove one listener.

## Members

| Call | Result / behavior |
| --- | --- |
| `Signal.new()` | New signal with no listeners. |
| `signal:connect(fn, priority?)` | Connection handle; `fn(data)` receives one argument. Priority defaults to `0`. |
| `signal:once(fn, priority?)` | Connection handle for a one-shot listener. |
| `handle:disconnect()` | Disconnects this listener; repeated calls are harmless. |
| `signal:fire(data)` | Synchronously dispatches one payload. |
| `signal:disconnect_all()` | Removes all listeners, deferred if currently dispatching. |
| `signal:block()` / `signal:unblock()` | Suppresses / resumes dispatch. Suppressed payloads are not queued. |
| `signal:blocked()` | Whether dispatch is blocked. |
| `signal:count()` | Current listener count. |

Lower priorities run first. Equal priorities run in connection order. Connections, disconnections, and clearing requested inside a listener take effect after the current dispatch: disconnecting a later listener does not skip it in the current pass.

Recursive `fire` on the same signal raises an error. Listener errors propagate after internal dispatch cleanup; do not assume the remaining listeners ran successfully.

## Payload ownership and cost

Signal passes the supplied value, not a deep copy. It neither clears nor pools tables. A producer can reuse a table only if every listener finishes using it synchronously and retains no reference.

Connections allocate listener entries and handles. Listener-list mutations during dispatch allocate pending operations. Ordinary dispatch with stable listeners avoids those allocations; one-shot cleanup and error paths have additional work.

Start with ordinary payloads. Use [Pool](@/h3lp_yours3lf/docs/api/packages/pool.md) only when measured allocation pressure justifies manual lifetime management. The [pooling example](@/h3lp_yours3lf/docs/examples/pooling-and-signals.md) demonstrates the complete acquire/fire/release sequence.

For choosing between synchronous interfaces, local observer patterns, and OpenMW events, see Cod3x's [Event Architecture](@/cod3x/docs/practice/events.md).
