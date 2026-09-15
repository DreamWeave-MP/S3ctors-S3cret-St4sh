---
title: Find an Object, Then Its Record
description: Separate runtime instance lookup from content-record lookup.
weight: 10
extra:
  kind: example
---

## Global: find instances by record ID

```lua
---@omw-context global

local world = require 'openmw.world'

local objects = world.getObjectsByRecordId('iron dagger')

for index = 1, #objects do
  local object = objects[index]
  print(object.id, object.recordId)
end
```

## Known object: inspect a type-specific record

```lua
---@omw-context player

local nearby = require 'openmw.nearby'
local types = require 'openmw.types'

for index = 1, #nearby.items do
  local object = nearby.items[index]

  if types.Weapon.objectIsInstance(object) then
    local record = types.Weapon.record(object)
    if record then print(record.id, record.name) end
  end
end
```

Use the object ID for instance state and the record ID/record for content definition.

See [Objects, Records, Types, and Cells](@/cod3x/docs/getting-started/objects-records-types.md).
