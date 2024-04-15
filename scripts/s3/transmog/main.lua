local deepPrint = require('scripts.s3.transmog.ui.common').deepPrint

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
    print(engineHandleKey)
    if type(engineHandleTable) ~= 'table' then error("Only tables are supported by the openmw interface") end
    -- deepPrint(engineHandleTable)
    for handleName, handle in pairs(engineHandleTable) do
      if engineHandleKey == 'externalFunctions' then
        if type(handle) == 'function' then handle()
        else error("invalid content for externalFunctions")
        end
      elseif engineHandleKey == 'interface' then
        print("Requested to add interface " .. handleName)
        globalHandlers.interface[handleName] = handle
      elseif engineHandleKey == 'eventHandlers' or engineHandleKey == 'engineHandlers' then
        print(engineHandleKey .. " " .. handleName)
        if not localHandlers[engineHandleKey][handleName] then localHandlers[engineHandleKey][handleName] = {} end
        local destinationTable = localHandlers[engineHandleKey][handleName]
        destinationTable[#destinationTable] = handle
      end
    end
  end
end

require('scripts.s3.transmog.settings')
extractHandlers(require('scripts.s3.transmog.test'))
extractHandlers(require('scripts.s3.transmog.actions'))
-- return(require('scripts.s3.transmog.actions'))


return globalHandlers
