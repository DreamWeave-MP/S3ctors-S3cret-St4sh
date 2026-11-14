+++
title = "StaticSwitcher_G Interface"
description = "Advanced global-script integration with SSS's inspection interface."
weight = 140

[extra]
api_docs = true
kind = "interface"
+++

{{ api_signature(value="require('openmw.interfaces').StaticSwitcher_G → version 6 interface") }}

`StaticSwitcher_G` is an advanced OpenMW-Lua integration surface provided by SSS's global script. Prefer YAML for authoring.

The interface reports `version = 6`. Version 6 added rule triggers, the `set_weather` action, and the `trigger` member. Version 5 added the spell, transient script, interface call, and event actions and the `is_follower` condition to the YAML contract; its Lua members were unchanged from version 4.

## Version guard

The provider is optional. Check that it exists and that it exposes the interface version your integration understands before reading any member:

```lua
---@omw-context global
local I = require 'openmw.interfaces'
local SSS = I.StaticSwitcher_G

if not SSS or SSS.version < 5 then
    return
end
```

Use a minimum-version check when later versions preserve the members your integration needs. If your integration depends on an exact table layout, reject unknown versions.

## Members

| Member | Signature | Contract |
| --- | --- | --- |
| `getRefNum` | `fun(object: openmw.GObject) → boolean, number` | Returns whether the object is generated and its local/generated reference number. |
| `composedReplacements` | `fun() → table` | Returns a read-only view of loaded static replacement data. This is diagnostic/advanced data, not a stable YAML authoring substitute. |
| `objectModificationStore` | `fun() → table` | Returns a read-only view of loaded instance rules keyed by canonical module ID. Rule-table internals are advanced data. |
| `overrideRecords` | `fun() → table` | Returns a read-only view of generated replacement record IDs keyed by canonical static module ID. |
| `trigger` | `fun(triggerName: string, object: openmw.GObject) → boolean` | Runs every rule listening to `custom:<triggerName>` on the object. Returns false when no rule listens, the object is not in the world, the call repeats within the debounce window, or it is made while any SSS rule is running. Added in version 6. |
| `version` | `integer` | Current interface version, currently `6`. |

“Read-only” applies to the exposed view. Do not mutate returned tables, object handles, generated record IDs, or bookkeeping. Validate object handles before using them; an object can become invalid during deferred replacement or deletion.

## Example

`getRefNum` distinguishes an original content-backed object from a generated object and returns its local/generated reference number. It does not keep the object alive or make an invalid handle safe to use.

```lua
---@omw-context global
local I = require 'openmw.interfaces'
local SSS = I.StaticSwitcher_G

local function describeObject(object)
    if not SSS or not object or not object:isValid() then return end
    return SSS.getRefNum(object)
end
```

### Firing a custom trigger

`trigger` runs the rules a module author wrote for `custom:<name>` on one object. It returns whether the rules were run:

```lua
---@omw-context global
local I = require 'openmw.interfaces'
local SSS = I.StaticSwitcher_G

local function soundTheAlarm(guard)
    if not SSS or SSS.version < 6 then return false end
    return SSS.trigger('myMod_alarm', guard)
end
```

Scripts in other contexts send the global event instead; it carries no return value:

```lua
---@omw-context local
local core = require 'openmw.core'
local self = require 'openmw.self'

core.sendGlobalEvent('StaticSwitcherTrigger', { name = 'myMod_alarm', object = self.object })
```

`Examples/InstanceModifier_SoundTheAlarm.yaml` is the module side of this pair.

Apart from `trigger`, the interface is observational. It does not provide registration, module mutation, deletion, or save-state editing operations. `trigger` runs only rules a module author wrote for that custom trigger name; see [Triggers](@/static_switching_system/docs/concepts/triggers.md#custom-triggers). The same request can be sent from any script context as the global event `StaticSwitcherTrigger` with `{ name, object }`.

It does not combine static and instance pipelines. See [Pipelines and Module Boundaries](@/static_switching_system/docs/concepts/pipelines.md).
