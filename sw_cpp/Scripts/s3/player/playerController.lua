local core = require('openmw.core')
local self = require('openmw.self')

return {
  engineHandlers = {
    onTeleported = function()
      core.sendGlobalEvent('SW4_PlayerCellChanged', { player = self.object, prevCell = self.cell.name })
    end
  }
}
