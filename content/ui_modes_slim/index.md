---
title: UI Modes Slim
description: Streamlined version of UI Modes, focused on simplified menu interactions.
date: 2025-03-19

taxonomies:
  tags:
    - User Interface
    - OpenMW-Lua
    - Hotkeys

extra:
  install_info:
    data_directories:
      - .
    content_files:
      - uiModesSlim.esp
    config:
      - "# Instead of ^"
      - .

  version: 0.2
---

Streamlined version of UI Modes, focused on simplified menu interactions.

<!-- more -->

**Requires OpenMW 0.49 or newer!**

Features (each feature can be separately enabled or disabled in mod settings):

- Separate UI pages for Map, Spells, Stats, Journal, and Magic
- Key bindings 'M' (Magic), 'Shift + M' (Map, optional), 'C' (Stats), 'I' (Inventory)
- Use right click to exit any menu
- Attack button (left mouse click) automatically prepares the last used weapon/spell.
- Ability to rotate 3rd person camera in inventory mode and during dialogs (controls: left/right arrow keys, controller right stick).

{{ install_instructions(describe=true) }}

Alternatively, you may simply (manually) add the following entry to your openmw.cfg:
`config=C:/the/location/of/ui_modes_slim`  

For example, if you have the `ui_modes_slim` folder in the same location as openmw.cfg, you can simply do this:
`config=ui_modes_slim`  

This will ensure UI Modes Slim loads after any other mods in your config chain and also apply its settings for you automagically.

You may, of course, apply these settings manually via settings.cfg, but this is more tedious and fallible:

```toml
[Windows]
inventory h = 0.896296
inventory w = 0.833333
inventory x = 0.00625
inventory y = 0.0611111
spells h = 0.828704
spells w = 0.921354
spells x = 0.0348958
spells y = 0.0694444
stats h = 0.827778
stats w = 0.957292
stats x = 0.0296875
stats y = 0.0703704
```

{% credits(default=false) %}
- Originally written by [Petr Mikheev](https://gitlab.com/ptmikheev)  
- Stripped down by S3ctor  
{% end %}
