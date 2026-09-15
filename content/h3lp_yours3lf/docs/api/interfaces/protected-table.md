---
title: ProtectedTable
description: Compose OpenMW settings, transient runtime state, and methods into one table-shaped manager interface.
weight: 15
extra:
  kind: api
---

{{ api_signature(value="require 'openmw.interfaces'.S3ProtectedTable.new(options) → ProtectedTable") }}

ProtectedTable composes three neighboring things into one table-shaped interface: an OpenMW storage section, arbitrary transient state owned by the script, and user-defined methods. Settings stay in storage; runtime values stay under `.state`; behavior lives on the same manager.

{% usage_note(title="Installed interface · Local and player") %}
Enable H3's plugin and obtain the constructor through `I.S3ProtectedTable`. This is not a plain `require`-returned constructor and it is not available to global or menu scripts.
{% end %}

## What it actually does

The caller does not have to juggle three separate namespaces:

```lua
local settings = Settings.Enabled
local lastUpdate = RuntimeState.lastUpdate
Methods.reset()
```

ProtectedTable presents the same arrangement as one manager:

```lua
local I = require 'openmw.interfaces'

local manager = I.S3ProtectedTable.new {
    inputGroupName = 'SettingsGlobalMyMod',
    managerName = 'MyMod',
}

manager.state.lastUpdate = 0

function manager.reset()
    manager.state.lastUpdate = 0
end

local enabled = manager.Enabled
local lastUpdate = manager.lastUpdate
if enabled and lastUpdate == 0 then manager.reset() end
```

`manager.Enabled` comes from the OpenMW storage section, `manager.state.lastUpdate` is written into arbitrary script-owned state, and `manager.lastUpdate` transparently reads that state through the manager. `manager.reset` is a user-defined method. The composition is the design; protection, synchronization, and ownership rules keep those sources from colliding.

## Construction

```lua
local I = require 'openmw.interfaces'

local manager = I.S3ProtectedTable.new {
    logPrefix = '[ MyMod ]',
    inputGroupName = 'SettingsGlobalMyMod',
    managerName = 'MyMod',
}
```

Provide `inputGroupName` for a global storage section or `storageSection` for an existing section. A standalone `storageSection` also needs a non-empty `managerName`. `logPrefix` prefixes diagnostics.

`subscribeHandler` controls synchronization:

| Value | Behavior |
| --- | --- |
| omitted or `nil` | Use the built-in handler to mirror setting changes. |
| function | Use that handler instead of the built-in handler. H3 wraps it for storage callbacks. |
| `false` | Install no subscription. |

## Reading and writing

Indexing checks cached settings, methods, and `.state`, then reads and caches an uncached setting. A subscription refreshes settings when storage changes.

```lua
local enabled = manager.Enabled
manager.state.lastUpdate = 0
manager.debugLog('enabled:', enabled)
```

Assignments to a writable section update storage; read-only sections reject them. Functions assigned to the manager become methods. Assigning a table to `.state` replaces its contents, not the state table.

The manager is callable and iterates current storage values in sorted key order. `tostring(manager)` lists settings, methods, and runtime state.

## Runtime state

`manager.state` is a writable table for transient values owned by the script. It is separate from the settings section and is not a method.

## Built-in methods

| Member | Behavior |
| --- | --- |
| `manager.debugLog(...)` | Prints arguments when the storage setting `DebugEnable` is true. |
| `manager.notifyPlayer(...)` | Shows a message box when `MessageEnable` is true; player scripts only. |
| `manager.interface(handler)` | Creates a table whose indexed values come from `handler(key)`. |

The interface also exposes a `help` string for the in-game console.

{% usage_note(title="Settings are not arbitrary runtime state") %}
Use `.state` for transient tables, counters, and other script-owned values. Do not put closures, UI elements, connection handles, or other runtime objects into a storage section or assume the manager itself is save-safe.
{% end %}
