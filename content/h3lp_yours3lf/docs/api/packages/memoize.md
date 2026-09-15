---
title: memoize
description: Cache function results with explicit key, expiry, and retention controls.
weight: 35
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.memoize' → memoize; memoize(fn, keyFn?, options?) → callable") }}

Use memoize when you keep asking the same expensive question and the answer is still valid. It remembers the result by key so later calls do not repeat the work.

{% usage_note(title="Plain Lua cache · Measure retention") %}
The module has no OpenMW clock or automatic scheduler. TTLs advance only when your code calls `cached:tick(dt)`, and a cache without expiry, an entry limit, or invalidation grows without bound.
{% end %}

## Basic usage

```lua
local memoize = require 'scripts.s3.memoize'
local vfs = require 'openmw.vfs'

local resolveIcon = memoize(function(path)
    if vfs.fileExists(path) then return path end
end)

local function rebuildList(records)
    for _, record in ipairs(records) do
        local iconPath = resolveIcon(record.iconPath)
        print(record.id, iconPath or 'no icon')
    end
end

return {
    eventHandlers = {
        MyModRebuildList = rebuildList,
    },
}
```

Every rebuild can ask for the same icon path; only the first lookup reaches the VFS. Without `keyFn`, only the first argument is the key. If later arguments affect the result, provide a key function:

```lua
local lookup = memoize(loadVariant, function(recordId, quality)
    return recordId .. ':' .. quality
end)
```

The key may be any Lua table key. `nil` keys, no-argument calls, and a `nil` result are supported through internal sentinels.

## Options and members

```lua
local cached = memoize(expensive, nil, {
    ttl = 5,
    refresh_on_hit = true,
    max_entries = 128,
})
```

| Option/member | Behavior |
| --- | --- |
| `ttl` | Positive age in caller-supplied seconds. Entries expire when `tick` advances them to this value. |
| `refresh_on_hit` | When true, a hit resets that entry's age; otherwise age begins at insertion. |
| `max_entries` | Positive integer limit on live entries. The oldest insertion is evicted on overflow. |
| `cached:tick(dt)` | Ages entries and evicts expired ones. Negative `dt` is accepted but moves ages backward. |
| `cached:invalidate(...)` | Removes the key derived from the same arguments used by the cache. |
| `cached:invalidate_all()` | Removes all entries without resetting hit/miss counters. |
| `cached:stats()` | Returns a newly allocated `{ hits, misses, size }` table. |

Entry limiting is FIFO by insertion age, not LRU. Cache hits do not change eviction order, even when they refresh TTL age.

## Return and ownership contract

Cache misses call the wrapped function and propagate its errors without storing a result. Multiple return values, zero returns, and `nil` values in any return position are preserved. The first argument is not copied; table and userdata keys use their normal identity semantics.

Returned tables and userdata are cached by reference, not copied. Mutating one changes what later hits receive. The callable retains keys and results until invalidation or eviction, so use bounded retention for player-driven or hot paths.

For the reasoning behind cache lifetime, invalidation, retention, and performance measurement, see Cod3x's [Caching Without Creating New Bugs](@/cod3x/docs/performance/caching.md).

Cache hits unpack through an internal reusable scratch array. Do not retain that implementation table; retain the returned values themselves if their types permit it. `stats()` and misses allocate; stable hits avoid result-table allocation.
