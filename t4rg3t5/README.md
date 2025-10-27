# T4rg3t5

<div align="center">
  <figure>
    <img src="../img/t4rg3t5.png" alt="targets icon" width="512" height="512" />
    <figcaption><h2 class="notoc">Morrowind Lock-On Targeting System</h2></figcaption>
  </figure>
  <br>
  <br>
</div>

## Installation

## Overview

T4rg3ts is a comprehensive Dark Souls-style lock-on targeting system for OpenMW that provides precise enemy tracking, visual target indicators, and intelligent combat automation.
With T4rgets, an enemy's health is displayed according to the color of the icon. Each enemy has five phases from full to wounded to dead, with the actual icon color mixing between the two nearest colors. This means you always know how healthy the enemy is in combat!

T4rg3t5 comes with a full suite of 31 icons to use for lock-on indicators. Additionally, it's very easy to create new target lock icons for T4rg3t5 for your own mods or personal use.

Please make sure to assign a keybinding for T4rg3t5 to use, or the mod will be (mostly) useless.

### Core Features

#### Smart Target Acquisition

1. Automatic Target Selection: Finds the nearest valid enemy in your field of view

1. Line-of-Sight Checking: Ensures targets are actually visible and not behind obstacles

1. Flick Switching: Quickly change targets by flicking the mouse left or right

1. Combat Auto-Lock: Automatically locks onto enemies who initiate combat with you

#### Visual Target Indicators

1. Dynamic Lock Icons: Customizable target markers that scale with distance

1. Health-Based Coloring: Icon color changes based on enemy health status:

    - Full Health (100%+): Primary color

    - Very Healthy (80-100%): Mix with full health color

    - Healthy (60-80%): Distinct healthy state

    - Wounded (40-60%): Noticeable wound indication

    - Very Wounded (20-40%): Critical condition warning

    - Dead/Dying (0-20%): Near death state

1. Hit Feedback: Icons "bounce" when you successfully hit locked targets

1. Distance Scaling: Icons grow/shrink based on target distance

#### Intelligent Automation

1. Auto-Facing: Character automatically turns to face locked targets

1. Weapon Awareness: Only allows locking when wielding weapons

1. Smart Target Management:

    - Automatically switches targets when current target dies

    - Breaks lock when targets move out of sight

    - Releases lock when sheathing weapons

## For Modders

### Making New Icons

Making new Icons for T4rg3t5 is dead simple. The recommended way is to use GIMP, but any image editor should be able to handle this task.

1. First, pick or create a source image.
1. Open it in GIMP
1. Use Colors -> Threshold to flatten all the colors to pure black/white. Make sure to adjust the values to find ones that fit your image.
1. Either delete the black pixels, or lighten them, using Colors -> Levels to increase the white levels of these pixels, so that the script's coloration works better.
1. Use Image -> Scale Image to resize the image to 128x128
1. Export as DDS without mipmaps OR compression to a subfolder, `textures/s3/crosshair`
