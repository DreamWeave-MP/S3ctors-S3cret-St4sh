---@omw-context menu|player

local emptyOptions = {}
local emptyItems = {}

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local MathFloor = math.floor
local UtilVector2 = util.vector2

---Build a grid as a vertical Flex of horizontal Flex rows.
---Allocates fresh layout, props, external, and content tables for the grid and each row. `items` are not
---copied; callers own child layout mutation and any mounted elements.
---@param options? {items?: openmw.ui.LayoutOrElement[], columns?: integer, columnGap?: number, rowGap?: number, name?: string, props?: table, rowProps?: table, external?: table, events?: table, userData?: any, template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function grid(options)
  options = options or emptyOptions

  local columns = options.columns or 1
  local columnGap = options.columnGap
  local rowGap = options.rowGap
  assert(
    type(columns) == 'number' and columns >= 1 and columns == MathFloor(columns),
    'H3 grid columns must be a positive integer'
  )
  assert(
    columnGap == nil or type(columnGap) == 'number' and columnGap >= 0,
    'H3 grid columnGap must be a non-negative number'
  )
  assert(
    rowGap == nil or type(rowGap) == 'number' and rowGap >= 0,
    'H3 grid rowGap must be a non-negative number'
  )

  local rows = {}
  local row
  local items = options.items or emptyItems
  for index = 1, #items do
    local item = items[index]
    if (index - 1) % columns == 0 then
      if row and rowGap and rowGap > 0 then
        rows[#rows + 1] = {
          type = ui.TYPE.Widget,
          props = { size = UtilVector2(0, rowGap), ignorePointerEvents = true },
        }
      end

      local rowProps = {}
      if options.rowProps then
        for key, value in next, options.rowProps do
          rowProps[key] = value
        end
      end
      rowProps.horizontal = true
      row = { type = ui.TYPE.Flex, props = rowProps, content = ui.content {} }
      rows[#rows + 1] = row
    elseif columnGap and columnGap > 0 then
      row.content:add {
        type = ui.TYPE.Widget,
        props = { size = UtilVector2(columnGap, 0), ignorePointerEvents = true },
      }
    end
    row.content:add(item)
  end

  local props = {}
  if options.props then
    for key, value in next, options.props do
      props[key] = value
    end
  end
  local external
  if options.external then
    external = {}
    for key, value in next, options.external do
      external[key] = value
    end
  end

  props.horizontal = false

  return {
    type = ui.TYPE.Flex,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    template = options.template,
    content = ui.content(rows),
  }
end

return grid
