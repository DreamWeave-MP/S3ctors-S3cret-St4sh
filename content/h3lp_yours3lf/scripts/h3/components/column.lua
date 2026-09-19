---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local Assert, Next, Type = assert, next, type

local UiContent, UiType, UtilVector2 = ui.content, ui.TYPE, util.vector2

local EmptyOptions = {}

---@param options H3.ColumnOptions
---@return openmw.ui.Content|openmw.ui.LayoutOrElement[]?
local function collectChildren(options)
  local explicit = options.content or options.children
  if #options == 0 then return explicit end
  Assert(not explicit, 'H3 column accepts array children or children/content, not both')
  local result = {}
  for index = 1, #options do
    result[index] = options[index]
  end
  return result
end

---@param children? openmw.ui.LayoutOrElement[]
---@param gap? number
---@return openmw.ui.LayoutOrElement[]?
local function withGap(children, gap)
  if gap then
    Assert(Type(gap) == 'number' and gap >= 0, 'H3 column gap must be a non-negative number')
  end
  if not children or #children < 2 or not gap or gap == 0 then return children end
  local result = {}
  local gapSize = UtilVector2(0, gap)
  for index = 1, #children do
    if index > 1 then
      result[#result + 1] = {
        type = UiType.Widget,
        props = { size = gapSize, ignorePointerEvents = true },
      }
    end
    result[#result + 1] = children[index]
  end
  return result
end

---@param options? H3.ColumnOptions
---@return openmw.ui.Layout
local function column(options)
  options = options or EmptyOptions
  local props = {}
  if options.props then
    for key, value in Next, options.props do
      props[key] = value
    end
  end
  local external
  if options.external then
    external = {}
    for key, value in Next, options.external do
      external[key] = value
    end
  end
  props.horizontal = false
  local layout = {
    type = UiType.Flex,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    template = options.template,
  }
  local children = withGap(collectChildren(options), options.gap)
  if children then layout.content = UiContent(children) end
  return layout
end

return column
