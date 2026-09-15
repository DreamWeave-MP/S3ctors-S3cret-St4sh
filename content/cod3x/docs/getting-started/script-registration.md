---
title: Script Registration and Entry Points
description: Put context in the registration and architecture before the first require.
weight: 15
extra:
  kind: guide
---

An OpenMW-Lua feature begins before its Lua code executes: the script registration decides where that entry point lives.

Common `.omwscripts` registrations in the DreamWeave corpus include:

```text
GLOBAL: scripts/myMod/global.lua
PLAYER: scripts/myMod/player.lua
MENU: scripts/myMod/menu.lua
CUSTOM: scripts/myMod/local.lua
```

Type-specific local registrations such as `CREATURE:` are also used when the feature belongs on a narrower object category.

The exact registration surface evolves with OpenMW. The architectural rule does not:

**register behavior where its authority and data naturally live.**

## Match the source annotation

A global entry point should say so:

```lua
---@omw-context global
```

A player entry point should declare `player`, and so on.

The `.omwscripts` file is an engine registration. The Cod3x annotation is a tooling contract. Keep them conceptually aligned.

## `CUSTOM` is not “generic global script”

A custom local script is intended to be attached to an object. It runs with local-object semantics when attached.

Do not use a custom registration merely to get a reusable file into the VFS. Plain Lua modules can be required by registered scripts without being registered as engine entry points.

## Separate entry points from libraries

A useful layout is:

```text
scripts/myMod/global.lua
scripts/myMod/player.lua
scripts/myMod/local.lua
scripts/myMod/core.lua
scripts/myMod/rules.lua
```

Only the engine entry points need `.omwscripts` registration. The shared modules should declare whatever Cod3x context they actually support.

This keeps engine handlers small and makes the reusable logic testable/readable without pretending every module is independently scheduled by OpenMW.

## Handler tables are contracts

A registered script returns the handlers/interfaces it exposes to OpenMW. Keep that return surface explicit and boring.

Do not dynamically invent handler names from configuration unless the engine contract and diagnostics remain clear.

When a handler is hot, keep the entry point thin and move the measured work into a module whose state/lifetime is easier to reason about.
