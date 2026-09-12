---
title: ProtectedTable
description: Bind settings and runtime state to a small, inspectable manager interface.
weight: 15
extra:
  kind: api
---

{{ api_signature(value="require('openmw.interfaces').S3ProtectedTable.new(options) → ProtectedTable") }}

Use ProtectedTable when a settings table has grown methods and transient state around it. Settings stay in storage; runtime state stays under `.state`; methods live on the same manager.

{% usage_note(title="Installed interface · Local and player") %}
Enable H3's plugin and obtain the constructor through `I.S3ProtectedTable`. This is not a plain `require`-returned constructor and it is not available to global or menu scripts.
{% end %}

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

## Built-in methods

| Member | Behavior |
| --- | --- |
| `manager.state` | Writable table for runtime values; not the settings section. |
| `manager.debugLog(...)` | Prints arguments when the storage setting `DebugEnable` is true. |
| `manager.notifyPlayer(...)` | Shows a message box when `MessageEnable` is true; player scripts only. |
| `manager.interface(handler)` | Creates a table whose indexed values come from `handler(key)`. |

The interface also exposes a `help` string for the in-game console.

{% usage_note(title="Settings are not arbitrary runtime state") %}
Use `.state` for transient tables, counters, and other script-owned values. Do not put closures, UI elements, connection handles, or other runtime objects into a storage section or assume the manager itself is save-safe.
{% end %}
