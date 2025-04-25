# S3LF

s3lf is a replacement for OpenMW's built-in `self` module. It contains all the same contents but saves some footguns in the API and makes certain calls more precise on your behalf, alongside being easier to introspect. This mod should be installed purely as a dependency of others, as it adds nothing on its own except an interface which other scripts may make use of. For scripters, read below to learn about how and why to make use of the `s3lf` interface.

## Installation

1. Download the mod from [this URL](https://modding-openmw.gitlab.io/s3ctors-s3cret-st4sh/s3lf)
1. Extract the zip to a location of your choosing, examples below:

        # Windows
        C:\games\OpenMWMods\s3lf

        # Linux
        /home/username/games/OpenMWMods/s3lf

        # macOS
        /Users/username/games/OpenMWMods/s3lf

1. Add the appropriate data path to your `opemw.cfg` file (e.g. `data="C:\games\OpenMWMods\s3lf"`)
1. Add the appropriate `content` entry to your `openmw.cfg` file: `content=s3lf.omwscripts`

## Using the Interface

It's a fairly common convention in Lua to use the keyword `self` in a table when it... needs to reference itself in some way. OpenMW-Lua subtly teaches you to use its own module `openmw.self` instead, which can break attempts to use the `self` keyword normally, induce subtle bugs, or just be plain weird. Additionally, the API overall is often considered too spread out or confusing to be easily used, with things like health being accessed like `self.type.stats.dynamic.health(self)`. The `s3lf` module will save you these painful indexes with hidden implementation footguns, *and* allow you to use the `self` keyword as you normally would. Compare the normal version to `s3lf.health.current`.

Any api function which takes `self.object` as its first argument now implicitly passes the SelfObject as the first argument. If the SelfObject is the only argument, then you do not even need to bother with the function call. The userdata values returned by the API are cached where possible and all flattened into the `s3lf` object. To best get a grip on it, just try using it in the Lua console!

`s3lf` is exported as an interface and immediately usable: `s3lf = require('openmw.interfaces').s3lf`

To use it in the lua console, make sure the script is installed and enabled, then use `luap` or `luas` and try the following:

            s3lf = I.s3lf
            s3lf.record.hair
            s3lf.health.base, s3lf.strength.base, s3lf.acrobatics.base, s3lf.speed.modified

`s3lf` objects may also construct other `s3lf` objects from normal `GameObject`s to gain the same benefits:

            local weapon = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedRight)
            local weaponType = s3lf.From(weapon).record.type

Additionally, s3lf objects provide a couple more convenience features to ease debugging and type checking respectively. A new function, `objectType`, is added to all objects which can be represented as a `s3lf`. For example:
            s3lf = I.s3lf
            s3lf.objectType()
            npc

All object types are represented as simple (lowercase) strings that you'd intuitively expect them to be, eg `npc`, `miscellaneous`, `weapon`, and so on.

Every `s3lf` object also includes a `display()` method, which will show a neatly-formatted output of all fields and functions currently used by this `s3lf` object:

            luap
            I.s3lf.display()
            S3GameGameSelf {
             Fields: {  },
             Methods: { From, display, objectType },
             UserData: { gameObject = openmw.self[object@0x1 (NPC, "player")], health = userdata: 0x702f9c0449e0, magicka = userdata: 0x702f81068130, record = ESM3_NPC["player"], shortblade = userdata: 0x702f62f9b350, speed = userdata: 0x702f62f40580 }
            }

`s3lf` objects may call the display method anywhere they see fit, but the result will only be visible if a player is nearby (as it is printed to the console directly, using the `nearby` module to locate nearby players.)

If your mod uses the `s3lf` interface and it is not available, it is recommended you link back to the [mod page](https://modding-openmw.gitlab.io/s3ctors-s3cret-st4sh/s3lf) in your error outputs so the user can get ahold of it themselves.

<div id="credits" style="text-align: center;">

## Credits

Author: **S3ctor**

All assets was made by Dave Corley under the GPL3 license. Please enjoy my mod, hack away as you please, and respect the freedoms of your fellow modders and players in the meantime.

Perhaps this was a bad idea, but until then - wheeeeee!

</div>
