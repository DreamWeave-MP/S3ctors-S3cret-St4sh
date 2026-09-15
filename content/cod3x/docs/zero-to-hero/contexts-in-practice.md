---
title: Scripts Have Contexts
description: Learn global, local, player, menu, and load scripts through the capabilities they own.
weight: 70
extra:
  kind: guide
---

OpenMW does not give every script the same toolbox. A script's context says where it runs and what authority it has.

| Registration | Context | Owns |
| --- | --- | --- |
| `GLOBAL:` | `global` | World-level systems and global object authority. |
| `CUSTOM:` | `local` | One attached in-world object. |
| `PLAYER:` | `player` | The player, player input, camera, and player UI. |
| `MENU:` | `menu` | Menu UI and menu input, without the normal world object surface. |
| `LOAD:` | `load` | Content-loading work. |

`CUSTOM` is the registration tag for a local script. It does not mean “put a generic Lua library here.” A normal library is required by an entry point; it does not need its own engine registration.

## Why the context changes the code

These imports express different ownership:

```lua
---@omw-context global
local world = require 'openmw.world'
```

```lua
---@omw-context player
local camera = require 'openmw.camera'
local input = require 'openmw.input'
```

```lua
---@omw-context local
local self = require 'openmw.self'
```

```lua
---@omw-context menu
local menu = require 'openmw.menu'
```

The annotation is a promise to the editor and to the next person reading the file. It does not grant permission at runtime.

## The “why can't I call that?” rule

When a module is unavailable, do not immediately wrap the `require` in `pcall` and discover the context by crashing gently. Ask which script should own the behavior instead.

- World authority belongs in a global script.
- Input and player UI belong in a player script.
- An object's local behavior belongs in a custom local script.
- Menu behavior belongs in a menu script.
- Pure calculations belong in a context-agnostic module.

If two contexts need to cooperate, design the boundary between them. Continue to [Make Two Scripts Talk](@/cod3x/docs/zero-to-hero/scripts-talk.md).

For the complete model, read [Script Contexts](@/cod3x/docs/getting-started/contexts.md).
