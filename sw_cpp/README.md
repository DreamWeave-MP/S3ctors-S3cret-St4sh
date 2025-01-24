# Starwind Community Patch Project

<h2 style="font-size: 1.5em;text-align: center;font-style: italic;padding-top: 45px;padding-bottom: 45px;">Brought to you by the Starwind Team and all the players on <a href="https://discord.gg/wcMj2b2svh">The Starwind Initiative</a></h2>

The Starwind Community patch project was born as a fix for crashes we found after someone made a [bunch of normal maps for everything](https://www.nexusmods.com/morrowind/mods/52567), including Starwind. Technically, these crashes are an engine bug, but it's also because the meshes are broken as well. Thus, SW_CPP was born.

Over time as The Starwind Initiative matured, we collected lots of minor bug fixes we needed to implement for multiplayer and wanted to make sure they were available to all Starwind players. Everything built here is available in the [Starwind-Builder](https://gitlab.com/modding-openmw/Starwind-Builder) repo, which is also used for deploying all content patches for TSI.

Community Patch Project also now includes a replacement file for Lua scripts to make their default layout colors look better. This means better compatibility with fancy script mods for Morrowind, basically. Also, a new and improved font, `Oxanium-SemiBold` has been added. Starwind's UI should look better than ever with CPP!

#### Installation

1. Download the mod from [this URL](https://modding-openmw.gitlab.io/s3ctors-s3cret-st4sh/sw_cpp)
1. Extract the zip to a location of your choosing, examples below:

        # Windows
        C:\games\OpenMWMods\sw_cpp

        # Linux
        /home/username/games/OpenMWMods/sw_cpp

        # macOS
        /Users/username/games/OpenMWMods/sw_cpp

1. Add the appropriate data path to your `opemw.cfg` file (e.g. `data="C:\games\OpenMWMods\sw_cpp"`)
1. Add `content=Starwind Community Patch Project.omwaddon` to your load order in `openmw.cfg` or enable them via OpenMW-Launcher
1. Add the following lines to your openmw.cfg to enable the Oxanium font:

``` toml
fallback=Fonts_Font_0,oxanium-semibold
fallback=Fonts_Font_2,oxanium-semibold
```

<div align="center"> <img src="../img/modathonbanner2024.png" alt="Modathon 2024" /> </div>

<div id="credits" style="text-align: center;">

#### Credits

Author: **S3ctor**

All code was written by Dave Corley under the GPL3 license. Please enjoy my mod, hack away as you please, and respect the freedoms of your fellow modders and players in the meantime.

</div>
