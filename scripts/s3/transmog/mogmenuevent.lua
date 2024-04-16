local I = require('openmw.interfaces')

local function mogMenuEvent(mogArgs)
  for aliasName, menuItem in pairs(I.transmogActions.MenuAliases()) do
    if aliasName ~= 'original inventory'
      and aliasName ~= 'current inventory'
      and aliasName ~= 'equipment'
      and menuItem.userData
      and menuItem.userData.mogMenuEvent
      and type(menuItem.userData.mogMenuEvent) == 'function'
      and (not mogArgs.targetName or mogArgs.targetName == aliasName) then
      menuItem.userData.mogMenuEvent(mogArgs)
    end
  end
end

return {
  eventHandlers = {
    mogMenuEvent = mogMenuEvent,
  }
}
