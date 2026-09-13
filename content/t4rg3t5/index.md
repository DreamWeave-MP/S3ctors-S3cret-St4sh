---
title: T4rg3t5
description: Lock on. Stay on. Dark Souls 1-inspired targeting for the modern outlander.
date: 2026-09-10

taxonomies:
  tags:
    - User Interface
    - Combat
    - OpenMW 0.50

extra:
  nexus_id: 57703
  nexus_group_id: 6591580
  install_info:
    data_directories:
      - .
    content_files:
      - T4rg3t5.esp

  version: 1.0
---

<div align="center">
  <h2 class="notoc">Lock on. Stay on.</h2>
  <p><em>Dark Souls 1-inspired targeting for the modern outlander.</em></p>
</div>

T4rg3t5 is a complete lock-on system for OpenMW: fast target acquisition, directional switching, automatic facing, readable combat feedback, and a rebuilt third-person camera designed around the fight instead of merely pointing at it.

<!-- more -->

## See it in action

<div align="center">
  <a href="https://youtu.be/OwHE_Or-Ps0"><strong>Watch the T4rg3t5 1.0 combat demo</strong></a>
</div>

T4rg3t5 1.0 is built around a collision-aware over-the-shoulder camera with automatic shoulder switching, independent camera and look smoothing, configurable framing, optional lock FOV, and graceful lock loss. It keeps the player and target readable without turning the camera into a hostage situation.

## Requirements

<div align="center">
  <a href="https://www.nexusmods.com/morrowind/mods/56417"><img src="../img/h3Required.svg" alt="H3lp Yours3lf"></a>
  <a href="https://openmw.org/downloads"><img src="../img/openmwRequired.svg" alt="Download OpenMW"></a>
  <br>
</div>

Assign a keybinding under **Settings → T4rg3t5 → Target Lock Core**, or the mod will be (mostly) useless.

{{ h3_usage(mod="T4RG3T5") }}

## What T4rg3t5 does

### Lock camera

- Collision-aware third-person orbit camera
- Automatic left/right shoulder switching when collision or visibility demands it
- Separate camera-position and look-target smoothing
- Configurable distance, height, shoulder offset, framing, look bias, responsiveness, and minimum collision distance
- Optional lock-camera FOV
- Configurable grace period before an invalid target is dropped
- First-person tracking without forcing the third-person camera

### Smart targeting

- Selects the nearest **eligible combat target** in your field of view
- Rejects offscreen and obstructed candidates during acquisition
- Optional continued line-of-sight checking after lock-on
- Flick left or right to switch targets in that screen direction
- Optional combat auto-lock when an enemy engages you
- Automatically switches when the current target dies
- Releases locks when targets remain invalid, leave range, or are configured to unlock on sheathing

T4rg3t5 listens to OpenMW's combat-target updates instead of scanning every actor in the world. The hot path came through the barbershop for a fade.

### Target feedback

- 31 bundled lock-on icons
- Marker size scales smoothly with target distance
- Marker color tracks health continuously across six configurable colors
- Hit feedback makes the marker bounce on successful strikes
- Custom marker textures are simple DDS replacements

T4rg3t5 owns vanilla crosshair visibility while enabled: the vanilla crosshair is hidden during a semantic target lock and shown while unlocked. It is not intended to share crosshair ownership with another mod.

### Combat behavior

- Automatically faces the locked target while tracking is active
- Respects weapon and spell readiness
- Can clear the lock when you sheath
- Keeps target state separate from marker presentation

## For mod authors

T4rg3t5 1.0 exposes a deliberately small integration surface: live state and settings through `I.S3LockOn.Manager`, target changes through `S3TargetLockOnto`, and the `S3TargetLock` input trigger for normal lock behavior.

Anything documented is fair game. Camera internals, frame handlers, and the rest of the machinery are implementation details. Poke at 'em if you like; just don't build your house there.

See the full [T4rg3t5 API and modder documentation](@/t4rg3t5/docs/_index.md).
