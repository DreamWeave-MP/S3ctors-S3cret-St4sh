local Aliases = require('scripts.s3.transmog.ui.menualiases')

local function mogMenuEvent(mogArgs)
  for aliasName, menuItem in pairs(Aliases()) do
    if aliasName ~= 'original inventory'
    and aliasName ~= 'current inventory'
    and aliasName ~= 'equipment' then
      if menuItem.userData
        and menuItem.userData.mogMenuEvent
        and type(menuItem.userData.mogMenuEvent) == 'function' then
        menuItem.userData.mogMenuEvent(mogArgs)
      end
    end
  end
end

return {
  eventHandlers = {
    mogMenuEvent = mogMenuEvent,
  }
}
