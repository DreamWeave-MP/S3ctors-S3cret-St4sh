+++
title = "StaticSwitcher_G Interface"
description = "Advanced global-script integration with SSS's inspection interface."
weight = 140

[extra]
api_docs = true
kind = "interface"
+++

{{ api_signature(value="require('openmw.interfaces').StaticSwitcher_G → version 4 interface") }}

`StaticSwitcher_G` is an advanced OpenMW-Lua integration surface provided by SSS's global script. Prefer YAML for authoring.

The interface reports `version = 4`.

## Version guard

The provider is optional. Check that it exists and that it exposes the interface version your integration understands before reading any member:

```lua
---@omw-context global
local I = require 'openmw.interfaces'
local SSS = I.StaticSwitcher_G

if not SSS or SSS.version < 4 then
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
| `version` | `integer` | Current interface version, currently `4`. |

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

The interface is intentionally observational. It does not provide registration, module mutation, replacement triggering, deletion, or save-state editing operations.

It does not combine static and instance pipelines. See [Pipelines and Module Boundaries](@/static_switching_system/docs/concepts/pipelines.md).
