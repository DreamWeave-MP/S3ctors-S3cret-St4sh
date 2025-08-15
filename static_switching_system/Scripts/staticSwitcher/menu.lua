local async = require 'openmw.async'
local core = require 'openmw.core'
local menu = require 'openmw.menu'
local storage = require 'openmw.storage'
local vfs = require 'openmw.vfs'

local I = require 'openmw.interfaces'

---@param path string normalized VFS path referring to a mesh replacement map
local function getPathBaseName(path)
    ---@type string
    local baseName
    for part in string.gmatch(path, "([^/]+)") do
        baseName = part
    end

    for split in baseName:gmatch('([^.]+)') do
        return split
    end
end

local meshReplacementModules, meshReplacementModulesLen = {}, 0

for meshReplacementsPath in vfs.pathsWithPrefix('scripts/staticSwitcher/data') do
    meshReplacementModulesLen = meshReplacementModulesLen + 1
    local baseName = getPathBaseName(meshReplacementsPath)
    if baseName ~= 'example' then
        meshReplacementModules[meshReplacementModulesLen] = baseName
    end
end

I.Settings.registerPage {
    key = 'StaticSwitcherPage',
    l10n = 'StaticSwitcher',
    name = 'Static Switching System',
    description = 'StaticSwitchingSystemDesc'
}

I.Settings.registerGroup {
    key = 'SettingsStaticSwitcher',
    l10n = 'StaticSwitcher',
    page = 'StaticSwitcherPage',
    name = 'StaticSwitcherSettings',
    description = '',
    permanentStorage = true,
    settings = {
        {
            key = 'StaticSwitcherEnableGlobal',
            renderer = 'checkbox',
            name = 'StaticSwitcherEnableGlobalReplacementsName',
            description = 'StaticSwitcherEnableGlobalDesc',
            argument = {
                l10n = 'StaticSwitcher',
                trueLabel = 'StaticSwitcherTrueLabel',
                falseLabel = 'StaticSwitcherFalseLabel',
            }
        },
        {
            renderer = 'select',
            key = 'StaticSwitcherModuleSelect',
            name = 'StaticSwitcherModuleSelection',
            description = 'StaticSwitcherModuleSelectionDesc',
            default = meshReplacementModules[1] or 'WTF',
            argument = {
                l10n = 'StaticSwitcher',
                items = meshReplacementModules,
            },
        },
        {
            key = 'StaticSwitcherDisableModule',
            renderer = 'checkbox',
            name = 'StaticSwitcherModuleDisableButton',
            description = 'StaticSwitcherModuleDisableDesc',
            argument = {
                l10n = 'StaticSwitcher',
                trueLabel = 'StaticSwitcherTrueLabel',
                falseLabel = 'StaticSwitcherFalseLabel',
            }
        }
    }
}

local settingsGroup = storage.playerSection('SettingsStaticSwitcher')
if settingsGroup:get('StaticSwitcherDisableModule') then settingsGroup:set('StaticSwitcherDisableModule', false) end

settingsGroup:subscribe(
    async:callback(
        function(_, key)
            if menu.getState() ~= menu.STATE.Running then return end

            if not key or key == 'StaticSwitcherDisableModule' then
                local targetModule = settingsGroup:get('StaticSwitcherModuleSelect')
                core.sendGlobalEvent('StaticSwitcherRemoveModule', targetModule)
            elseif not key or key == 'StaticSwitcherEnableGlobal' then
                if settingsGroup:get('StaticSwitcherEnableGlobal') then
                    core.sendGlobalEvent('StaticSwitcherRunGlobalFunctions')
                end
            end
        end
    )
)

return {
    eventHandlers = {
        StaticSwitcherRequestGlobalFunctions = function()
            if not settingsGroup:get('StaticSwitcherEnableGlobal') then return end
            core.sendGlobalEvent('StaticSwitcherRunGlobalFunctions')
        end,
        StaticSwitcherMenuRemoveModule = function(moduleName)
            if menu.getState() ~= menu.STATE.Running then return end

            local description = ('Removed StaticSwitcher module: %s at %s'):format(moduleName, core.getRealTime())
            menu.saveGame(description, 'Removed Static Switcher Module ' .. moduleName)
            menu.quit()
        end
    }
}
