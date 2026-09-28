---
title: S4V3R
description: Lightweight, combat-aware autosave management with optional rest and cell change saves.
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

  version: 1.5
---

{{ image(src="/img/s4v3r.png", alt="Saver - OpenMW Autosaves", style="border-radius: 8px;") }}

S4V3R is a brutally opinionated autosave manager with simplistic options and an extremely lightweight performance footprint.

<!-- more -->

{{ install_instructions(describe=true) }}

# Overview

S4V3R is my own take on save management, intended to maintain as few options as actually make sense whilst also not breaking the bank in the Lua profiler or your download count.

It tries to offer the most sane defaults it can:
- Saves every nine minutes of unpaused play
- Keeps a rotating stack of ten autosaves, overwriting the oldest
- Saves when entering and exiting combat, at most once per minute
- Saves once when character creation finishes
- Empty, but customizable, save prefixes

All of the above options are configurable. With the default settings, this gives you about an hour and a half of backups, alongside your combat saves.

Combat saves only trigger when an enemy is actually targeting you, or, with [Follower Detection Util](https://www.nexusmods.com/morrowind/mods/58053) installed, one of your followers.

# Optional Saves

These are disabled by default:
- **Save When Resting** saves after you rest or wait for at least an hour. If you enable it, you'll probably want to disable OpenMW's own autosave on rest (`autosave` under `[Saves]`), since S4V3R can't take over or replace the engine's autosave.
- **Save On Cell Change** saves after you move into or out of an interior. Walking between exterior cells never triggers it. Requires [H3lp Yours3lf](@/h3lp_yours3lf/index.md); the setting only appears when `H3lp Yours3lf.esp` is enabled.

Combat, start, rest, and cell change saves each keep a single file that's overwritten every time, and none of them count toward your autosave limit. With the defaults, you have a rolling total of 13 saves.

# Ironman Mode

Ironman mode deletes every save S4V3R made for your character when you die, then quits the game. Your manual saves and quicksaves are never touched. Naturally, this is disabled by default.

# Settings

| Setting | Default |
| --- | --- |
| Disable/Enable | Enabled |
| Enable Interval Saves | Yes |
| Save Interval | 9 minutes |
| Max Saves | 10 |
| Enable Combat Saves | Yes |
| Combat Save Cooldown | 1 minute |
| Save When Resting | No |
| Enable Start Saves | Yes |
| Ironman Mode | No |
| Save Name Prefix | Empty |
| Enable Logging | No |
| Save On Cell Change | No (requires H3lp Yours3lf) |

# Optional Integrations

- [Follower Detection Util](https://www.nexusmods.com/morrowind/mods/58053): combat saves also trigger when enemies target your followers.
- [H3lp Yours3lf](@/h3lp_yours3lf/index.md): enables Save On Cell Change.
- Starwind: detected automatically, and the start save is timed for Starwind's character creation.

S4V3R comes with English, French, and Swedish localizations.

Scripters can find S4V3R's interface, events, and settings in the [S4V3R documentation](@/s4v3r/docs/_index.md).

{{ credits(default=true) }}
