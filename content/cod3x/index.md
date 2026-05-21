---
title: Cod3x
description: Expanded and improved LLS annotations for OpenMW-Lua scripters.
date: 2026-05-21

taxonomies:
  tags:
    - OpenMW-Lua
    - Tools
    - Documentation

extra:
  version: 0.1
---
context-aware diagnostics for `require('openmw.*')` calls.

Add the stubs directory to `workspace.library`, select Lua 5.1, and load the
context plugin with `runtime.plugin`:
<!-- more -->

```json
{
  "workspace.library": ["/path/to/openmw/lua_api_lls"],
  "runtime.version": "Lua 5.1",
  "runtime.plugin": "/path/to/openmw/lua_api_lls/omw_context_plugin.lua"
}
```

Do not use the old `plugins` setting; LuaLS expects `runtime.plugin` for this
plugin.

Declare the OpenMW script context near the top of each script:

```lua
---@omw-context global
```

Valid contexts are `global`, `local`, `player`, `menu`, and `load`.

Player script example:

```lua
---@omw-context player
local camera = require('openmw.camera')
local input = require('openmw.input')

if input.isActionPressed(input.ACTION.Use) then
    camera.setMode(camera.MODE.FirstPerson)
end
```

Global script example:

```lua
---@omw-context global
local world = require('openmw.world')

local function onUpdate()
    for _, actor in ipairs(world.activeActors) do
        -- Global world logic.
    end
end

return { engineHandlers = { onUpdate = onUpdate } }
```

Load script example:

```lua
---@omw-context load
local content = require('openmw.content')

content.gameSettings.records.fJumpAcrobaticsBase = 1024
content.globals.records.MyVariable = 42
```

To type your mod interfaces, augment `openmw.interfaces` in a project-local stub
file and keep that file in your workspace:

```lua
---@meta

---@class openmw.interfaces
---@field MyMod? openmw.interfaces.MyMod

---@class openmw.interfaces.MyMod
---@field version string
---@field doThing fun(target: unknown)
```

{{ credits(default=true) }}
