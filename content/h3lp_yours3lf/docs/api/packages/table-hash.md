---
title: tableHash
description: Derive a compact content hash for simple, acyclic Lua tables.
weight: 73
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.tableHash'(table) → string") }}

Use `tableHash` when a table's current contents need a stable-looking identifier for cache keys, change detection, or generated names. It hashes recursively and does not mutate the input.

```lua
local tableHash = require 'scripts.s3.tableHash'

local key = tableHash(actionData)
```

Keys are sorted by Lua type and then `tostring` before the table is serialized into a simple representation. Numbers use a fixed numeric format. Userdata must expose `value.__type.name`; otherwise the function raises.

This helper allocates temporary key, content, and representation tables while hashing. It is not cryptographic, collision-free, or cycle-safe: recursive tables will recurse indefinitely, and equal hashes do not prove equal tables. Values whose `tostring` output is not stable should not be used as a deterministic key.
