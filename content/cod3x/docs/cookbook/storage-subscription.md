---
title: Subscribe to Storage Without Hiding the State Flow
summary: Read once, subscribe once, and keep the cache contract obvious.
description: A small storage subscription pattern with explicit cached state.
weight: 25
extra:
  kind: example
---

A read-only storage section can be observed in contexts where mutation is not allowed.

```lua
---@omw-context player

local async = require 'openmw.async'
local storage = require 'openmw.storage'

local settings = storage.globalSection('ExampleSettings')
local enabled = settings:get('enabled') == true

settings:subscribe(async:callback(function(section, key)
  if key ~= 'enabled' then return end

  enabled = section:get('enabled') == true
end))
```

The important part is not the syntax. The important part is that `enabled` has an obvious source and invalidation path.

Do not wrap storage access behind a magic table unless the abstraction preserves these semantics clearly.

See [Storage, Save State, and Lifecycle](@/cod3x/docs/getting-started/storage-and-lifecycle.md) and [A Shadow Cache Needs the Same Invalidation as Its Source](@/cod3x/docs/paid-for-with-blood/shadow-cache-invalidation.md).
