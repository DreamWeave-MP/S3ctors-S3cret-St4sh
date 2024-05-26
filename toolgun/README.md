# Toolgun

Toolgun is a port of the eponymous swiss-army-revolver from Garry's Mod, purpose built for OpenMW. Fix floaters, rotate or scale objects to your liking, and then save them all back into a REAL mod you can share with the world after!

#### Credits

Author: **S3ctor & Epoch**

All code was written by S3ctor, NIF assets were converted by Epoch. Facepunch owns the original Toolgun mesh, and the SFX are sourced from [Valve](https://developer.valvesoftware.com/wiki/Mod_Content_Usage) in accordance with their mod content policy for non-commercial products.

## Usage

Please keep in mind that Toolgun requires OpenMW version 0.49, or at time of writing, a [development build](https://openmw.org/downloads/). Linux users may (probably) find development builds through their respective package managers, or failing all else, check out [JohnnyHostile's AppImages](https://modding-openmw.com/mods/openmw-appimage/) 

With that out of the way...

### It's TOOL TIME!

Toolgun offers a series of built-in tool modes for manipulating the game world around you. The entire table of tool modes is exposed through the interface `toolTime`, and modders may add their own tool modes through the member `tools`. In `mode.lua`, modders can find the base tool object for making their own.

Toolgun also offers a hand-built JSON serializer that players can use to make their own mods using it (almost) as simply as possible. Just go do some stuff with it, save your game, and hit F10. You'll have a single (possibly, extremely long) line of text you can copy into a new document. Do so, and name it `whatever.json`. Then you can feed that file into tes3conv (specifically, version [0.0.10](https://github.com/Greatness7/tes3conv/releases/tag/v0.0.10)), and now you've got a new mod.

How hard was that?

<!-- Insert gif here when I feel like it -->

#### Controls

Many controls in toolgun are mode-specific. However, there are a small handful of (hardcoded, I am not changing this until default keybinds are properly implemented) controls which apply to all modes:

1. 'X' - this increases the magnitude of your current edit mode. Eg, in `scale` mode, this will increase the amount by which the object's scale is increased.
2. 'Z' - this decreases the magnitude of your current edit mode. Eg, in `scale` mode, this will decrease the amount by which the object's scale is decrease.
3. Ctrl + 'X', 'Y', or 'Z' - this will lock certain actions to a given axis. For example, if using the `move` submode, pressing Ctrl-Z will ensure the object only moves on the Z axis. Not applicable for every submode.
4. Ctrl + 'C' - This cycles between tool modes.
   - Just pressing `C` will allow switching between *sub*modes of certain tools, such as clone.

Otherwise, just equip the toolgun and fire to activate it. 

#### Built-in Tools

1. Scale - Use this to increase or decrease the size of objects. WARNING: Scaling an object below 0.5 or above 2.0 violates Bethesda's usage of the ESP format, and so, extreme object scales will not work when trying to save them with tes3conv. Sorry.
2. Delete - Self-explanatory. 
   - However, if you press `Shift+Z` when using the delete submode, you can replace any object you remove accidentally.
3. Clone - Use this submode to copy or cut objects from the game world. Hold shift when shooting an object to delete the original and save it to your clipboard. 
   - Switch submodes to go between copy and paste
4. Grab - As it says on the tin, use the grab submode to move objects around. 
   - Free - No special constraints on object movement. Just drag the thing directly in front of your camera while left mouse is held down.
   - Axis - Use with the above mentioned axis-locking commands to restrict movement to a specific axis
   - Ground - Use this submode to drop objects onto the ground using a raycast. 
   - Point - In this submode, you can bind two objects together. First, shoot wherever you want your object to go. Then, shoot the object you want to move. The second object will snap to whatever the first point you shot was, and you can continue from there.
5. Rotate - Just rotates objects around. Quite unwieldy when rotating on all three axes, so highly recommended to lock rotation to a specific axis.

#### Installation

1. Download the mod from [this URL](https://modding-openmw.gitlab.io/s3ctors-s3cret-st4sh/)
1. Extract the zip to a location of your choosing, examples below:

        # Windows
        C:\games\OpenMWMods\toolgun

        # Linux
        /home/username/games/OpenMWMods/toolgun

        # macOS
        /Users/username/games/OpenMWMods/toolgun

1. Add the appropriate data path to your `opemw.cfg` file (e.g. `data="C:\games\OpenMWMods\toolgun"`)
1. Add `content=toolgun.omwaddon` to your load order in `openmw.cfg` or enable them via OpenMW-Launcher

<p align="center">
  <img src="../img/modathonbanner2024.png" alt="Modathon 2024" />
</p>
