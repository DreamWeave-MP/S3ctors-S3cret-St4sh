---@omw-context menu|player

local ScriptContext = require 'scripts.s3.scriptContext'
local CurrentContext = ScriptContext.get()

local H3UI = require 'scripts.s3.ui'

if CurrentContext == ScriptContext.Types.Menu then
  ---@omw-context-next menu
  require 'scripts.s3.h3uiSettings'
end

---@class openmw.interfaces.H3UI: H3UI

---@class openmw.interfaces
---@field H3UI? openmw.interfaces.H3UI

return {
  interfaceName = 'H3UI',
  interface = H3UI,
}
