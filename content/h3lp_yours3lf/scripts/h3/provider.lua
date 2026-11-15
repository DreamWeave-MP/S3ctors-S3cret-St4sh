---@omw-context menu|player

local ScriptContext = require 'scripts.s3.scriptContext'
local CurrentContext = ScriptContext.get()

local H3UI = require 'scripts.h3.ui'
local Input = require 'scripts.h3.input'
local updateQueue = require 'scripts.h3.ui.updateQueue'

local engineHandlers = {
  onFrame = updateQueue.flush,
}

if CurrentContext == ScriptContext.Types.Menu then
  ---@omw-context-next menu
  require 'scripts.h3.settings'

  ---@omw-context-next menu
  local InputPage = require 'scripts.h3.inputPage'
  InputPage.register()
  engineHandlers.onControllerButtonPress = InputPage.onControllerButtonPress
  engineHandlers.onKeyPress = InputPage.onKeyPress
  engineHandlers.onMouseButtonPress = InputPage.onMouseButtonPress
else
  Input.registerActions()
end

return {
  interfaceName = 'H3UI',
  interface = H3UI,
  engineHandlers = engineHandlers,
}
