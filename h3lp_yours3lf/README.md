# H3lp Yours3lf

Sometimes, you just have to h3lp yours3lf.

H3lp Yours3lf is a collection of scripting modules built for openmw. It contains multiple individual interfaces which authors can use to improve performance and ergonomics in their OpenMW-Lua scripts. Additionally, H3lp Yours3lf includes some helper functions for more exotic behaviors, such as detecting the context in which a given script is running.

## Installation

Nothing else is necessary! Hopefully, you have installed this mod as a dependency of another one that needs it.

#### Modules

##### S3lf

 s3lf is a replacement for OpenMW's built-in `self` module. It contains all the same contents but saves some footguns in the API and makes certain calls more precise on your behalf, alongside being easier to introspect. This mod should be installed purely as a dependency of others, as it adds nothing on its own except an interface which other scripts may make use of. For scripters, read below to learn about how and why to make use of the `s3lf` interface.

###### Using the S3lf Module

It's a fairly common convention in Lua to use the keyword `self` in a table when it... needs to reference itself in some way. OpenMW-Lua subtly teaches you to use its own module `openmw.self` instead, which can break attempts to use the `self` keyword normally, induce subtle bugs, or just be plain weird. Additionally, the API overall is often considered too spread out or confusing to be easily used, with things like health being accessed like `self.type.stats.dynamic.health(self)`. The `s3lf` module will save you these painful indexes with hidden implementation footguns, *and* allow you to use the `self` keyword as you normally would. Compare the normal version to `s3lf.health.current`.

Any api function which takes `self.object` as its first argument now implicitly passes the SelfObject as the first argument. If the SelfObject is the only argument, then you do not even need to bother with the function call. The userdata values returned by the API are cached where possible and all flattened into the `s3lf` object. To best get a grip on it, just try using it in the Lua console!

Some specific notes on how fields are changed:

- `self.type` is no longer accessible, as all fields inside of the `.type` field are flattened into `s3lf`
- Attributes, skills, level, and dynamic stats are all directly accessible via `s3lf`
- All fields of `self.type.stats.ai` are available under `s3lf`
- All fields from the original `GameObject` type are available under `s3lf`
- All fields of the associated record are available under `s3lf`. Due to a name collision, the `.id` field of `s3lf` will always refer to `GameObject.id` and not the record's id. use `s3lf.recordId` to find the object's record name instead of the instance id.
- All fields of the animation module are available under `s3lf`
- A new `.record` field is added to replace the `.record` function, which returns `self.type.records[self.recordId]`
- An additional function, `ConsoleLog` is added which will display a given message in the `~` console from any context.

`s3lf` is exported as an interface and immediately usable: `local s3lf = require('openmw.interfaces').s3lf`

To use it in the lua console, make sure the script is installed and enabled, then use `luap` or `luas` and try the following:

```lua
            s3lf = I.s3lf
            s3lf.record.hair
            s3lf.health.base, s3lf.strength.base, s3lf.acrobatics.base, s3lf.speed.modified
```

`s3lf` objects may also construct other `s3lf` objects from normal `GameObject`s to gain the same benefits:

```lua
            local weapon = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedRight)
            local weaponType = s3lf.From(weapon).record.type
```

`s3lf` also tracks combat targets on players, using the built-in openmw event, `OMWMusicCombatTargetsChanged`. All combat targets are stored in the table `s3lf.combatTargets`, and additionally the function `s3lf.isInCombat()` may be used to quickly determine whether a fight is currently happening. When a combat target is added or removed, either the event `S3CombatTargetAdded` or `S3CombatTargetRemoved` is sent to the player, with the actor whom is added or removed being the only argument provided to downstream eventHandlers.

```lua
Additionally, s3lf objects provide a couple more convenience features to ease debugging and type checking respectively. A new function, `objectType`, is added to all objects which can be represented as a `s3lf`. For example:
            s3lf = I.s3lf
            s3lf.objectType()
            npc
```

All object types are represented as simple (lowercase) strings that you'd intuitively expect them to be, eg `npc`, `miscellaneous`, `weapon`, and so on.

Every `s3lf` object also includes a `display()` method, which will show a neatly-formatted output of all fields and functions currently used by this `s3lf` object:

```lua
            luap
            I.s3lf.display()
            S3GameGameSelf {
             Fields: {  },
             Methods: { From, display, objectType },
             UserData: { gameObject = openmw.self[object@0x1 (NPC, "player")], health = userdata: 0x702f9c0449e0, magicka = userdata: 0x702f81068130, record = ESM3_NPC["player"], shortblade = userdata: 0x702f62f9b350, speed = userdata: 0x702f62f40580 }
            }
```

`s3lf` objects may call the display method anywhere they see fit, but the result will only be visible if a player is nearby (as it is printed to the console directly, using the `nearby` module to locate nearby players.)

If your mod uses the `s3lf` interface and it is not available, it is recommended you link back to the [mod page](https://modding-openmw.gitlab.io/s3ctors-s3cret-st4sh/s3lf) in your error outputs so the user can get ahold of it themselves.

##### ProtectedTable

A construct designed to make it easy to bind a game system, to an OpenMW settings group. This makes it easy, for example, to make a global setting group which scales actor health and reference it in all scripts with concise notation. For example:

```lua
---@class CameraManager:ProtectedTable
---@field NoThirdPerson boolean
---@field PitchLocked boolean
---@field CursorCamPitch number configured pitch lock
local CameraManager = I.S3ProtectedTable.new {
  logPrefix = ModInfo.logPrefix,
  inputGroupName = 'SettingsGlobal' .. ModInfo.name .. 'MoveTurnGroup',
}

---@param dt number deltaTime
---@param Managers ManagementStore
function CameraManager:onFrameEnd(dt, Managers)
    CameraManager:updateDelta()

    if self.NoThirdPerson and camera.getMode() == camera.MODE.FirstPerson then
        camera.setMode(camera.MODE.ThirdPerson)
    end
end
```

ProtectedTables are usable in all contexts, except for `MENU`. Additionally, you may use `I.S3ProtectedTable.help` through the in-game (lua) console at any time for a detailed description of its usage. They will always be up-to-date with the settings group they're built on, as they contain a built-in subscribe function which will sync the values. If you wish, it is possible to override this subscribe function by using the `subscribeHandler` parameter of the constructor. subscribeHandler functions must match the `ShadowTableSubscriptionHandler` type definition.

ProtectedTables additionally come with a __tostring method that will show the manager name and all functions and methods associated with it. When building a script around a ProtectedTable, you may add as many new functions as you wish, but you may not add non-function fields. Additionally, to prevent invalidating the setting values the table tracks, the script will actually throw an error if you attempt to write directly to the table. To counteract this, all ProtectedTables include a `state` table which you may write to, and overwrite completely. The reason for this design is to allow flexible access to settings and to override each available function in the ProtectedTable on a case-by-case basis. If you create a protectedTable and use it as an interface, downstream modders may override the individual functions at their leisure without having to override your entire Interface.

Finally, due to their nature, please keep in mind that ProtectedTables only work with global setting groups, not player ones. This is to ensure that all possible gameObjects have access to the various values in each group.

##### ScriptContext

Provides an enum describing script contexts and a function to return the current one. Used by the LogMessage Function. Handy for when you would like for a given script or function to be usable regardless of what script context it is being ran in. ScriptContext is not available through an interface and must be `require`d directly, since interfaces are naturally scopes anyway, and this is a somewhat niche usage.

Example:

```lua
  local ScriptContext = require 'scripts.s3.scriptContext'
  local currentContext = ScriptContext.get()

  if currentContext == ScriptContext.Types.Player then
        print("I'm a player script!")
  elseif currentContext == ScriptContext.Types.Global then
        print("I'm a global script!")
  end
```

##### LogMessage

Emits a message to the `~` console from any context. Takes one argument. Re-exported through the `s3lf` module under the name `ConsoleLog`.

Example:

```lua
-- S3lf interface
Lua[Player] I.s3lf.ConsoleLog(('Hai from %s!'):format(I.s3lf.recordId))
Hai from player!

Lua[Player] exit()
Lua mode OFF
> luas
Lua mode ON, use exit() to return, help() for more info
Context: Local[object0x4001134 (NPC, "SW_HungoxSteward")]
Lua[sw_hungoxsteward] I.s3lf.ConsoleLog(('Hai from %s!'):format(I.s3lf.recordId))
```

```lua
-- standalone
local LogMessage = require 'scripts.s3.logmessage'
LogMessage(('Hai From %s'):format(I.s3lf.recordId))
```
