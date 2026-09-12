---@omw-context local | global | player | load

---@type ScriptContext
local ScriptContext = require 'scripts.s3.scriptContext'
local CurrentContext = ScriptContext.get()

local select, tostring = select, tostring
local World, nearby, ui

if CurrentContext == ScriptContext.Types.Global then
  ---@omw-context-begin global
  World = require 'openmw.world'
  ---@omw-context-end global
elseif
  CurrentContext == ScriptContext.Types.Local or CurrentContext == ScriptContext.Types.Player
then
  ---@omw-context-begin local
  local types = require 'openmw.types'
  local Self = require 'openmw.self'

  if types.Player.objectIsInstance(Self) then
    ---@omw-context-begin player
    ui = require 'openmw.ui'
    ---@omw-context-end player
  else
    nearby = require 'openmw.nearby'
  end
  ---@omw-context-end local
end

--- Prints all arguments without adding a module-specific prefix.
---@param ... any
local function LogMessage(...)
  local arguments = { ... }
  for index = 1, select('#', ...) do
    arguments[index] = tostring(arguments[index])
  end
  local messageString = table.concat(arguments, '\t')

  if CurrentContext == ScriptContext.Types.Load then
    print(messageString)
  elseif CurrentContext == ScriptContext.Types.Global then
    assert(World, 'World is not available')

    for _, player in pairs(World.players) do
      player:sendEvent('S3LFDisplay', messageString)
    end
  else
    if CurrentContext == ScriptContext.Types.Player then
      ui.printToConsole(messageString, ui.CONSOLE_COLOR.Success)
    elseif CurrentContext == ScriptContext.Types.Local then
      for _, player in pairs(nearby.players) do
        player:sendEvent('S3LFDisplay', messageString)
      end
    end
  end
end

return LogMessage
