---@omw-context menu|player

local eventHandlers = require 'scripts.s3.components.eventHandlers'

local function activationEvents(events, onActivate)
  local result = {}
  for name, callback in next, events or {} do
    result[name] = callback
  end

  if onActivate then
    eventHandlers.add(result, 'mouseClick', onActivate, true)
  end

  return next(result) and result or nil
end

return activationEvents
