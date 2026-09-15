---
title: Keep Some State
description: Choose ordinary locals, storage, or save data based on lifetime and ownership.
weight: 100
extra:
  kind: guide
---

State is simply information your script remembers. The important question is how long it should remember it and who owns it.

## Ordinary locals are runtime state

This counter lives in the running script instance:

```lua
local count = 0

local function increment()
    count = count + 1
end
```

It is cheap and private. It is also gone when the script is reloaded or recreated. That is correct for a temporary cache, an open UI element, or a current operation.

## Save data survives a save/load cycle

Engine handlers can return and receive a serializable table:

```lua
local count = 0

return {
    engineHandlers = {
        onSave = function()
            return { version = 1, count = count }
        end,

        onLoad = function(data)
            count = data and data.count or 0
        end,
    },
}
```

Save only the facts needed to reconstruct the runtime state. Do not put UI elements, closures, live engine handles, or iterators in save data.

## Storage is for named persistent/shared sections

OpenMW storage sections are useful for settings and state owned by a scope:

```lua
---@omw-context player

local storage = require 'openmw.storage'
local settings = storage.playerSection 'MyFirstModSettings'

local enabled = settings:get('Enabled')
```

Use a global section for global ownership and a player section for player ownership. Do not use storage as a message bus or as a place to hide transient runtime objects.

## The three-question test

Before storing a value, ask:

1. Who owns it: the world, a player, one object, or this operation?
2. Should it survive reload and save/load?
3. Can it be rebuilt from smaller authoritative facts?

The answers choose the storage mechanism. [Storage, Save State, and Lifecycle](@/cod3x/docs/getting-started/storage-and-lifecycle.md) covers migrations, invalidation, and the cases where these choices become painful.

Next, make state visible in [Put Something on the Screen](@/cod3x/docs/zero-to-hero/put-something-on-screen.md).
