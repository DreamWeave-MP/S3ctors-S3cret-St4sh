---
title: S4V3R
description: Lightweight, combat-aware autosave management with optional start save functionality.
date: 2026-07-22

taxonomies:
  tags:
    - Quality-Of-Life
    - OpenMW-Lua
    - Gameplay

extra:
  nexus_id: 59665
  nexus_group_id: 7702380

  install_info:
    data_directories:
      - .
    content_files:
      - S4V3R.esp

  version: 1.0
---

{{ image(src="/img/s4v3r.png", alt="Saver - OpenMW Autosaves", style="border-radius: 8px;") }}

S4V3R is a brutally opinionated autosave manager with simplistic options and an extremely lightweight performance footprint.

<!-- more -->

{{ install_instructions(describe=true) }}

# Overview

S4V3R is my own take on save management, intended to maintain as few options as actually make sense whilst also not breaking the bank in the Lua profiler or your download count.

It tries to offer the most sane defaults it can:
- Saves every nine minutes
- Keeps a rotating stack of ten slots
- Saves when entering and exiting combat
- Saves when finishing character creation

All of the above options are configurable. With the default settings, this gives you about an hour and a half of backups, alongside your combat saves.

Note that combat saves don't consume your autosave budget, nor does your start save  - so with the defaults, you have a rolling total of 13 saves.

# Interop for Scripters

S4V3R doesn't have a lot to offer in terms of interface, but it tries to expose everything it can. Please let me know if you'd like to see the interface extended. 

When a save is triggered, two events are emitted:
- MENU scope: `S4V3R_MENU_TriggerSave`
- PLAYER scope: `S4V3R_PLAYER_SaveComplete`

You may subscribe to either event depending on the exact timing you require. Additionally, you can register a save handler through the interface using `I.S4V3R.addSaveCompletionHandler`.

Interface fields:
```lua
  ---@param handler fun(saveName: string, saveSlot: integer): boolean?
  addSaveCompletionHandler = function(handler)
    assert(
      type(handler) == 'function',
      'S4V3R.addSaveCompletionHandler was passed a non-function value!'
    )

    saveCompletionHandlers[#saveCompletionHandlers + 1] = handler
  end,
  ---@return boolean canSave
  canSave = function() return sinceLastSave >= SaveInterval and allowedToSave() ~= nil end,
  ---@return integer
  getCurrentSaveSlot = function() return saveSlot end,
  ---@return integer
  getMaxSaves = function() return MaxSaveSlots end,
  ---@return number timeBetweenSaves
  getSaveInterval = function() return SaveInterval end,
  ---@return number timeRemaining
  untilNextSave = function() return SaveInterval - sinceLastSave end,
  version = 1,
```

{{ credits(default=true) }}
