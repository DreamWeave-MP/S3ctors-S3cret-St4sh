---
title: Cod3x
description: OpenMW Lua tooling, context-aware annotations, and the OpenMW-Lua engineering field manual.
date: 2026-05-21

taxonomies:
  tags:
    - OpenMW-Lua
    - Tools
    - Documentation

extra:
  nexus_id: 59122
  nexus_group_id: 7468718
  version: "0.4"
---

# Cod3x

Cod3x is the OpenMW-Lua development companion: Lua Language Server annotations, context-aware diagnostics, and an engineering field manual built from years of production OpenMW Lua, profiler work, repository history, and runtime archaeology.

{{ image(src="/img/cod3x/icon.png", alt="Cod3x: Code, Context, Consequence.", style="border-radius: 8px;") }}

The annotations answer **what exists**.

The [Cod3x Field Manual](@/cod3x/docs/_index.md) answers **how to engineer with it, why the rules exist, where the engine costs live, and which mistakes have already been Paid For With Blood**.

<!-- more -->

## Field Manual

Start with [Why Cod3x Exists](@/cod3x/docs/mission.md), then use the manual by problem:

- [Zero to Hero: build your first OpenMW Lua mod](@/cod3x/docs/zero-to-hero/_index.md)
- [OpenMW Lua mental model](@/cod3x/docs/getting-started/mental-model.md)
- [script contexts](@/cod3x/docs/getting-started/contexts.md)
- [objects, records, types, and cells](@/cod3x/docs/getting-started/objects-records-types.md)
- [error handling](@/cod3x/docs/practice/error-handling.md)
- [Good Designs](@/cod3x/docs/good-designs/_index.md)
- [performance](@/cod3x/docs/performance/_index.md)
- [Pr0f1l3r](@/cod3x/docs/performance/pr0f1l3r.md)
- [LuaJIT bytecode and traces](@/cod3x/docs/performance/luajit-bytecode.md)
- [Paid For With Blood](@/cod3x/docs/paid-for-with-blood/_index.md)
- [So You Want To Code With AI?](@/cod3x/docs/tooling/so-you-want-to-code-with-ai.md)

Cod3x is also the map legend for the rest of the site. Follow a rule into an [H3 pattern library](@/h3lp_yours3lf/docs/_index.md), a [S3maphore production system](@/s3maphore/docs/_index.md), or the [historical evidence index](@/cod3x/docs/reference/history-index.md).

## LuaLS setup

Add the Cod3x folder to `workspace.library`, select LuaJIT, and load the Cod3x context plugin with `runtime.plugin`:

```json
{
  "workspace.library": ["/absolute/path/to/Cod3x"],
  "runtime.version": "LuaJIT",
  "runtime.plugin": "/absolute/path/to/Cod3x/omw_context_plugin.lua"
}
```

Cod3x ships an example config at `examples/openmw-mod/.luarc.json`.

## Declare script context

Add a context annotation near the top of every OpenMW-facing script:

```lua
---@omw-context player
```

Available contexts are `global`, `local`, `player`, `menu`, and `load`, plus Cod3x's shared-code sets `runtime`, `all`, and `none`.

For shared code, combine contexts with `|`:

```lua
---@omw-context global | player
```

Use scoped context assertions when only a narrow block has a stronger runtime guarantee:

```lua
---@omw-context global | player
local core = require 'openmw.core'

---@omw-context-next player
local camera = require 'openmw.camera'
```

See [Script Contexts](@/cod3x/docs/getting-started/contexts.md) for the model and exact semantics.

## Type your own interfaces

Keep interface metadata in your workspace; OpenMW does not load it:

```lua
---@meta

---@class openmw.interfaces
---@field MyMod? openmw.interfaces.MyMod

---@class openmw.interfaces.MyMod
---@field version string
---@field doThing fun(target: unknown): boolean
```

## Editor formatting

Cod3x's context plugin uses virtual LuaLS transforms. They improve context-aware diagnostics but must not become the source text for on-type formatting edits.

If VS Code/VSCodium inserts or indents text incorrectly, disable LuaLS on-type formatting for the workspace. The example `.luarc.json` carries the recommended settings.

{{ credits(default=true) }}
