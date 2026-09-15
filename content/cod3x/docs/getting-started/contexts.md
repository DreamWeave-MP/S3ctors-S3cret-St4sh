---
title: Script Contexts
description: Treat context as an architectural contract, not something to discover by crashing requires.
weight: 20
extra:
  kind: guide
---

Every OpenMW script has a context. Treat that as part of the module's contract.

Cod3x understands these concrete contexts:

| Context | Mental model | Characteristic APIs |
| --- | --- | --- |
| `global` | world authority | `openmw.world`, global object mutation |
| `local` | one attached object | `openmw.self`, `openmw.nearby`, actor-local interfaces |
| `player` | player local script plus player capabilities | `openmw.camera`, `openmw.debug`, postprocessing, player UI/input |
| `menu` | main-menu environment | `openmw.menu`, UI/input without world object APIs |
| `load` | content loading | `openmw.content` |

Cod3x also defines annotation-only sets:

- `runtime` = global, local, player, and menu;
- `all` = every concrete context, including load;
- `none` = intentionally OpenMW-API-agnostic Lua.

A combined annotation uses intersection semantics. If a file says:

```lua
---@omw-context global | player
```

then APIs used unconditionally in that file must be valid in **both** contexts.

## Declare context, do not infer it accidentally

A normal OpenMW module should make its intended environment obvious:

```lua
---@omw-context player

local camera = require 'openmw.camera'
local input = require 'openmw.input'
```

If a shared module is truly portable:

```lua
---@omw-context runtime

local core = require 'openmw.core'
```

If only a narrow block is guaranteed to execute in one context, Cod3x supports scoped assertions:

```lua
---@omw-context global | player

local core = require 'openmw.core'

---@omw-context-begin player
local camera = require 'openmw.camera'
local input = require 'openmw.input'
---@omw-context-end
```

The annotation is an assertion. The plugin cannot prove that your runtime branch actually matches it.

## Availability is not always module-wide

Some modules exist in many contexts while particular members are narrower.

`openmw.core` is broadly available, but world-time, weather, sound, global events, and other runtime members are not meaningful in the load context. `openmw.storage` similarly exposes sections with different context availability.

Cod3x's context plugin checks both module availability and selected member-level restrictions.

Do not assume that successfully requiring a broad module makes every field legal.

## Historical anti-pattern: probing with `pcall`

Starwind Builder contained an early helper that determined context by attempting context-specific requires inside protected calls:

```lua
local isNotMenu, types = pcall(require, 'openmw.types')
local isGlobal = pcall(require, 'openmw.world')
local isMenu = pcall(require, 'openmw.menu')
```

It worked because an unavailable module failed and the failure became data.

It also turned context into a runtime discovery problem, spent protected calls during module initialization, hid intent from tooling, and encouraged one shared module to know more environments than it usually needed.

For ordinary code, this is now the wrong direction.

Prefer:

- context-specific entry points;
- shared modules with explicit broad annotations;
- interfaces or events where contexts must communicate;
- scoped annotations when a runtime branch genuinely narrows the environment.

H3 still contains context-introspection helpers for compatibility and utilities whose **contract is explicitly to identify the environment**. That is an exceptional boundary, not a general model for application architecture.

See [Probing Context by Failure](@/cod3x/docs/anti-patterns/context-probing.md).

## Player is special, not merely “local plus a name”

A player script is attached locally, but it has additional player-facing APIs and interface availability.

Do not infer player-ness from record IDs, object names, or nearby lists when the script registration can express that ownership directly.

Likewise, do not write generic local code that secretly requires player-only modules unless the type and registration guarantee that context.

## Menu is not a weak player context

A useful historical correction from Cod3x itself is [commit `8f3e075d`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/8f3e075d98c1fbd31a7a2eecce09cbece7686ff1): the annotations initially claimed `openmw.types` was available in menu scripts. It is not.

H3 Pattern: [ScriptContext](@/h3lp_yours3lf/docs/api/packages/script-context.md) is for a genuinely shared module that must choose a context-specific implementation. It is introspection, not context switching or permission escalation. For architecture, prefer separate modules with explicit [context annotations](@/cod3x/docs/getting-started/contexts.md).

The mistake is instructive. APIs that feel foundational in runtime scripts may simply not exist in menu or load environments.

**Contract:** use the actual context surface, not intuition about what “should” be available.

## Load is deliberately different

Load scripts work while content is being loaded, not while the normal game world is running.

They use `openmw.content` and broadly safe utility facilities. They should not be treated as runtime scripts with a different callback.

If code has meaningful runtime dependencies, do not annotate it `all` just to make reuse easier. Split the pure part from the engine-facing part.

## Context should shape module boundaries

A useful module split often looks like:

```text
scripts/myFeature/shared.lua      none/runtime-safe calculations
scripts/myFeature/global.lua      world authority
scripts/myFeature/player.lua      input/UI/player state
scripts/myFeature/actor.lua       local actor observation
```

That layout is not mandatory. The principle is.

When context-specific behavior is mixed into one giant file, you usually acquire runtime probing, conditional requires, hidden assumptions, and harder tests.

Make the boundary visible.
