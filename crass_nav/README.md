# Crassified Navigation

<style>

ul.toc {
    list-style-image: url('/img/crassius.png');
}

</style>

<div align="center"> <img src="../img/crassnav-map.png" alt="Crassius Curio is on the Map." /> </div>

<h2 style="font-size: 1.5em;text-align: center;font-style: italic;padding-top: 45px;padding-bottom: 45px;">Uncle Crassius Doesn't Need A Map. Why Should You?</h2>

Crassified Navigation is a simple mod, but meant to be as cursed as possible. It's effectively an OpenMW port of the mod `Get Lost`, spawned by a user request in MMC. But it comes with an extra cursed twist, being that as much of the operative Lua code as possible is embedded directly into the mod's omwaddon.

Nevertheless, it works just as well and easily as anything else.

#### Installation

1. Download the mod from [this URL](https://modding-openmw.gitlab.io/s3ctors-s3cret-st4sh/crass-nav)
1. Extract the zip to a location of your choosing, examples below:

        # Windows
        C:\games\OpenMWMods\crass-nav

        # Linux
        /home/username/games/OpenMWMods/crass-nav

        # macOS
        /Users/username/games/OpenMWMods/crass-nav

1. Add the appropriate data path to your `opemw.cfg` file (e.g. `data="C:\games\OpenMWMods\crass-nav"`)
1. Add `content=Crassified Navigation.omwaddon` to your load order in `openmw.cfg` or enable them via OpenMW-Launcher
1. Add the following to your [settings.cfg](https://openmw.readthedocs.io/en/stable/reference/modding/paths.html)

        [Windows]
        map hidden = true

<div id="credits" style="text-align: center;">

#### Credits

Author: **S3ctor**

All code was written by Dave Corley under the GPL3 license. Please enjoy my mod, hack away as you please, and respect the freedoms of your fellow modders and players in the meantime.

</div>
