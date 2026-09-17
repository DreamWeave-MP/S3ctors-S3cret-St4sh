---@omw-context menu|player

local async = require 'openmw.async'

local function activationEvents(events, onActivate)
  local result = {}
  for name, callback in next, events or {} do
    result[name] = callback
  end

  if onActivate then
    local previous = result.mouseClick
    result.mouseClick = async:callback(function(event, layout)
      local activationResult = onActivate(event, layout)
      if previous then
        local previousResult = previous(event, layout)
        if previousResult ~= nil then return previousResult end
      end
      if activationResult ~= nil then return activationResult end
      return true
    end)
  end

  return next(result) and result or nil
end

return activationEvents
