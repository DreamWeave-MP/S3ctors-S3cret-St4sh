local input = require('openmw.input')
local Settings = require('openmw.interfaces').Settings

-- The only way to register the key bindings for input actions is with a settings menu,
-- So we *must* define an entire one
-- This is just the page name and description
Settings.registerPage {
    key = 's3_transmogMenu',
    l10n = 'TransmogrificationMenu',
    name = 'Transmog Menu',
    description = 'Settings for the Transmog Menu',
}

-- This is the group that will be used to register the action
-- The actual bound key value is the `default` value in the tables within settings table
Settings.registerGroup {
    key = 'Settingss3_transmogMenuGroup',
    page = 's3_transmogMenu',
    l10n = 'TransmogrificationMenu',
    name = 'Key Bindings',
    description = '',
    permanentStorage = true, -- Need to figure out exactly what this is
    settings = {
        {
            key = 'TransmogMenuKey',
            renderer = 'inputBinding',
            name = 'Open Glamour Menu',
            description = 'Key which opens the transmogrification menu',
            default = 'k',
            argument = {
              key = 'transmogMenuKey', -- The key here should match the key in the action table
              type = "action" -- And whether it's an action or trigger
            }
        },
        {
            key = 'TransmogMenuRotateRight',
            renderer = 'inputBinding',
            name = 'Rotate Right',
            description = 'Rotates the character to the right in the glamour menu',
            default = 'q',
            argument = {
              key = 'transmogMenuRotateRight', -- The key here should match the key in the action table
              type = "action" -- And whether it's an action or trigger
            }
        },
        {
            key = 'TransmogMenuRotateLeft',
            renderer = 'inputBinding',
            name = 'Rotate Left',
            description = 'Rotates the character to the left in the glamour menu',
            default = 'e',
            argument = {
              key = 'transmogMenuRotateLeft', -- The key here should match the key in the action table
              type = "action" -- And whether it's an action or trigger
            }
        },
        {
            key = 'TransmogMenuConfirm',
            renderer = 'inputBinding',
            name = 'Confirm Glamour',
            description = 'Confirms choices in the glamour menu',
            default = 'Space',
            argument = {
              key = 'transmogMenuConfirm', -- The key here should match the key in the action table
              type = "trigger" -- And whether it's an action or trigger
            }
        },
    },
}


-- This is the #ActionInfo table that will be used to register the action
-- The name appears in the settings menu along with the description
local actions = {
  {
    name = 'Open',
    l10n = 'Open', -- localization key; meant to be replaced by translation files
    description = '', -- description of the action
    type = input.ACTION_TYPE.Boolean, -- Actions can have bool, integer, or string values
    defaultValue = false,
    key = 'transmogMenuKey', -- This is not the key that will be used to bind the action,
    -- but rather the table key which is used to refer to it elsewhere
  },
  {
    name = 'Rotate Right',
    l10n = 'RotateRight',
    description = '',
    type = input.ACTION_TYPE.Boolean,
    defaultValue = false,
    key = 'transmogMenuRotateRight',
  },
  {
    name = 'Rotate Left',
    l10n = 'RotateLeft',
    description = '',
    type = input.ACTION_TYPE.Boolean,
    defaultValue = false,
    key = 'transmogMenuRotateLeft',
  },
}

local triggers = {
  {
    name = 'Confirm',
    l10n = 'Confirm',
    description = 'Confirms choices in the glamour menu',
    -- type = input.ACTION_TYPE.Boolean,
    defaultValue = false,
    key = 'transmogMenuConfirm',
  },
}

for _, actionInfo in ipairs(actions) do
  print("Registering action: " .. actionInfo.key)
  input.registerAction(actionInfo)
end

for _, triggerInfo in ipairs(triggers) do
  print("Registering trigger: " .. triggerInfo.key)
  input.registerTrigger(triggerInfo)
end
