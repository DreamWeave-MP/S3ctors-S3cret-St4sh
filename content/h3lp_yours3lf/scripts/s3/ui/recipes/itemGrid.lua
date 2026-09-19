---@omw-context menu|player

local async = require 'openmw.async'

---@class H3UI.ItemGridOptions
---@field items? table[]|openmw.ui.Layout[]
---@field onActivate? fun(item: table, index: integer, layout: openmw.ui.Layout): any
---@field onLayout? fun(item: table, index: integer, layout: openmw.ui.Layout) Construction hook
---receiving each produced layout. Fixtures use it to register identity maps for retained
---selection without a second structure walk.
---@field columns? integer
---@field columnGap? number
---@field rowGap? number
---@field rowProps? table
---@field variant? string
---@field tone? string
---@field class? string
---@field classes? string[]|table<string, boolean>
---@field style? table
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any
---@field template? openmw.ui.Template

local metadata = {
  role = true,
  variant = true,
  tone = true,
  class = true,
  classes = true,
  style = true,
  name = true,
}

local function itemLayout(ctx, item, index, activate)
  if type(item) ~= 'table' then return item end
  assert(
    item.component == nil and item.recipe == nil,
    'H3 UI itemGrid items must be descriptors or constructed layouts'
  )
  if item.type ~= nil or item.template ~= nil and item.resource == nil then
    if not activate then return item end
    local layout = {}
    for key, value in next, item do
      layout[key] = value
    end
    local events = {}
    for key, value in next, item.events or {} do
      events[key] = value
    end
    activate.targets[layout] = {
      item = item,
      index = index,
      callback = events.mouseClick,
    }
    events.mouseClick = activate.callback
    layout.events = events
    return layout
  end
  local spec = {
    role = item.role or 'item',
    variant = item.variant,
    tone = item.tone,
    class = item.class,
    classes = item.classes,
    style = item.style,
    name = item.name or ('item_' .. tostring(index)),
  }
  for key, value in next, item do
    if not metadata[key] then spec[key] = value end
  end
  local layout = ctx.itemSlot(spec)
  if activate then
    activate.targets[layout] = {
      item = item,
      index = index,
      callback = layout.events and layout.events.mouseClick,
    }
  end
  return layout
end

local function itemGrid(ctx, spec)
  local items = spec.items or {}
  local activate
  if spec.onActivate then
    local targets = setmetatable({}, { __mode = 'k' })
    activate = {
      targets = targets,
      callback = async:callback(function(event, layout)
        local target = targets[layout]
        if not target then return true end
        local previousResult
        if target.callback then previousResult = target.callback(event, layout) end
        local result = spec.onActivate(target.item, target.index, layout)
        if previousResult ~= nil then return previousResult end
        if result ~= nil then return result end
        return true
      end),
    }
  end
  local onLayout = spec.onLayout
  local children = {}
  for index = 1, #items do
    children[index] = itemLayout(ctx, items[index], index, activate)
    if activate and children[index] and type(children[index]) == 'table' then
      local events = children[index].events or {}
      events.mouseClick = activate.callback
      children[index].events = events
    end
    if onLayout and children[index] and type(children[index]) == 'table' then
      onLayout(items[index], index, children[index])
    end
  end
  return ctx.grid {
    role = 'root',
    variant = spec.variant,
    tone = spec.tone,
    class = spec.class,
    classes = spec.classes,
    style = spec.style,
    items = children,
    columns = spec.columns,
    name = spec.name,
    props = spec.props,
    columnGap = spec.columnGap,
    rowGap = spec.rowGap,
    rowProps = spec.rowProps,
    external = spec.external,
    events = spec.events,
    userData = spec.userData,
    template = spec.template,
  }
end
return itemGrid
