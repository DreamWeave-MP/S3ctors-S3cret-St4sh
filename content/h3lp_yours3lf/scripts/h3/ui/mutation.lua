---@omw-context menu|player
---@module 'scripts.h3.ui.mutation'

local ui = require 'openmw.ui'

local Assert, Type = assert, type

local UiContent = ui.content

---@param layout openmw.ui.Layout
---@param children openmw.ui.LayoutOrElement[]
---@param invalidate? fun(): nil
---@return nil
local function setChildren(layout, children, invalidate)
  Assert(Type(layout) == 'table', 'H3 UI setChildren layout must be a table')
  Assert(Type(children) == 'table', 'H3 UI setChildren children must be a table')

  layout.content = UiContent(children)

  if invalidate then invalidate() end
end

---@generic R
---@param callback? fun(...): R
---@param invalidate fun(): nil
---@return fun(...): R|nil
local function invalidateAfter(callback, invalidate)
  if not callback then return invalidate end

  return
    ---@param ... H3UI.LuaValue
    ---@return H3UI.LuaValue
    function(...)
    local result = callback(...)

    invalidate()

    return result
  end
end

return {
  setChildren = setChildren,
  invalidateAfter = invalidateAfter,
}
