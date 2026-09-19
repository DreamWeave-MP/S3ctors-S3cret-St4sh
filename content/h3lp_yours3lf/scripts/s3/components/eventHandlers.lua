---@omw-context menu|player
---@module 'scripts.s3.components.eventHandlers'

local async = require 'openmw.async'

local function add(events, name, handler, defaultResult)
  assert(type(events) == 'table', 'H3 event composition requires an events table')
  assert(type(name) == 'string' and name ~= '', 'H3 event composition requires an event name')
  assert(type(handler) == 'function', 'H3 event composition requires a handler')
  local previous = events[name]
  events[name] = async:callback(function(...)
    local result = handler(...)
    if previous then
      local previousResult = previous(...)
      if previousResult ~= nil then return previousResult end
    end
    if result ~= nil then return result end
    return defaultResult
  end)
end

return {
  add = add,
}
