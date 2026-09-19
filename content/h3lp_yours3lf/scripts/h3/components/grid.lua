---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local Assert, MathFloor, Next, Type = assert, math.floor, next, type

local UiContent, UiType, UtilVector2 = ui.content, ui.TYPE, util.vector2
local EmptyOptions, EmptyItems = {}, {}

---Build a grid as a vertical Flex of horizontal Flex rows.
---Allocates fresh layout, props, external, and content tables for the grid and each row. `items` are not
---copied; callers own child layout mutation and any mounted elements.
---@param options? H3.GridOptions
---@return openmw.ui.Layout
local function grid(options)
  options = options or EmptyOptions

  local columns = options.columns or 1
  local columnGap = options.columnGap
  local rowGap = options.rowGap
  Assert(
    Type(columns) == 'number' and columns >= 1 and columns == MathFloor(columns),
    'H3 grid columns must be a positive integer'
  )
  Assert(
    columnGap == nil or Type(columnGap) == 'number' and columnGap >= 0,
    'H3 grid columnGap must be a non-negative number'
  )
  Assert(
    rowGap == nil or Type(rowGap) == 'number' and rowGap >= 0,
    'H3 grid rowGap must be a non-negative number'
  )

  local rows = {}
  local row
  local items = options.items or EmptyItems
  for index = 1, #items do
    local item = items[index]
    if (index - 1) % columns == 0 then
      if row and rowGap and rowGap > 0 then
        rows[#rows + 1] = {
          type = UiType.Widget,
          props = { size = UtilVector2(0, rowGap), ignorePointerEvents = true },
        }
      end

      local rowProps = {}
      if options.rowProps then
        for key, value in Next, options.rowProps do
          rowProps[key] = value
        end
      end
      rowProps.horizontal = true
      row = { type = UiType.Flex, props = rowProps, content = UiContent {} }
      rows[#rows + 1] = row
    elseif columnGap and columnGap > 0 then
      row.content:add {
        type = UiType.Widget,
        props = { size = UtilVector2(columnGap, 0), ignorePointerEvents = true },
      }
    end
    row.content:add(item)
  end

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

  return {
    type = UiType.Flex,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    template = options.template,
    content = UiContent(rows),
  }
end

return grid
