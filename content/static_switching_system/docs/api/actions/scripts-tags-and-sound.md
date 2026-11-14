+++
title = "Scripts, Tags, and Sound Actions"
description = "Attach or run scripts, call interfaces, send events, activate objects, manage optional FlexTags, and play positional sounds."
page_template = "docs/page.html"
weight = 50

[extra]
api_docs = true
kind = "api"
+++

## `add_lua_script`

**Shape:** `add_lua_script: string`

Attaches the supplied VFS Lua script path to the current action target.

```yaml
add_lua_script: Scripts/myMod/activator.lua
```

The action passes the path to OpenMW; SSS does not provide a portable file-existence or script-behavior guarantee. A replacement target receives the script when `replace` precedes it in the same action table. If the script is already attached to the target, the action does nothing and does not count as a successful application.

## `remove_lua_script`

**Shape:** `remove_lua_script: string`

Removes the supplied VFS Lua script path from the current action target.

```yaml
remove_lua_script: Scripts/myMod/activator.lua
```

The path is passed to OpenMW for removal. If the script is not attached to the target, the action does nothing and does not count as a successful application.

## `run_lua_script`

**Shape:** `run_lua_script: { script: string, function?: string, args?: any[] }`

Attaches the script to the current action target, which makes OpenMW run the script's `onInit` immediately, then detaches the script in the same action. `onInit` receives `{ function = <name>, args = <args> }` as its init data; the script decides what to do with it. The script must be registered with the `CUSTOM` flag, as any dynamically attached script must.

```yaml
run_lua_script:
  script: scripts/myMod/applyCurse.lua
  function: applyCurse
  args: [curse_blight, 3]
```

A matching script looks like this:

```lua
local self = require 'openmw.self'
local types = require 'openmw.types'

local functions = {}

function functions.applyCurse(spellId, stacks)
  for _ = 1, stacks do
    types.Actor.activeSpells(self):add { id = spellId, effects = { 0 }, stackable = true }
  end
end

return {
  engineHandlers = {
    onInit = function(data) functions[data['function']](unpack(data.args or {})) end,
  },
}
```

This is a one-shot. Timers, `async` callbacks, and event handlers the script registers are discarded when it is detached in the same frame, and events it sends from `onInit` are still delivered. If the script is already attached, OpenMW does not run `onInit` again and SSS then detaches it, so do not use the same path as a persistent script. Engine errors, such as an unknown or non-`CUSTOM` script, are logged as warnings and the action no-ops. Rules without `once` run the script again on every activation that passes the rule's conditions.

## `call_interface`

**Shape:** `call_interface: { interface: string, function: string, args?: any[] }`

Calls a function on a global script interface, synchronously, with the current action target as the first argument followed by `args` in order. Any global interface available to SSS qualifies, including other mods'.

```yaml
call_interface:
  interface: MyQuestMod
  function: markVisited
  args: [tomb_phase_two]
```

A missing interface or function is logged as a warning and no-ops. An error raised by the called function is caught, logged, and no-ops; it does not stop the rest of the rule. Local script interfaces are not reachable from SSS; use `send_event` or `run_lua_script` for those.

## `send_event`

**Shape:** `send_event: { name: string, data?: table }`

Sends a local event to the scripts attached to the current action target. The payload is a copy of `data` with the target injected as `object`.

```yaml
send_event:
  name: MyMod_Awaken
  data:
    stage: 2
```

## `send_global_event`

**Shape:** `send_global_event: { name: string, data?: table }`

Sends a global event with the same payload rule as `send_event`.

```yaml
send_global_event:
  name: MyMod_CritterEntered
  data:
    cell: Gnisis, Arvs-Drelen
```

Events are delivered by OpenMW on a later frame. A receiver sharing an action block with `delete` can receive an `object` that is already invalid, so check `object:isValid()`. Both actions always count as applied for rule and `once` bookkeeping.

## `activate_by_player`

**Shape:** `activate_by_player: boolean`

When the field is truthy, activates the current action target as if the player used it.

```yaml
activate_by_player: true
```

The handler ignores the boolean's value after the action is selected; `false` is skipped by SSS's action dispatch. Activation may trigger other game scripts and is not a pure local mutation.

## `add_tag`

**Shape:** `add_tag: string`

Adds a FlexTag to the current action target. This requires the optional FlexTag mod/interface.

```yaml
add_tag: LootContainer
```

Without FlexTag, no tag is added. The current instance dispatcher still treats the field as a handled action for rule/once bookkeeping, so do not use it as a dependency probe.

## `remove_tag`

**Shape:** `remove_tag: string`

Removes a FlexTag from the current action target and has the same optional dependency and bookkeeping caveat as `add_tag`.

```yaml
remove_tag: LootContainer
```

## `playsound`

**Shape:** `playsound: string | { id?: string, file?: string, chance?: number | { min?: number, max: number }, volume?: number, pitch?: number, loop?: boolean, timeOffset?: number }`

Plays a 3D positional sound at the current action target. A string is a sound record ID. The map must provide `id` or `file`; `file` is a VFS sound path and takes precedence when both are present. Optional chance is tested before playback. Volume, pitch, loop, and time offset are forwarded as sound options.

```yaml
playsound:
  file: sound/fire/fire_loop.wav
  loop: true
  volume: 0.8
```

Missing both `id` and `file`, or a failed chance roll, is a no-op. Zero-valued optional numeric options are forwarded when supplied. The action does not validate that an asset exists before calling OpenMW; package and VFS correctness remain the author's responsibility.

## FlexTag and lifetime notes

FlexTag operations are optional-dependency operations, not built-in tag storage. Script attachment/removal, transient scripts, interface calls, events, and activation delegate to OpenMW or other mods and can have effects outside SSS's own saved state. Sound playback is an immediate effect and is not a persistence mechanism.
