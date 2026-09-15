---
title: What Is OpenMW Lua?
description: How ordinary Lua changes when it runs inside OpenMW's sandbox and scheduler.
weight: 30
extra:
  kind: guide
---

OpenMW Lua is Lua running inside the OpenMW engine. Your script is not a standalone program that owns the game. It is a small participant in a host that owns the world, scheduler, input, UI, records, objects, and saves.

## The host gives you a shaped toolbox

OpenMW exposes engine modules through `require`:

```lua
local core = require 'openmw.core'

print(core.getGameTime())
```

The module exists because OpenMW provided it. Lua itself has no `openmw.core`.

The host also limits what a script can do. A script does not get unrestricted access to the operating system merely because Lua has libraries named `io` or `os`. OpenMW's sandbox and script context determine what is available.

That is the first important translation:

| Ordinary Lua idea | OpenMW reality |
| --- | --- |
| `require` loads a module | `require 'openmw.core'` exposes an engine-owned API. |
| A table holds values | Some values are engine-backed userdata that only look table-like. |
| A function runs when called | A handler may run later when OpenMW invokes it. |
| A variable lives until the program exits | A script instance can reload, unload, or cross a save boundary. |

## OpenMW calls your code

A registered script returns a table describing handlers:

```lua
return {
    engineHandlers = {
        onUpdate = function()
            print('OpenMW called me.')
        end,
    },
}
```

The return table is not just data for your own code. It is part of the contract between your script and the engine. OpenMW decides when the handler runs and what arguments it receives.

## The sandbox is a feature

The sandbox keeps scripts from assuming they can inspect or modify everything. A player script, a global script, and a menu script do not have the same authority. That stops an innocent-looking helper from quietly becoming world-wide mutation machinery.

The exact capabilities are described by [Script Contexts](@/cod3x/docs/getting-started/contexts.md). The broader mental model is in [The OpenMW Lua Mental Model](@/cod3x/docs/getting-started/mental-model.md).

## The practical rule

When a snippet behaves differently in OpenMW than it would in a small Lua interpreter, ask two questions:

1. Is this an ordinary Lua rule?
2. Is this an OpenMW host rule about context, lifetime, userdata, or scheduling?

That split prevents a lot of bad debugging. The language may be fine; your script may simply be asking the host for a capability it does not grant.

Next, make something visible in [Your First OpenMW Lua Mod](@/cod3x/docs/zero-to-hero/first-openmw-mod.md).
