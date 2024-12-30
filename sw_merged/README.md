# Starwind Merged Plugin Project

<h2 style="font-size: 1.5em;text-align: center;font-style: italic;padding-top: 45px;padding-bottom: 45px;">Brought to you by the Starwind Team and all the players on <a href="https://discord.gg/wcMj2b2svh">The Starwind Initiative</a></h2>

The Starwind Merged Plugin Project began as an effort to consolidate the Starwind ESM files, to eventually make them entirely indepentent of Morrowind.esm and friends. At this time, the merged plugin project primarily focuses on the vanilla ESM files, with additional content stripped out. 

### WARNING
Please do not try to use the merged plugin project with any other Starwind mods. They are not presently compatible, but will be in the future!

Over time as The Starwind Initiative matured, we collected lots of minor bug fixes we needed to implement for multiplayer and wanted to make sure they were available to all Starwind players. Everything built here is available in the [Starwind-Builder](https://gitlab.com/modding-openmw/Starwind-Builder) repo, which is also used for deploying all content patches for TSI.

#### Installation

1. Download the mod from [this URL](https://modding-openmw.gitlab.io/s3ctors-s3cret-st4sh/sw_merged)
1. Extract the zip to a location of your choosing, examples below:

        # Windows
        C:\games\OpenMWMods\sw_merged

        # Linux
        /home/username/games/OpenMWMods/sw_merged

        # macOS
        /Users/username/games/OpenMWMods/sw_merged

1. Add the appropriate data path to your `opemw.cfg` file (e.g. `data="C:\games\OpenMWMods\sw_merged"`)
1. Add `content=Starwind.omwaddon` for multiplayer, or `content=Starwind_SP.omwaddon` for singleplayer, to your load order in `openmw.cfg` or enable them via OpenMW-Launcher

<div id="credits" style="text-align: center;">

#### Credits

Author: **S3ctor**

All code was written by Dave Corley under the GPL3 license. Please enjoy my mod, hack away as you please, and respect the freedoms of your fellow modders and players in the meantime.

Most of the changes and fixes in here were drawn from bug reports and other errata discovered by the TSI community. Thanks to all of you, as well <3

</div>
