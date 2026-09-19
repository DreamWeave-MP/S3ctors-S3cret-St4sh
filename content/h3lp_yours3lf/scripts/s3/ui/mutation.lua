---@omw-context menu|player
---@module 'scripts.s3.ui.mutation'

local ui = require 'openmw.ui'

local function setChildren(layout, children, invalidate)
  assert(type(layout) == 'table', 'H3 UI setChildren layout must be a table')
  assert(type(children) == 'table', 'H3 UI setChildren children must be a table')
  layout.content = ui.content(children)
  if invalidate then invalidate() end
end

local function invalidateAfter(callback, invalidate)
  return function(...)
    local result
    if callback then result = callback(...) end
    invalidate()
    return result
  end
end

return {
  setChildren = setChildren,
  invalidateAfter = invalidateAfter,
}
