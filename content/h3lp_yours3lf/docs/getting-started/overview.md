---
title: Your First H3 Integration
description: Install H3, run a complete player script, and choose your next helper.
weight: 10
extra:
  kind: guide
---

H3 saves you from maintaining the same small utilities in every mod. You can adopt one helper without adopting a framework. Start with a plain module; installed interfaces come later.

## Install the dependency

Follow the [H3 installation instructions](@/h3lp_yours3lf/index.md): make its data directory available to OpenMW and enable `H3lp Yours3lf.esp`. Use an OpenMW version supported by the H3 release you installed. These pages describe the source in this repository, not every older release.

Your own mod still needs its own data directory and script declaration. Requiring a helper does not register your script with OpenMW.

## Run a complete example

Create `scripts/<mod_name>/h3_demo.lua` inside your mod's data directory:

```lua
local Signal = require 'scripts.s3.signal'
local normalizePath = require 'scripts.s3.normalizePath'

local ready = Signal.new()
ready:connect(function(path)
    print('H3 demo: ' .. path)
end)

local function report()
    ready:fire(normalizePath('Config\\MyMod\\Icon'))
end

return {
    engineHandlers = {
        onInit = report,
        onLoad = report,
    },
}
```

Create your script list alongside the `scripts` directory:

```text
PLAYER: scripts/<mod_name>/h3_demo.lua
```

Enable that script list in OpenMW's content list, with H3 enabled as a dependency. Load a game. The OpenMW log should contain:

```text
H3 demo: config/mymod/icon
```

The example does not load a texture or change game state. It normalizes a string, passes it to a synchronous listener, and prints the result. `onInit` covers initialization and `onLoad` covers loading saved script state; no per-frame polling is needed.

{% usage_note(title="Plain modules, player-script example") %}
Signal and normalizePath do not import OpenMW APIs. This example runs as a player script because its lifecycle handlers belong to that script. Requiring these helpers does not give another script player-only permissions.
{% end %}

## If nothing happens

- **Module not found:** check that H3's data directory is active. Paths passed to `require` are module names, not filesystem paths.
- **No output:** check that your script list is enabled and its script path matches your file. Read earlier log errors before debugging the helper.
- **Missing interface:** a plain module and an installed interface are different entry points. [S3lf](@/h3lp_yours3lf/docs/api/modules/s3lf.md) is `I.s3.lf`, not a Signal-style constructor.

## Choose the next step

- [Signal](@/h3lp_yours3lf/docs/api/modules/signal.md): coordinate synchronous listeners.
- [Debounce](@/h3lp_yours3lf/docs/api/modules/debounce.md): wait until changes settle before acting.
- [normalizePath](@/h3lp_yours3lf/docs/api/modules/normalize-path.md): understand exactly what normalization changes.
- [State and Context](@/h3lp_yours3lf/docs/concepts/state-and-context.md): decide where behavior belongs.
- [Migrating helpers](@/h3lp_yours3lf/docs/migration/from-local-helpers.md): replace existing code without quietly changing its contract.
