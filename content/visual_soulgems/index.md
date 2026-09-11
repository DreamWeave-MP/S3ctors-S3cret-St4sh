---
title: Visual Soul Gems
description: Filled soul gem visuals for OpenMW, with four Crystal Soul Gems effect variants and optional randomization.

taxonomies:
  tags:
    - Visuals
    - Items
    - OpenMW

extra:
  nexus_id: 60181
  nexus_group_id: 7945146

  data_directories:
    - .
  content_files:
    - VSG.esp

  version: 1.0
---

Visual Soul Gems makes filled soul gems look filled.

VSG uses the excellent [Crystal Soul Gems](https://www.nexusmods.com/morrowind/mods/48300) assets by SVNR, OffworldDevil, and NullCascade to give filled vanilla soul gems four distinct visual styles in OpenMW. Pick one, or let VSG choose for you.

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

- OpenMW
- Nothing else. The Crystal Soul Gems assets required by VSG are included.

## Overview

Crystal Soul Gems normally ships its visual variants as alternatives: install one mesh set over another and whichever files win the VFS overwrite wins in game.

VSG needs those variants available **at the same time**.

To make that possible, the required Crystal Soul Gems meshes are bundled with VSG and moved into separate internal paths. VSG can then select the appropriate model at runtime without asking four mutually exclusive replacers to somehow coexist. No overwrite roulette required.

Only **filled** soul gems are changed. Empty soul gems are left alone.

VSG supports all soul gem variants.

## Visual Variants

VSG includes four filled-gem styles:

- **Particles**
- **Particles & Static Glow**
- **Static Glow**
- **Ultra Glow**

**Ultra Glow** is the default.

## Settings

VSG exposes two global settings:

| Setting | Default | Behavior |
| --- | --- | --- |
| **Soul Gem Variant** | Ultra Glow | Chooses the visual style used for newly converted filled soul gems. |
| **Randomize** | Off | Chooses a random visual variant whenever VSG converts a filled soul gem or stack. |

When randomization is enabled, the selected fixed variant is ignored for that conversion.

A soul gem keeps the appearance it received when VSG converted it. Changing the setting later affects future conversions; it does not retroactively repaint objects that have already been replaced.

## What VSG Preserves

VSG is not merely swapping a mesh path on the existing object. OpenMW does not currently expose that operation for an individual object, so VSG creates an equivalent replacement record using the selected model and replaces the filled gem with it.

During that replacement, VSG preserves the important instance state:

- trapped soul;
- stack count;
- owner;
- owning faction and faction rank;
- scale;
- cell, position, and rotation.

Stacks stay stacks. Souls stay trapped. The pretty lights are the only part meant to change.

## Compatibility

VSG intentionally owns the model used by filled vanilla soul gems after they are converted. A conventional replacer that changes the vanilla soul gem mesh path will therefore not change a VSG-generated filled gem.

Empty gems are not converted by VSG.

## Installation

Install VSG as a normal OpenMW data directory and enable the mod.

Do **not** install Crystal Soul Gems separately as a requirement for VSG. The assets VSG needs are already included and arranged so its variants can coexist without overwriting one another.

Keep the bundled meshes and textures with the mod. They are part of the runtime design, not optional installer choices.

## Uninstallation

VSG creates replacement records and saves references to them. It is therefore not equivalent to a purely visual texture or mesh replacer.

Mid-save uninstallation is unsupported. Removing VSG's assets from a save containing converted soul gems can leave those objects referring to models that are no longer present.

## Credits

Visual Soul Gems uses assets from **[Crystal Soul Gems](https://www.nexusmods.com/morrowind/mods/48300)**, created by **SVNR, OffworldDevil, and NullCascade** and uploaded by **SVNR**.

Those assets are redistributed under the permissions published on the original Nexus Mods page. Crystal Soul Gems does not permit its assets to be used in mods or files that are sold, and does not permit mods using those assets to earn Nexus Donation Points.

Please go give the original mod some love. VSG exists because those meshes are damn good.
