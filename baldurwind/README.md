# Baldurwind

Baldurwind is a mechanical total conversion for OpenMW. More features are planned, but in essence, Baldurwind's goal is to convert Morrowind into turn-based, party RPG!

The idea was inspired due to the sheer popularity of Baldur's Gate 3 (obviously) and some of my longstanding grievances with the combat system. There's not enough audiovisual feedback in typical Morrowind combat, so instead of removing hit chance (as I did in another mod), I designed some mechanics which enable the game to (in my opinion) more properly lean into that idea.

## Usage

Baldurwind is specifically designed to be compatible with whatever the latest stable release of OpenMW is. At the time of this writing, that is 0.48. To the best of my knowledge, Baldurwind still works on development builds as of commit cd116ebe5f .

Otherwise, just follow the installation instructions below and be ready for a hard time. Turn-based Morrowind is extremely punishing and necessitates a proper build, and having friends along helps quite a bit. If you don't typically play with followers or companions, you probably will now!

Pairs great with [AttendMe](https://gitlab.com/urm-openmw-mods/attend-me/-/tree/0.49?ref_type=heads) and [OpenNeverMind](https://modding-openmw.gitlab.io/opennevermind/).

<!-- Insert gif here when I feel like it -->

#### Installation

1. Download the mod from [this URL](https://modding-openmw.gitlab.io/s3ctors-s3cret-st4sh/baldurwind)
1. Extract the zip to a location of your choosing, examples below:

        # Windows
        C:\games\OpenMWMods\baldurwind

        # Linux
        /home/username/games/OpenMWMods/baldurwind

        # macOS
        /Users/username/games/OpenMWMods/baldurwind

1. Add the appropriate data path to your `opemw.cfg` file (e.g. `data="C:\games\OpenMWMods\baldurwind"`)
1. Add `content=baldurwind.omwaddon` to your load order in `openmw.cfg` or enable them via OpenMW-Launcher

<p align="center">
  <img src="../img/modathonbanner2024.png" alt="Modathon 2024" />
</p>

<div id="credits" style="text-align: center;">

#### Credits

Author: **S3ctor**

All code was written by Dave Corley under the GPL3 license. Please enjoy my mod, hack away as you please, and respect the freedoms of your fellow modders and players in the meantime.

</div>
