---
title: Debounce
description: Emit the latest value after a quiet interval, with caller-driven polling.
weight: 40
extra:
  kind: api
---

{{ api_signature(value="debounce(wait, simulation?) → tick, push") }}

Require `scripts.s3.debounce`. Debouncing waits for changes to stop: every `push(value)` restarts the quiet interval. It is useful when processing the final value matters more than processing every intermediate change.

`wait` must be a number greater than zero. `simulation` must be absent or boolean: absent/false uses real time; true uses simulation time. Invalid arguments raise an assertion.

{% usage_note(title="OpenMW clock · You supply the update handler") %}
This helper reads `openmw.core` time. It does not register a handler or schedule a timer. Elapsed time alone does not deliver anything: your script must call `tick()`.
{% end %}

## Complete player-script example

```lua
local debounce = require 'scripts.s3.debounce'
local tick, push = debounce(0.25, true)

return {
    eventHandlers = {
        MyModValueChanged = function(value)
            push(value)
        end,
    },
    engineHandlers = {
        onUpdate = function()
            local fired, value = tick()
            if fired then print('Settled value: ' .. tostring(value)) end
        end,
    },
}
```

Register this as a player script using the [bootstrap instructions](@/h3lp_yours3lf/docs/getting-started/overview.md). Send your player's `MyModValueChanged` event when the input changes. A burst of events produces one print on a subsequent tick after at least 0.25 simulation seconds without another push.

## Return and lifetime contract

- `push(value)` stores the value and restarts the interval. It does not invoke a callback.
- `tick()` returns `false, nil` while idle or waiting.
- After the quiet interval, `tick()` returns `true, value` once and clears the pending value.
- `nil` is a valid pushed value; test `fired`, not the truthiness of `value`.
- Tables are retained by reference, not copied. Construction creates closures holding the pending state; the helper does not serialize it into save data.

Do not replace the second argument with a function: this API returns two functions rather than accepting a completion callback.

Need a regular interval or an immediately ready rate limit instead? Compare [Every and Cooldown](@/h3lp_yours3lf/docs/api/modules/timing.md).
