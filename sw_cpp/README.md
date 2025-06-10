# Starwind Community Patch Project

<h1 style="font-size: 1.5em;text-align: center;font-style: italic;padding-top: 45px;padding-bottom: 45px;">Brought to you by the Starwind Team and all the players on <a href="https://discord.gg/wcMj2b2svh">The Starwind Initiative</a></h1>

The Starwind Community patch project was born as a fix for crashes we found after someone made a [bunch of normal maps for everything](https://www.nexusmods.com/morrowind/mods/52567), including Starwind. Technically, these crashes are an engine bug, but it's also because the meshes are broken as well. Thus, SW_CPP was born.

Over time as The Starwind Initiative matured, we collected lots of minor bug fixes we needed to implement for multiplayer and wanted to make sure they were available to all Starwind players. Everything built here is available in the [Starwind-Builder](https://gitlab.com/modding-openmw/Starwind-Builder) repo, which is also used for deploying all content patches for TSI.

Community Patch Project also now includes a replacement file for Lua scripts to make their default layout colors look better. This means better compatibility with fancy script mods for Morrowind, basically. Also, a new and improved font, `Oxanium-SemiBold` has been added. Starwind's UI should look better than ever with CPP! Additionally, the `galactic-basic` font has been added as a replacement for daedric fonts.

## Installation

1. Add the following lines to your openmw.cfg to enable the Oxanium and Galactic Basic fonts:

``` toml
fallback=Fonts_Font_0,oxanium-semibold
fallback=Fonts_Font_2,galactic-basic
```

<div align="center"> <img src="../img/modathonbanner2024.png" alt="Modathon 2024" /> </div>

## Credits

Author: **S3ctor**  
All code was written by Dave Corley under the GPL3 license.  
Please enjoy my mod, hack away as you please, and respect the freedoms of your fellow modders and players in the meantime.

- Special Thanks to:

Ignatious  

SkoomaBreath  

RymanTheGreat  

Everyone who's ever played Starwind, or on TSI  
