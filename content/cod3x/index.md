---
title: Cod3x
description: Lua Language Server support for OpenMW Lua modding.
date: 2026-05-21

taxonomies:
  tags:
    - OpenMW-Lua
    - Tools
    - Documentation

extra:
  nexus_id: 59122
  nexus_group_id: 7468718
  version: 0.4
---

# Cod3x

Cod3x gives the Lua Language Server (LuaLS) better type information for
OpenMW Lua scripts. It provides completions and warnings for OpenMW modules,
interfaces, and script contexts.

## Setup

Add the Cod3x folder to `workspace.library`, select LuaJIT, and load the
Cod3x context plugin with `runtime.plugin`:

Cod3x also ships an example config at
`examples/openmw-mod/.luarc.json`. Copy it into your mod project and replace
`/absolute/path/to/Cod3x` with the folder where you extracted Cod3x.

<!-- more -->

```json
{
  "workspace.library": ["/absolute/path/to/Cod3x"],
  "runtime.version": "LuaJIT",
  "runtime.plugin": "/absolute/path/to/Cod3x/omw_context_plugin.lua"
}
```

## Add a script context

Add a context annotation near the top of each OpenMW script. This tells LuaLS
which OpenMW APIs are available to that script.

```lua
---@omw-context player
```

Available contexts:

- `global` — one script for the game world
- `local` — a script attached to an object or actor
- `player` — a player-specific script
- `menu` — a menu script
- `load` — a content-loading script

Cod3x also provides abstract contexts for shared code:

- `runtime` — code that can run in global, local, player, or menu scripts
- `all` — code that can run in every OpenMW script context, including `load`
- `none` — a file that intentionally uses no OpenMW APIs

For example, a utility shared by runtime scripts can use:

```lua
---@omw-context runtime
local core = require('openmw.core')
```

For shared code, combine contexts with `|`:

```lua
---@omw-context global | player
```

## Scoped contexts

Use `omw-context-next` for one line or `omw-context-begin` and
`omw-context-end` for a block:

```lua
---@omw-context global | player
local core = require('openmw.core')

---@omw-context-next player
local camera = require('openmw.camera')

---@omw-context-begin player
local input = require('openmw.input')
local ui = require('openmw.ui')
---@omw-context-end
```

Scoped contexts temporarily override the file's default context. They are
assertions for LuaLS; make sure the code really only runs in that context.

## Examples

Player script:

```lua
---@omw-context player
local camera = require('openmw.camera')
local input = require('openmw.input')

if input.isActionPressed(input.ACTION.Use) then
    camera.setMode(camera.MODE.FirstPerson)
end
```

Global script:

```lua
---@omw-context global
local world = require('openmw.world')

local function onUpdate()
    for _, actor in ipairs(world.activeActors) do
        print(actor.recordId)
    end
end

return { engineHandlers = { onUpdate = onUpdate } }
```

Load script:

```lua
---@omw-context load
local content = require('openmw.content')

content.gameSettings.records.fJumpAcrobaticsBase = 1024
```

## VS Code and VSCodium

If pressing Enter causes incorrect indentation, disable LuaLS on-type
formatting for the workspace:

```json
{
  "language.fixIndent": false,
  "typeFormat.config": {
    "format_line": "false"
  }
}
```

## Type your own interfaces

To get completions and type checking for your own interfaces, add a LuaLS
metadata file to your project. Keep it in your workspace; OpenMW does not load
this file.

```lua
---@meta

---@class openmw.interfaces
---@field MyMod? openmw.interfaces.MyMod

---@class openmw.interfaces.MyMod
---@field version string
---@field doThing fun(target: unknown): boolean
```

Cod3x checks OpenMW APIs used directly in each file. It cannot check whether
context annotations on your own modules agree with every module that imports
them, so give shared modules the broadest context they actually support.

{{ credits(default=true) }}
