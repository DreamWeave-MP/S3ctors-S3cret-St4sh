---
title: S4V3R Interface
description: The player-scoped I.S4V3R interface for save timing and save notifications.
weight: 50
extra:
  api_docs: true
  kind: interface
---

`I.S4V3R` lives in the player context. Guard it if S4V3R is optional.

```lua
---@omw-context player
local I = require 'openmw.interfaces'

if I.S4V3R then
    I.S4V3R.addSaveCompletionHandler(function(saveName, saveSlot, saveClass)
        print(('S4V3R is saving: %s'):format(saveName))
    end)
end
```

The current interface version is `1`.

## Members

| Member | Signature | Behavior |
| --- | --- | --- |
| `addSaveCompletionHandler` | `fun(handler: fun(saveName: string, saveSlot: integer, saveClass: SaveClass): boolean?)` | Registers a handler that runs every time S4V3R saves. Throws if `handler` isn't a function. |
| `canSave` | `fun() → boolean` | Returns whether the save interval has elapsed and the player is somewhere S4V3R would save: no menu open, not in combat, on solid ground, and not swimming. |
| `getCurrentSaveSlot` | `fun() → integer` | Returns the number the next interval autosave will put in its name. |
| `getMaxSaves` | `fun() → number` | Returns the `MaxSaveSlots` setting. |
| `getSaveInterval` | `fun() → number` | Returns the save interval in seconds. |
| `untilNextSave` | `fun() → number` | Returns the seconds of unpaused play until the next interval autosave is due. Negative while an overdue autosave waits for a safe moment. |
| `version` | `integer` | Interface version. |

## Save completion handlers

Handlers run when the player receives [`S4V3R_PLAYER_SaveComplete`](@/s4v3r/docs/api/events.md). S4V3R sends that event at the same time it asks the menu script to save, so the save file may not be written yet when your handler runs.

Handlers run newest first. Returning `false` stops older handlers from running.

`saveClass` says which kind of save it was; see [save classes](@/s4v3r/docs/api/events.md#save-classes). `saveSlot` only means something for interval autosaves (`saveClass == 1`).

## Slot numbers

`getCurrentSaveSlot` and a handler's `saveSlot` are the number shown in the save's name. They don't decide which file gets overwritten: S4V3R always overwrites the oldest interval autosave on disk. After loading an older save, two autosaves can briefly share a number.

When interval autosaves are disabled, the timer behind `canSave` and `untilNextSave` stops advancing.
