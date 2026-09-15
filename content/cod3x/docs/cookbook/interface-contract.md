---
title: Publish a Small Interface
summary: Export one stable contract instead of your whole module.
description: A minimal OpenMW interface shape with private implementation state.
weight: 15
extra:
  kind: example
---

Keep implementation state private and export only the operations consumers need.

```lua
---@omw-context player

local enabled = true

local function isEnabled()
  return enabled
end

local function setEnabled(value)
  assert(type(value) == 'boolean', 'value must be boolean')
  enabled = value
end

return {
  interfaceName = 'ExampleFeature',
  interface = {
    isEnabled = isEnabled,
    setEnabled = setEnabled,
  },
}
```

For a shared/public mod API, add LuaLS metadata for the interface and document version/ownership expectations.

See [API and Interface Design](@/cod3x/docs/practice/api-design.md) and [Built-In Interfaces](@/cod3x/docs/reference/interfaces.md).
