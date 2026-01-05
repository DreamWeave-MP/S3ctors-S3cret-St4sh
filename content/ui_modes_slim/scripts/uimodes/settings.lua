local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local settings = storage.playerSection('SettingsUiModesSmol')

local M = {}

local function boolSetting(key, default)
    M[key] = function() return settings:get(key) end
    return {
        key = key,
        renderer = 'checkbox',
        name = key,
        description = key .. 'Description',
        default = default,
    }
end

local function floatSetting(key, default)
    M[key] = function() return settings:get(key) end
    return {
        key = key,
        renderer = 'number',
        name = key,
        description = key .. 'Description',
        default = default,
    }
end

I.Settings.registerPage({
    key = 'UiModes',
    l10n = 'UiModes',
    name = 'UiModes',
    description = 'UiModesDescription',
})

I.Settings.registerGroup({
    key = 'SettingsUiModesSmol',
    page = 'UiModes',
    l10n = 'UiModes',
    name = 'Settings',
    permanentStorage = true,
    settings = {
        boolSetting('uiModesShortcuts', true),
        boolSetting('allowOpenMap', true),
        boolSetting('autoDrawWeapon', true),
        boolSetting('autoDrawWeaponOnCombatStart', false),
        boolSetting('autoSheathWeaponOnCombatEnd', false),
        boolSetting('continueAttackingWhileHeld', true),
        boolSetting('rotateCameraInInventory', true),
        boolSetting('rotateCameraInDialogs', false),
        floatSetting('rotateCameraSpeed', 2.0),
    },
})

return M
