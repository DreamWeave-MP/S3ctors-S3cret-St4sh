---
title: Transmog Menu
description: OpenMW reimplementation of MWSE's Cosmetic Overrides.
date: 2024-04-11

taxonomies:
  tags:
    - User Interface
    - OpenMW-Lua
    - MWSE Ports

extra:
  install_info:
    data_directories:
     - .
    content_files:
     - transmog.omwscripts
---

The Transmog Menu is originally derived from [Cosmetic Overrides for MWSE](https://www.nexusmods.com/morrowind/mods/47713). However, that mod does all its work in an MCM, and I wanted to go all-out here.

Transmog Menu is much closer to a full reimplementation of the Morrowind inventory menu. It does as much as the API is presently capable of in UI terms in as modular a way as possible, constituting just over three thousand lines of annotated code I hope can prove useful to someone else as well, covering subjects such as [the new Actions/Triggers API](https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_input.html), [loads and loads of from-scratch UI](https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_ui.html), and [OpenMW's native MCM](https://openmw.readthedocs.io/en/latest/reference/lua-scripting/interface_settings.html)

Transmog Menu isn't fully complete and I have broader goals for it, but right now I'm golfing it down as much as possible so that I can extend it more easily and hopefully make it more useful for other scripters on the way.

## Usage

Transmog Menu requires requires OpenMW 0.49, or a development build as of this writing. Otherwise, it is completely standalone and *should* be compatible with the final released version of 0.49, whenever that happens.

Follow the installation instructions below, and that should get you started! Transmog menu tries to explain as much ingame as possible, but a few things bear mentioning here:

1. To 'mog two items together, just open the menu and click on two items.
1. You can preview items that would appear on your character visually by holding the spacebar. This binding does not use the Settings menu and is hardcoded. If you have a new item selected with a valid appearance, you'll preview it automatically.
1. Almost any two object types can be combined together. Mix and match stuff and get weird with it!
1. In general, objects will inherit the stats and properties of the top, or base, item, with the appearance of the new one in the bottom box. There are special cases for a few types of objects, however...
1. This will be explained ingame when the mod is first installed, but it also bears mentioning here. At this time, OpenMW does not allow you to use its settings menu *and* automatically have working default keybinds. Thus, you have to set the key bindings yourself or this mod *will not work*. I recommend the following defaults:

        Rotate Right: Q
        Rotate Left: E
        Select: Enter/Return
        Open Transmog Menu: L

{{ install_instructions(describe=true) }}

<p align="center">
  <img src="../img/modathonbanner2024.png" alt="Modathon 2024" />
</p>

## Credits

Author: **S3ctor**  

All code was written by Dave Corley under the GPL3 license. Please enjoy my mod, hack away as you please, and respect the freedoms of your fellow modders and players in the meantime.  

Brought to you by:  

<a class="MWText" id="kartoffel" href="https://discord.com/channels/260439894298460160/1235260117566357535">Kartoffel's OpenMW Mod Bounties<a/>
