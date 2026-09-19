---@omw-context menu|player
---@module 'scripts.h3.components.eventHandlers'

local async = require 'openmw.async'

local Assert, Type = assert, type

---@param events table<string, function|openmw.async.Callback>
---@param name string
---@param handler fun(...: H3UI.LuaValue): boolean?
---@param defaultResult? boolean
---@return nil
local function add(events, name, handler, defaultResult)
  Assert(Type(events) == 'table', 'H3 event composition requires an events table')
  Assert(Type(name) == 'string' and name ~= '', 'H3 event composition requires an event name')
  Assert(Type(handler) == 'function', 'H3 event composition requires a handler')
  local previous = events[name]
  events[name] = async:callback(
    ---@param ... H3UI.LuaValue
    ---@return boolean?
    function(...)
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
