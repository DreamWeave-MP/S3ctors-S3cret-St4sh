---@omw-context player

local ui = require 'openmw.ui'

return {
  engineHandlers = {
    onKeyPress = function(key)
      if key.symbol == 'x' then ui.showMessage 'Hello from Lua.' end
    end,
  },
}
