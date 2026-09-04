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
  nexus_id: 59122
  nexus_group_id: 7468718
  version: 0.2
---
context-aware diagnostics for `require('openmw.*')` calls.

Add the stubs directory to `workspace.library`, select LuaJIT, and load the
context plugin with `runtime.plugin`:

Cod3x also ships an example config at
`examples/openmw-mod/.luarc.json`. Copy that file into your mod project root
and replace `/absolute/path/to/Cod3x` with the folder where you extracted Cod3x.

<!-- more -->

```json
{
  "workspace.library": ["/path/to/openmw/lua_api_lls"],
  "runtime.version": "LuaJIT",
  "runtime.plugin": "/path/to/openmw/lua_api_lls/omw_context_plugin.lua"
}
```

Do not use the old `plugins` setting; LuaLS expects `runtime.plugin` for this
plugin.

Cod3x relies on LuaLS virtual source transforms for implicit casts and
context-aware diagnostics.  In VSCode/VSCodium, disable LuaLS on-type line
formatting so Enter-key formatting cannot apply transformed offsets to the real
buffer:

```json
{
  "language.fixIndent": false,
  "typeFormat.config": {
    "format_line": "false"
  }
}
```

These are LuaLS settings, not Cod3x-only magic.  The old GitHub wiki is
deprecated in favor of the current LuaLS website; see the current LuaLS docs for
[`language.fixIndent`](https://luals.github.io/wiki/settings/#languagefixindent)
and [`typeFormat.config`](https://luals.github.io/wiki/settings/#typeformatconfig).
LuaLS also defines these keys in its upstream config template as
`Lua.language.fixIndent` and `Lua.typeFormat.config`.

Cod3x validates OpenMW API availability and interface surfaces in the current
file. It cannot reliably validate whether an arbitrary user module's
`---@omw-context` is compatible with every importer: LuaLS may process an
importer before the imported module, and its plugin API has no reliable
post-resolution diagnostic hook. Give shared modules the broadest context they
actually support, or keep context-specific code in separate modules.

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
