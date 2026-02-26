---
title: Luamics
description: Mimics for OpenMW, inspired by Dark Souls, based on concit's Mimic assets.
date: 2025-03-19

taxonomies:
  tags:
    - Gameplay
    - OpenMW-Lua

extra:
  install_info:
    data_directories:
      - .
    content_files:
      - luamics.omwaddon
  version: 1.1
---

Luamics is a simple global script that adds a chance for any chest encountered in-game to be replaced by a mimic chest. Mimic chests will retain their original loot, and spawn at a rate of 5%. Chests which are scripted, owned, or have `trader` in their record id are ineligible to be converted to mimics, so the script *should* be relatively safe. Should be, that is.

<!-- more -->

{{ install_instructions(describe=true) }}

{{ credits(default=true) }}
