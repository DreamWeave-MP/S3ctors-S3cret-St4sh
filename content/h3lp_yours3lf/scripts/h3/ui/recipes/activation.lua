---@omw-context menu|player
---@module 'scripts.h3.ui.recipes.activation'

local async = require 'openmw.async'

local Next, SetMetatable, Type = next, setmetatable, type

local WeakKeys = { __mode = 'k' }

---@param onActivate? fun(item: H3UI.RecipeItem, index: integer, layout: openmw.ui.Layout): boolean?
---@return H3UI.ActivationState?
local function new(onActivate)
  if not onActivate then return end

  local targets = SetMetatable({}, WeakKeys)

  return {
    targets = targets,
    callback = async:callback(
      ---@param event openmw.ui.MouseEvent
      ---@param layout openmw.ui.Layout
      ---@return boolean
      function(event, layout)
      local target = targets[layout]
      if not target then return true end

      local previousResult
      if target.callback then previousResult = target.callback(event, layout) end

      local result = onActivate(target.item, target.index, layout)

      if previousResult ~= nil then return previousResult end
      if result ~= nil then return result end
      return true
    end),
  }
end

---@param activation? H3UI.ActivationState
---@param layout openmw.ui.Layout
---@param item H3UI.RecipeItem
---@param index integer
---@param copyLayout? boolean
---@return openmw.ui.Layout
local function bind(activation, layout, item, index, copyLayout)
  if not activation or Type(layout) ~= 'table' then return layout end

  if copyLayout then
    local source = layout
    local copied = {}

    for key, value in Next, source do
      copied[key] = value
    end

    ---@cast copied openmw.ui.Layout
    layout = copied
  end

  local events
  if copyLayout then
    events = {}

    for key, value in Next, layout.events or {} do
      events[key] = value
    end
  else
    events = layout.events or {}
  end

  activation.targets[layout] = {
    item = item,
    index = index,
    callback = events.mouseClick,
  }

  events.mouseClick = activation.callback
  layout.events = events

  return layout
end

return {
  bind = bind,
  new = new,
}
