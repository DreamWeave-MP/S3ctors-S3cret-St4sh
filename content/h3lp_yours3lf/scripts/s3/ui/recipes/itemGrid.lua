---@omw-context menu|player

local metadata = {
  role = true,
  variant = true,
  tone = true,
  class = true,
  classes = true,
  style = true,
  component = true,
  recipe = true,
}

local function itemNode(ctx, item, index)
  if type(item) ~= 'table' then return item end
  if item.recipe then return ctx.build(item) end
  if item.component then return ctx.component(item.component, item) end
  if item.type ~= nil or item.template ~= nil and item.resource == nil then return item end
  local spec = {
    role = item.role or 'item',
    variant = item.variant,
    tone = item.tone,
    class = item.class,
    classes = item.classes,
    style = item.style,
  }
  for key, value in next, item do
    if not metadata[key] then spec[key] = value end
  end
  spec.name = spec.name or ('item_' .. tostring(index))
  return ctx.component('itemSlot', spec)
end

local function itemGrid(ctx, spec)
  local items = spec.items or {}
  local children = {}
  for index = 1, #items do
    children[index] = itemNode(ctx, items[index], index)
  end
  return ctx.component('grid', {
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
  })
end
return itemGrid
