---@omw-context menu

require 'openmw.interfaces'.Settings.registerPage {
    key = 'StaticSwitcherPage',
    l10n = 'StaticSwitcher',
    name = 'Static Switching System',
    description = 'StaticSwitchingSystemDesc'
}

local StaticSwitcherL10n = require 'openmw.core'.l10n('StaticSwitcher')
local menu = require 'openmw.menu'

return {
    eventHandlers = {
        ---@param moduleName string
        StaticSwitcherMenuRemoveModule = function(moduleName)
            ---@diagnostic disable-next-line: missing-parameter
            menu.saveGame(StaticSwitcherL10n('StaticSwitcherSaveDesc', { moduleName = moduleName }))
            menu.quit()
        end
    }
}
