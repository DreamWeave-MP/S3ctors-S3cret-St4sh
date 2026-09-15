---
title: Set Up Cod3x
description: Configure LuaLS with OpenMW's API knowledge and prove that context diagnostics are active.
weight: 60
extra:
  kind: guide
---

Cod3x is a folder of LuaLS annotations and a context plugin. It is editor tooling, not an OpenMW runtime dependency.

## Put the configuration in the workspace

Create a `.luarc.json` in the root of the mod or workspace containing your OpenMW Lua files:

```json
{
    "runtime.version": "LuaJIT",
    "workspace.library": [
        "/absolute/path/to/Cod3x"
    ],
    "runtime.plugin": "/absolute/path/to/Cod3x/omw_context_plugin.lua",
    "language.fixIndent": false,
    "typeFormat.config": {
        "format_line": "false",
        "auto_complete_end": "false",
        "auto_complete_table_sep": "false"
    }
}
```

Replace both absolute paths with the paths on your machine. The workspace configuration travels with the project; each developer may need different local paths.

Cod3x ships the same shape in [`examples/openmw-mod/.luarc.json`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/cod3x/examples/openmw-mod/.luarc.json). LuaLS documents `.luarc.json` as a portable workspace configuration mechanism; see the [LuaLS configuration documentation](https://luals.github.io/wiki/configuration/).

## Prove the setup

Create a temporary Lua file with this content:

```lua
---@omw-context menu

local types = require 'openmw.types'
```

`openmw.types` is not available in menu scripts. If Cod3x is working, LuaLS should report a context diagnostic on the `require`.

Then change the annotation to `player` and confirm that the context diagnostic goes away:

```lua
---@omw-context player

local types = require 'openmw.types'
```

Delete the test file or keep it as a tiny tooling check. A deliberate error is a better installation test than “the extension appears in the editor.”

## Common setup mistakes

- Adding the Cod3x folder as a data directory instead of a LuaLS library.
- Pointing at a parent directory that does not contain the `openmw` stubs.
- Forgetting the `omw_context_plugin.lua` path.
- Opening a subfolder as the editor workspace so `.luarc.json` is outside the workspace root.
- Treating a runtime failure as proof that the language server is wrong.

Read [Cod3x and LuaLS](@/cod3x/docs/tooling/luals.md) for the full tooling contract. Next, learn why the same `require` can be legal in one script and illegal in another in [Scripts Have Contexts](@/cod3x/docs/zero-to-hero/contexts-in-practice.md).
