---@omw-context menu|player

---@class H3UI.ItemGridOptions
---@field items? table[]|openmw.ui.Layout[]
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

local function itemLayout(ctx, item, index)
  if type(item) ~= 'table' then return item end
  assert(
    item.component == nil and item.recipe == nil,
    'H3 UI itemGrid items must be descriptors or constructed layouts'
  )
  if item.type ~= nil or item.template ~= nil and item.resource == nil then return item end
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
  return ctx.itemSlot(spec)
end

local function itemGrid(ctx, spec)
  local items = spec.items or {}
  local children = {}
  for index = 1, #items do
    children[index] = itemLayout(ctx, items[index], index)
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
