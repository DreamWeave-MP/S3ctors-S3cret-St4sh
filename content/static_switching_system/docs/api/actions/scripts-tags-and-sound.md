+++
title = "Scripts, Tags, and Sound Actions"
description = "Attach scripts, activate objects, manage optional FlexTags, and play positional sounds."
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

The action passes the path to OpenMW; SSS does not provide a portable file-existence or script-behavior guarantee. A replacement target receives the script when `replace` precedes it in the same action table.

## `remove_lua_script`

**Shape:** `remove_lua_script: string`

Removes the supplied VFS Lua script path from the current action target.

```yaml
remove_lua_script: Scripts/myMod/activator.lua
```

The path is passed to OpenMW for removal. Removing a path that is not attached is not described as a content migration or a persistence operation by SSS.

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

FlexTag operations are optional-dependency operations, not built-in tag storage. Script attachment/removal and activation delegate to OpenMW and can have effects outside SSS's own saved state. Sound playback is an immediate effect and is not a persistence mechanism.
