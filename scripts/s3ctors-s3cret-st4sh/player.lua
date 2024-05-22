-- These lines load code from the OpenMW engine:
-- input: How we handle key presses and things like that
-- self: TODO
-- storage: We will be getting and setting settings values with this
-- ui: Lets us use the in game UI and build our own UIs
-- I: Load and use functionality from other mods, including parts of the OpenMW engine itself
local input = require("openmw.input")
local self = require("openmw.self")
local storage = require("openmw.storage")
local ui = require("openmw.ui")
local I = require("openmw.interfaces")

-- These lines set up a common variable (the mod ID, which cannot have spaces in it) and load a few more things from the OpenMW engine:
-- L: Use OpenMW's builtin localization handling to support multiple languages more easily
-- Player: Access the player object in the game
-- playerSettings: Access the player's settings
local MOD_ID = "s3ctors-s3cret-st4sh"
local L = require("openmw.core").l10n(MOD_ID)
local Player = require("openmw.types").Player
local playerSettings = storage.playerSection("SettingsPlayer" .. MOD_ID)

-- In OpenMW, mods can provide functionality to one another via "interfaces".
-- Those are defined below, but we set the version of the interface at the top.
local interfaceVersion = 1

-- This code sets up the settings page as found in the ESC >> Options >> Scripts menu in game:
-- key: The name of the settings page, it should be unique so using your mod ID is a good idea
-- l10n: The ID used for localization configuration, it's also a good idea to use your mod's name
-- name: The name of your mod, this can contain spaces
-- description: The localized description of your mod (hence the usage of `L("foo")` where `foo` is a key in the localization file)
I.Settings.registerPage {
    key = MOD_ID,
    l10n = MOD_ID,
    name = "%{name}",
    description = L("modDescription")
}

-- This adds an actual group of settings that are adjustable by the user:
-- key: The name of the settings group, it should be unique so using your mod ID is a good idea here as well
-- l10n: The ID used for localization configuration, it's also a good idea to use your mod's name
-- name: The name of your mod, this can contain spaces
-- page: The name of the page, if your settings has multiple pages TODO check this
-- description: The localized description of the settings group
-- permanentStorage: TODO check this
-- settings: A table (stuff inside braces {}) of tables representing each setting to make available
I.Settings.registerGroup {
    key = "SettingsPlayer" .. MOD_ID,
    l10n = MOD_ID,
    name = "%{name}",
    page = MOD_ID,
    description = "settingsDescription",
    permanentStorage = false,
    settings = {
        {
            -- TODO
            key = "showMessages",
            name = "showMsgs",
            default = true,
            renderer = "checkbox"
        }
    }
}

-- A simple function that shows the user a message in a box. It looks at a
-- player settings value that we make available and does different things
-- based on its value.
local function msg(str)
    if playerSettings:get("showMessages") then
        ui.showMessage(str)
    else
        ui.showMessage("Messages have been disabled, but you still get this one!")
    end
end

-- Function for handling key press events. If the player presses down the H key, we do stuff.
local function onKeyPress(key)
    if key.code == input.KEY.H then
        msg(string.format("Hello World! And Hello %s", Player.record(self).name))
    end
end

-- Function for handling key release events. If the player releases the H key, we do stuff.
local function onKeyRelease(key)
    if key.code == input.KEY.H then
        msg(string.format("Goodbye World! And Goodbye %s", Player.record(self).name))
    end
end

-- A function that other mods will use via the interfaces package (more explanation below).
local function SayHello()
    msg(string.format("Hello World! And Hello %s", Player.record(self).name))
end

return {
    -- This is how we load our code into the OpenMW engine to be ran at specific times.
    -- TODO: link to handlers list and etc
    engineHandlers = {
        onKeyPress = onKeyPress,
        onKeyRelease = onKeyRelease
    },
    -- This is how we make functionality from our mod available to other mods.
    -- The code in another mod might look like this:
    -- I.s3ctors-s3cret-st4sh.SayHello()
    interfaceName = MOD_ID,
    interface = {
        version = interfaceVersion,
        SayHello = SayHello
    }
}
