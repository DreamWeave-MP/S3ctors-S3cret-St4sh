---@omw-context local

local MakeInterface = require 'scripts.s3.dr1p.interface'
local MakeRuntime = require 'scripts.s3.dr1p.runtime'

---@type DR1PRuntime
local Runtime = MakeRuntime(function() return false end)

---@type DR1PInterfaceDefinition
local PublicInterface = MakeInterface(Runtime)

return {
  eventHandlers = {},
  interfaceName = PublicInterface.interfaceName,
  interface = PublicInterface.interface,
}
