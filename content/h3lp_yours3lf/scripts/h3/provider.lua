---@omw-context menu|player

local ScriptContext = require 'scripts.s3.scriptContext'
local CurrentContext = ScriptContext.get()

local H3UI = require 'scripts.h3.ui'
local updateQueue = require 'scripts.h3.ui.updateQueue'

if CurrentContext == ScriptContext.Types.Menu then
  ---@omw-context-next menu
  require 'scripts.h3.settings'
end

return {
  interfaceName = 'H3UI',
  interface = H3UI,
  engineHandlers = {
    onFrame = updateQueue.flush,
  },
}
