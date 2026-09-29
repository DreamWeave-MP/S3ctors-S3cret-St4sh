---
title: Crassified Navigation
description: Get Lost for OpenMW! Hide your map and feel the pain.
date: 2024-01-24

taxonomies:
  tags:
    - User Interface
    - Gameplay

extra:
  icon: img/crassius.png
  cover: img/crassnav-map.png
---
# Uncle Crassius Doesn't Need A Map. Why Should You?

Crassified Navigation is a simple mod, but meant to be as cursed as possible. It's effectively an OpenMW port of the mod `Get Lost`, spawned by a user request in MMC. But it comes with an extra cursed twist, being that as much of the operative Lua code as possible is embedded directly into the mod's omwaddon.

Nevertheless, it works just as well and easily as anything else.

<!-- more -->

{{ image(src="/img/crassnav-map.png", alt="Crassius Curio is on the Map.", style="border-radius: 8px;") }}

{{ install_instructions(describe=true) }}

Also, add the following to your [settings.cfg](https://openmw.readthedocs.io/en/stable/reference/modding/paths.html):

```toml
[Windows]
map hidden = true
```

{{ credits(default=true) }}
