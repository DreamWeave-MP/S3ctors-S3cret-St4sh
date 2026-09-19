---@omw-context menu|player

local eventHandlers = require 'scripts.h3.components.eventHandlers'

local Next = next

---@param events? table<string, function>
---@param onActivate fun(event: openmw.ui.MouseEvent, layout: openmw.ui.Layout): boolean?
---@return table<string, function>?
local function activationEvents(events, onActivate)
  local result = {}
  if events then
    for name, callback in Next, events do
      result[name] = callback
    end
  end

  if onActivate then eventHandlers.add(result, 'mouseClick', onActivate, true) end

  if Next(result) then return result end
end

return activationEvents
