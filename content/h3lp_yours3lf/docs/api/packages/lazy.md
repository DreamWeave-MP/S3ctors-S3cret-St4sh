---
title: lazy
description: Compute one value on demand and reuse it until explicitly reset.
weight: 37
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.lazy' → lazy; lazy(factory) → callable") }}

Use lazy for something expensive you may never need. The first call builds it; later calls reuse the same value until you reset it.

{% usage_note(title="Plain Lua closure · One value only") %}
The module has no OpenMW imports or persistence behavior. It creates a callable object and retains the factory result and its references until reset or garbage collection.
{% end %}

```lua
local lazy = require 'scripts.s3.lazy'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local getStatusText = lazy(function()
    return ui.create {
        type = ui.TYPE.Text,
        layer = 'HUD',
        props = { text = '', relativeSize = util.vector2(0.4, 0.05) },
    }
end)

local function showStatus(message)
    local statusText = getStatusText()
    statusText.layout.props.text = message
    statusText:update()
end

return {
    eventHandlers = {
        MyModStatusChanged = function(message) showStatus(message) end,
    },
}
```

| Member | Behavior |
| --- | --- |
| `getValue()` | Runs the factory once if needed and returns its first value. Factory errors propagate and do not mark the value computed. |
| `getValue:computed()` | Returns true after a successful computation, even if the result is `nil`. |
| `getValue:peek()` | Returns the cached value without computing; `nil` is ambiguous. |
| `getValue:reset()` | Clears the cached value so the next call computes again. |

The factory is called with no arguments. Extra factory return values are discarded because the callable represents one value. If the element is destroyed, call `getStatusText:reset()` before building it again. Recursive factory evaluation and resetting during evaluation raise errors.

Use `lazy` when construction should happen at most once on demand. For a result that must be refreshed by keys or expiry, use [memoize](@/h3lp_yours3lf/docs/api/packages/memoize.md) instead; for explicit success/failure, use [Result](@/h3lp_yours3lf/docs/api/packages/result.md).
