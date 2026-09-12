---
title: ScriptContext
description: Identify the OpenMW script context in code shared across script types.
weight: 60
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.scriptContext' → ScriptContext") }}

Use ScriptContext when one shared Lua module genuinely needs to behave differently in local, player, global, menu, or load scripts. It tells you where you are; it does not give you permissions you do not have.

{% usage_note(title="Context detection · Not context switching") %}
The module may be required from all supported contexts, but the APIs available to the rest of your script still follow OpenMW's context rules. Detecting `Player` does not make a global script a player script.
{% end %}

```lua
local ScriptContext = require 'scripts.s3.scriptContext'

if ScriptContext.get() == ScriptContext.Types.Player then
    print('Running in the player script')
end
```

The enum contains `Types.Local`, `Types.Global`, `Types.Player`, `Types.Menu`, and `Types.Load`. `get()` returns one member or raises if detection fails.

On load, the module probes context-specific OpenMW modules. `get()` checks global, load, and menu before using the attached object to distinguish local from player.

Use it when one plain module needs a context-appropriate implementation, as [LogMessage](@/h3lp_yours3lf/docs/api/modules/log-message.md) does. Prefer separate modules when branching obscures permissions or lifecycle.
