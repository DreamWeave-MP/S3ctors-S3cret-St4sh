local self = require('openmw.self')

local MenuAliases = require('scripts.s3.transmog.ui.menualiases')

local localHandlers = {
  engineHandlers = {
    onInputAction = {},
    onKeyPress = {},
    onKeyRelease = {},
    onMouseButtonPress = {},
    onMouseButtonRelease = {},
    onMouseWheel = {},
    onFrame = {},
    onUpdate = {},
    onInit = {},
    onConsoleCommand = {},
  },
  eventHandlers = {},
}

local function runAllHandlers(handlers, ...)
  for _, handler in pairs(handlers) do
    if type(handler) ~= 'function' then error("Provided a handler for a function but it was not a handler") end
    if type(...) == 'table' then
      handler(unpack(arg))
    else
      handler(...)
    end
  end
end

local globalHandlers = {
  interfaceName = 'transmogActions',
  interface = {
    MenuAliases = MenuAliases,
    MogMenuEvent = function(mogArgs)
      self:sendEvent('mogMenuEvent', mogArgs)
    end,
  },
  eventHandlers = {},
  engineHandlers = {
    onInputAction = function(...) runAllHandlers(localHandlers.engineHandlers.onInputAction, ...) end,
    onKeyPress = function(...) runAllHandlers(localHandlers.engineHandlers.onKeyPress, ...) end,
    onKeyRelease = function(...) runAllHandlers(localHandlers.engineHandlers.onKeyRelease, ...) end,
    onFrame = function(...) runAllHandlers(localHandlers.engineHandlers.onFrame, ...) end,
    onUpdate = function(...) runAllHandlers(localHandlers.engineHandlers.onUpdate, ...) end,
    onInit = function(...) runAllHandlers(localHandlers.engineHandlers.onInit, ...) end,
    onMouseButtonPress = function(...) runAllHandlers(localHandlers.engineHandlers.onMouseButtonPress, ...) end,
    onMouseButtonRelease = function(...) runAllHandlers(localHandlers.engineHandlers.onMouseButtonRelease, ...) end,
    onMouseWheel = function(...) runAllHandlers(localHandlers.engineHandlers.onMouseWheel, ...) end,
    onConsoleCommand = function(...) runAllHandlers(localHandlers.engineHandlers.onConsoleCommand, ...) end,
  },
}

local function extractHandlers(handlers)
  if type(handlers) ~= 'table' then error("Only tables are supported by the openmw interface") end
  for engineHandleKey, engineHandleTable in pairs(handlers) do
    if type(engineHandleTable) ~= 'table' then error("Only tables are supported by the openmw interface") end
    for handleName, handle in pairs(engineHandleTable) do
      if engineHandleKey == 'externalFunctions' then
        if type(handle) == 'function' then handle()
        else error("invalid content for externalFunctions")
        end
      elseif engineHandleKey == 'interface' or engineHandleKey == 'eventHandlers' then
        globalHandlers[engineHandleKey][handleName] = handle
      elseif engineHandleKey == 'engineHandlers' then
        if not localHandlers[engineHandleKey][handleName] then localHandlers[engineHandleKey][handleName] = {} end
        local destinationTable = localHandlers[engineHandleKey][handleName]
        destinationTable[#destinationTable + 1] = handle
      end
    end
  end
end

-- Settings Bindings are stored here
require('scripts.s3.transmog.settings')
-- Correlating actions are registered here
require('scripts.s3.transmog.actionregistrations')
-- standalone engineHandlers go here
extractHandlers(require('scripts.s3.transmog.enginehandlers.oninit'))
extractHandlers(require('scripts.s3.transmog.enginehandlers.hudinterceptor'))
-- standalone eventHandlers go here
extractHandlers(require('scripts.s3.transmog.actions'))
extractHandlers(require('scripts.s3.transmog.mogmenuevent'))

return globalHandlers
