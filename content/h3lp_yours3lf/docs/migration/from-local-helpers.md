---
title: From Local Helpers
description: Replace one utility at a time without changing ownership or behavior by accident.
weight: 10
extra:
  kind: guide
---

Migrate one helper at a time. Similar names do not guarantee equivalent behavior: check inputs, outputs, mutation, context, scheduling, and failure behavior first.

## Before: duplicated normalization

```lua
local function normalize(path)
    local result = path:lower():gsub('\\', '/'):gsub('/+', '/')
    return result
end
assert(normalize('Textures\\MyMod//Icon.dds') == 'textures/mymod/icon.dds')
```

## After: require the shared helper

```lua
local normalize = require 'scripts.s3.normalizePath'
assert(normalize('Textures\\MyMod//Icon.dds') == 'textures/mymod/icon.dds')
```

The [normalizePath contract](@/h3lp_yours3lf/docs/api/modules/normalize-path.md) matches these transformations. If your previous function also checked existence or resolved parent directories, this is not a complete replacement.

## Verify the migration

1. Install H3 as an explicit dependency using the [bootstrap](@/h3lp_yours3lf/docs/getting-started/overview.md).
2. Keep the old function's representative inputs as assertions, including edge cases.
3. Verify the return shape. Debounce returns `tick, push`, not a callback wrapper; Signal uses `fire`, not `emit`.
4. Check [context and ownership](@/h3lp_yours3lf/docs/concepts/state-and-context.md). Do not replace an engine event with Signal or persistent state with a pooled table.
5. Exercise initialization and loading an existing save where lifecycle matters.
6. Remove the duplicated implementation only after the replacement behaves as intended. State the H3 version you tested in your mod's dependency requirements.
