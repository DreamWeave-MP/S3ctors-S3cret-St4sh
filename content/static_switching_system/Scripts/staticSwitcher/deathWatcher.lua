---@omw-context local

local core = require 'openmw.core'
local self = require 'openmw.self'

return {
  eventHandlers = {
    Died = function() core.sendGlobalEvent('StaticSwitcherActorDied', self.object) end,
  },
}
