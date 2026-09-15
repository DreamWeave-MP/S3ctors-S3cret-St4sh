---
title: Probing Context by Failure
description: A historical compatibility trick that should not become ordinary module architecture.
weight: 30
extra:
  kind: guide
---

Starwind Builder contained this basic strategy:

```lua
local isNotMenu, types = pcall(require, 'openmw.types')
local isGlobal = pcall(require, 'openmw.world')
local isMenu = pcall(require, 'openmw.menu')
```

Then the module inferred global/menu/local/player from whichever requires succeeded.

## Why it seemed clever

OpenMW exposes different modules in different contexts.

A shared helper could therefore ask the runtime which environment it had by trying context-specific modules.

It avoided duplicating helpers across scripts and worked before the tooling knew enough to express context statically.

## Why it ages badly

The approach:

- turns a static architecture property into runtime error probing;
- requires protected calls during module load;
- makes dependencies conditional and implicit;
- prevents tooling from understanding the intended surface as clearly;
- encourages one module to accumulate branches for every context.

Cod3x now has explicit `---@omw-context` annotations and scoped assertions. Use them.

## When probing can still be legitimate

A helper whose explicit purpose is “tell me what context I am running in” may have no better runtime primitive and can reasonably probe availability.

Likewise, a library designed to run in OpenMW *and* non-OpenMW Lua may probe for `openmw.core` as a capability check.

Those are probing utilities.

They are not evidence that normal feature modules should discover their architecture by throwing errors.

## Better shape

Prefer separate context entry points:

```text
scripts/myMod/global.lua
scripts/myMod/player.lua
scripts/myMod/local.lua
scripts/myMod/shared.lua
```

Shared code can declare the broadest context it genuinely supports. Context-specific entry points can adapt the shared logic to the engine surface they own.
