---
title: Events
description: The events S4V3R sends when it saves, and the save classes they describe.
weight: 60
extra:
  api_docs: true
  kind: events
---

## `S4V3R_PLAYER_SaveComplete`

A player-scoped event with no payload, sent to the player whenever S4V3R saves.

Despite the name, S4V3R sends it at the same time it requests the save, not after the save file is written. If you need the save's details, use [`addSaveCompletionHandler`](@/s4v3r/docs/api/interface.md) instead, which runs on this event and receives the save name, slot number, and class.

```lua
---@omw-context player
return {
    eventHandlers = {
        S4V3R_PLAYER_SaveComplete = function()
            -- S4V3R has just requested a save.
        end,
    },
}
```

## `S4V3R_MENU_TriggerSave`

S4V3R's own save request, sent from its player script to its menu script. The payload is an array of `{ saveName, saveSlot, saveClass }`.

Menu scripts may observe it, but must not return `false` from their handler, or S4V3R's menu script may never receive the request. Don't send it yourself: S4V3R treats every one as a real save and updates its autosave rotation to match.

## Save classes

| Value | Name | Saved when |
| --- | --- | --- |
| `1` | `AUTO` | The save interval elapses. Rotates through `MaxSaveSlots` files. |
| `2` | `COMBAT_START` | Combat starts. |
| `3` | `COMBAT_END` | Combat ends. |
| `4` | `GAME_START` | Character creation finishes. |
| `5` | `REST` | The rest or wait menu opens. |
| `6` | `CELL_CHANGE` | The player moves into or out of an interior, when H3lp Yours3lf is installed. |

Every class other than `AUTO` keeps a single file that's overwritten each time.
