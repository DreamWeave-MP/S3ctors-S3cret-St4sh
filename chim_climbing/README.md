# Chim Climbing

CHIM Climbing is my own long-awaited attempt at porting the movement mechanics from the classic [CHIM]() mod I worked on many years ago into OpenMW-Lua. The climbing module is strictly related to, well, climbing!
This first version focuses exclusively on the concept of mantling, You can now climb and clamber over surfaces which you wouldn't have previously had access to. 

The next major release of this mod will include a full Daggerfall-style climbing system, as was implemented in the original mod, but far less jank.

# Usage

Once installed, just go jump around! 
Surfaces you can mantle over can be scaled by simply walking up to them and jumping. You may mantle any surface which is about 1.5 times your character's height - or, in other words, if it's within arm's reach. You can mantle surfaces while jumping or falling, so you can use the feature to catch yourself, or jump and then mantle over surfaces which're otherwise too high!

### Installation

1. Download the mod from [this URL](https://modding-openmw.gitlab.io/s3ctors-s3cret-st4sh/chim_climbing)
1. Extract the zip to a location of your choosing, examples below:

        # Windows
        C:\games\OpenMWMods\chim_climbing

        # Linux
        /home/username/games/OpenMWMods/chim_climbing

        # macOS
        /Users/username/games/OpenMWMods/chim_climbing

1. Add the appropriate data path to your `opemw.cfg` file (e.g. `data="C:\games\OpenMWMods\chim_climbing"`)
1. Add `content=Chim_Climbing.omwscripts` to your load order in `openmw.cfg` or enable them via OpenMW-Launcher

#### Credits

Author: **Dave Corley**

- Brought to you by the generosity of the OpenMW Community.