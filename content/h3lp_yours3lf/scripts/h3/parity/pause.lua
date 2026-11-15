---@omw-context global

local world = require 'openmw.world'

local PauseTag = 'h3ui-parity'

return {
  eventHandlers = {
    ---@return nil
    H3UIParityPause = function() world.pause(PauseTag) end,

    ---@return nil
    H3UIParityUnpause = function() world.unpause(PauseTag) end,
  },
}
