---
title: Settings
description: S4V3R's player-backed settings and how to read them.
weight: 40
extra:
  api_docs: true
  kind: settings
---

Settings live in `SettingsPlayerS4V3R`. PLAYER and MENU scripts can read and write the section directly. S4V3R subscribes to it, so external writes take effect immediately.

```lua
---@omw-context player
local Settings = require 'openmw.storage'.playerSection('SettingsPlayerS4V3R')

local combatSavesEnabled = Settings:get('CombatSaveToggle')
```

## Fields

| Field | Type | Default | Meaning |
| --- | --- | --- | --- |
| `S4V3RActive` | boolean | `true` | Enables S4V3R. When off, S4V3R makes no saves at all. |
| `IntervalSaveToggle` | boolean | `true` | Enables interval autosaves. |
| `SaveInterval` | number | `9` | Minutes of unpaused play between interval autosaves, from `1` to `60`. |
| `MaxSaveSlots` | number | `10` | Number of interval autosaves to keep, from `1` to `100`. Once reached, the oldest is overwritten. Lowering it deletes the excess oldest autosaves at the next autosave. |
| `CombatSaveToggle` | boolean | `true` | Saves when combat starts and ends. |
| `CombatSaveCooldown` | number | `1` | Minimum minutes between combat saves, from `0` to `60`. `0` disables the cooldown. |
| `RestSaveToggle` | boolean | `false` | Saves when the rest or wait menu opens. |
| `StartSaveToggle` | boolean | `true` | Saves once when character creation finishes. |
| `DeleteSavesOnDeath` | boolean | `false` | Ironman mode. On death, deletes every save S4V3R made for the current character and quits the game. |
| `SavePrefix` | string | `''` | Prefix added to S4V3R's save names. |
| `DebugEnable` | boolean | `false` | Prints S4V3R's debug messages to the console. |
| `CellChangeSaveToggle` | boolean | `false` | Saves after the player moves into or out of an interior. Only registered when `H3lp Yours3lf.esp` is enabled; otherwise it reads as `nil`. |

S4V3R also tracks which save files belong to each character in the `S4V3RSaveFiles` section. That's an implementation detail. Don't write to it.
