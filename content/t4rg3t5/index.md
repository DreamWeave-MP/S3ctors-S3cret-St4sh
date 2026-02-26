---
title: T4rg3t5
description: T4rg3ts is a comprehensive Dark Souls-style lock-on targeting system for OpenMW that provides precise enemy tracking, visual target indicators, and intelligent combat automation.

taxonomies:
  tags:
    - User Interface
    - Combat
    - OpenMW 0.50

extra:
  install_info:
    data_directories:
      - .
    content_files:
      - T4rg3t5.esp

  version: 0.5
---

With T4rgets, an enemy's health is displayed according to the color of the icon. Each enemy has five phases from full to wounded to dead, with the actual icon color mixing between the two nearest colors. This means you always know how healthy the enemy is in combat!

Target indicators also grow in size dynamically according to how far away your target is. Additionally, it is impossible to target enemies which are offscreen, and the mod does not use any raycasts unless the `CheckLOS` setting is enabled - what this means for you is no bad targets, and high performance (as much as can be expected from updating a UI element every frame, anyway).

<!-- more -->

<div align="center">
  <figure>
    <img src="../img/t4rg3t5.png" alt="targets icon" width="512" height="512" />
    <figcaption><h2 class="notoc">Morrowind Lock-On Targeting System</h2></figcaption>
  </figure>
  <br>
  <br>
</div>

T4rg3t5 comes with a full suite of 31 icons to use for lock-on indicators. Additionally, it's very easy to create new target lock icons for T4rg3t5 for your own mods or personal use.

Please make sure to assign a keybinding for T4rg3t5 to use, or the mod will be (mostly) useless.

## Requirements

<div align="center">
  <a href="https://www.nexusmods.com/morrowind/mods/56417"><img src="../img/h3Required.svg" alt="Download OpenMW"></a>
  <a href="https://openmw.org/downloads"><img src="../img/openmwRequired.svg" alt="H3lp Yours3lf"></a>
  <br>
</div>

## Core Features

### Smart Target Acquisition

- Automatic Target Selection: Finds the nearest valid enemy in your field of view
  
![Target Switching](../img/t4rg3t5/targetSwitching.webp)

- Line-of-Sight Checking: Ensures targets are actually visible and not behind obstacles

- Flick Switching: Quickly change targets by flicking the mouse left or right

![Flick Switching](../img/t4rg3t5/flickSwitching.webp)

Combat Auto-Lock: Automatically locks onto enemies who initiate combat with you
  
![Combat Auto-Lock](../img/t4rg3t5/autoTarget.webp)

### Visual Target Indicators

1. Dynamic Lock Icons: Customizable target markers that scale with distance

1. Health-Based Coloring: Icon color changes based on enemy health status:

    - Full Health (100%+): Primary color

    - Very Healthy (80-100%): Mix with full health color

    - Healthy (60-80%): Distinct healthy state

    - Wounded (40-60%): Noticeable wound indication

    - Very Wounded (20-40%): Critical condition warning

    - Dead/Dying (0-20%): Near death state
  
![Health Coloration](../img/t4rg3t5/healthColoration.webp)

1. Hit Feedback: Icons "bounce" when you successfully hit locked targets
  
![Hit Bounce](../img/t4rg3t5/hitBounce.webp)

1. Distance Scaling: Icons grow/shrink based on target distance

### Intelligent Automation

1. Auto-Facing: Character automatically turns to face locked targets

1. Weapon Awareness: Only allows locking when wielding weapons

1. Smart Target Management:

    - Automatically switches targets when current target dies

    - Breaks lock when targets move out of sight

    - Releases lock when sheathing weapons

## For Modders

### Events

Target locking always happens by way of sending an event. If you wish to modify this behavior somehow, you may create an eventHandler for the `S3TargetLockOnto` event. This will allow you to prevent target locking in some circumstances, change the target, do some specific behavior when a target is locked, etc. In the eventData is *only* the targeted actor, which is nil if the target lock has been broken for any reason.

### Triggers

You can also engage target locking manually from any `PLAYER` script by calling `input.activateTrigger('S3TargetLockOn')`. This will either disable or enable locking as appropriate.
If you care to check whether a target is already selected or not, then use `I.S3LockOn.Manager.getMarkerVisibility()`.

### ProtectedTable

T4rg3t5 uses `H3lp Yours3lf`'s protected table interface, which offers many conveniences - such as displaying all the associated setting values by simply trying to print the table. Try the following the console and explore for yourself:

```lua
luap
I.S3LockOn.Manager
```

### Making New Icons

Making new Icons for T4rg3t5 is dead simple. The recommended way is to use GIMP, but any image editor should be able to handle this task.

1. First, pick or create a source image.
1. Open it in GIMP
1. Use Colors -> Threshold to flatten all the colors to pure black/white. Make sure to adjust the values to find ones that fit your image.
1. Either delete the black pixels, or lighten them, using Colors -> Levels to increase the white levels of these pixels, so that the script's coloration works better.
1. Use Image -> Scale Image to resize the image to 128x128
1. Export as DDS without mipmaps OR compression to a subfolder, `textures/s3/crosshair`

<!-- data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAABlBMVEUAAAD///+l2Z/dAAAAAXRSTlMAQObYZgAAAGlJREFUKM+FUVsKACAMsvtfuo85XSU0IkL30AV8YlUkGBkHXlj43Uv5PaVp9yFDopP6SB0JAnVVRcvl063cHB4qYtiTqEMYnGFRc20ksA5u+LTS5OPel0pgc3OJr5+bQWTSjyN9utf7jQ38qQDY40DqPgAAAABJRU5ErkJggg== -->
