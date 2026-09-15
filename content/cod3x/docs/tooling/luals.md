---
title: Cod3x and LuaLS
description: Context-aware annotations turn engine contracts into editor feedback.
weight: 10
extra:
  kind: guide
---

Cod3x's original job remains important: give Lua Language Server a useful model of OpenMW.

## Workspace setup

Add the Cod3x directory to `workspace.library`, select LuaJIT for current OpenMW Lua, and load the context plugin:

```json
{
  "workspace.library": ["/absolute/path/to/Cod3x"],
  "runtime.version": "LuaJIT",
  "runtime.plugin": "/absolute/path/to/Cod3x/omw_context_plugin.lua"
}
```

The repository also ships `examples/openmw-mod/.luarc.json`.

## Context annotations

Every OpenMW-facing source file should declare its context:

```lua
---@omw-context player
```

Shared modules should declare the broadest context they genuinely support, not the broadest annotation that happens to silence diagnostics.

Cod3x understands:

- `global`;
- `local`;
- `player`;
- `menu`;
- `load`;
- `runtime`;
- `all`;
- `none`.

See [Script Contexts](@/cod3x/docs/getting-started/contexts.md).

## Scoped assertions

Use `omw-context-next` or begin/end blocks when a runtime branch genuinely narrows the environment.

```lua
---@omw-context global | player

local core = require 'openmw.core'

---@omw-context-begin player
local camera = require 'openmw.camera'
---@omw-context-end
```

These are assertions. The plugin does not prove your runtime guard.

## Type your own interfaces

A workspace metadata file can teach LuaLS the contract of your own interface without OpenMW loading that file:

```lua
---@meta

---@class openmw.interfaces
---@field MyMod? openmw.interfaces.MyMod

---@class openmw.interfaces.MyMod
---@field version string
---@field resolve fun(recordId: string): boolean
```

Public interfaces deserve types because types force the contract to become explicit.

## The annotations are not infallible

Cod3x history contains many fixes for:

- optional fields;
- context availability;
- changed record-key types;
- enum specificity;
- missing fields;
- engine data that violated a happy-path assumption.

If runtime behavior and annotations disagree, investigate the engine/source. Fix the annotation rather than programming around a lie from the tool.

## Virtual transforms are tooling, not source edits

The context plugin can transform text virtually so LuaLS emits useful diagnostics. Editor formatting must not write those transformed offsets back into the source document.

The provided configuration disables the problematic on-type formatting path while preserving context transforms.
