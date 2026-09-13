---
title: Visual Soul Gems
description: Give filled soul gems distinct visuals in OpenMW with four selectable or randomized styles, including support for black soul gems.
date: 2026-09-11

taxonomies:
  tags:
    - Visuals
    - Items
    - OpenMW
    - OpenMW 0.51

extra:
  nexus_id: 60181
  nexus_group_id: 7945146

  install_info:
    data_directories:
      - .
    content_files:
      - VSG.esp

  version: 1.1
---

Visual Soul Gems makes filled soul gems look filled.

VSG uses the excellent [Crystal Soul Gems](https://www.nexusmods.com/morrowind/mods/48300) assets by SVNR, OffworldDevil, and NullCascade to give filled vanilla soul gems four distinct visual styles in OpenMW. VSG also supports black soul gems. Pick one of four styles, or let VSG choose for you.

<!-- more -->

<div align="center">
  <figure>
    <img src="../img/vsg.png" alt="Visual Soul Gems logo" width="512" height="512" />
    <figcaption><h2 class="notoc">Dynamic Soul Gem Visuals for OpenMW</h2></figcaption>
  </figure>
  <br>
  <br>
</div>

## Requirements

- OpenMW 0.51.0 or newer
- Nothing else. The Crystal Soul Gems assets required by VSG are included.

## Overview

Crystal Soul Gems normally ships its visual variants as alternatives: install one mesh set over another and choose a look for your game.

VSG needs those variants available **at the same time**.

To make that possible, VSG bundles the required meshes so all four styles can coexist. No overwrite roulette required.

Only **filled** soul gems are changed. Empty soul gems are left alone.

## Visual Variants

VSG includes four filled-gem styles:

- **Particles**
- **Particles & Static Glow**
- **Static Glow**
- **Ultra Glow**

All four styles are enabled by default.

## Settings

VSG exposes a randomization toggle and one toggle for each visual style:

| Setting | Default | Behavior |
| --- | --- | --- |
| **Randomize** | On | Chooses a random enabled visual variant whenever VSG converts a filled soul gem or stack. |
| **Style toggles** | All On | Choose which visual styles Randomize can use. |

When randomization is enabled, only enabled styles are eligible. When it is disabled, the style toggles become mutually exclusive and the single enabled style is used for every conversion. Re-enabling Randomize restores all four styles.

A soul gem keeps the appearance it received when VSG converted it. Changing the setting later affects future conversions; it does not retroactively repaint objects that have already been replaced.

The settings menu is available in English, German, Spanish, French, and Swedish.

## How It Works

When VSG finds a filled soul gem in the world, it replaces it with a matching visual variant.

OpenMW still treats the replacement as a soul gem. VSG preserves the trapped soul, stack count, ownership, scale, and placement while changing only its appearance.

Stacks stay stacks. Souls stay trapped. The pretty lights are the only part meant to change.

VSG supports all five vanilla soul gem sizes: Petty, Lesser, Common, Greater, and Grand.

It also recognizes filled black soul gems from [Black Soul Gems](https://www.nexusmods.com/morrowind/mods/45902) and [OAAB Data](https://www.nexusmods.com/morrowind/mods/49042), and gives them the same four visual styles.

## Compatibility

VSG uses its own visual records for converted filled soul gems. Conventional mesh replacers that change the original soul gem paths therefore will not affect gems already converted by VSG.

Empty gems are not converted by VSG.

## Installation

Install VSG as a normal OpenMW data directory and enable the mod.

Do **not** install Crystal Soul Gems separately as a requirement for VSG. The assets VSG needs are already included and arranged so its variants can coexist without overwriting one another.

Keep the bundled meshes and textures with the mod. They are part of the runtime design, not optional installer choices.

## Uninstallation

VSG is not a simple mesh replacer. Once a soul gem has been converted, your save may contain a VSG-specific version of that item.

**Mid-save uninstallation is unsupported.** Removing VSG can leave already-converted soul gems pointing to assets that no longer exist.

## Credits

Visual Soul Gems uses assets from **[Crystal Soul Gems](https://www.nexusmods.com/morrowind/mods/48300)**, created by **SVNR, OffworldDevil, and NullCascade** and uploaded by **SVNR**.

Those assets are redistributed under the permissions published on the original Nexus Mods page. Crystal Soul Gems does not permit its assets to be used in mods or files that are sold, and does not permit mods using those assets to earn Nexus Donation Points.

The filled black soul gem NIFs were made by **grumblingvomit**, based on [OAAB Data](https://www.nexusmods.com/morrowind/mods/49042) assets.

Please go give the original mod some love. VSG exists because those meshes are damn good.
