local I = require('openmw.interfaces')

local function mogMenuEvent(mogArgs)
  for aliasName, menuItem in pairs(I.transmogActions.MenuAliases()) do
    if aliasName ~= 'original inventory'
      and aliasName ~= 'current inventory'
      and aliasName ~= 'equipment' then
      if not mogArgs.targetName or mogArgs.targetName == aliasName then
        if menuItem.userData
          and menuItem.userData.mogMenuEvent
          and type(menuItem.userData.mogMenuEvent) == 'function' then
          menuItem.userData.mogMenuEvent(mogArgs)
        elseif menuItem.mogMenuEvent and type(menuItem.mogMenuEvent) == 'function' then
          menuItem:mogMenuEvent(mogArgs)
        end
      end
    end
  end
end

return {
  eventHandlers = {
    mogMenuEvent = mogMenuEvent,
  }
}
