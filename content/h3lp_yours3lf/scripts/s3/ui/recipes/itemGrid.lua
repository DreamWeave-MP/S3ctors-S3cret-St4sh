---@omw-context menu|player

local merge = require 'scripts.s3.ui.merge'

local passthrough = {
  'resource',
  'count',
  'name',
  'props',
  'iconProps',
  'countProps',
  'external',
  'events',
  'userData',
  'template',
}

local function itemNode(ctx, item, index)
  if type(item) ~= 'table' then return item end

  if item.recipe then return ctx.build(item) end
  if item.component then return ctx.component(item.component, item) end
  if item.type ~= nil or item.template ~= nil or item.content ~= nil then return item end

  local args = merge.shallowCopy(item.args or {})
  for keyIndex = 1, #passthrough do
    local key = passthrough[keyIndex]
    if item[key] ~= nil then args[key] = item[key] end
  end
  args.name = args.name or ('item_' .. tostring(index))

  return ctx.component('itemSlot', {
    role = item.role or 'item',
    variant = item.variant,
    tone = item.tone,
    density = item.density,
    class = item.class,
    classes = item.classes,
    style = item.style,
    args = args,
  })
end

local function itemGrid(ctx, spec)
  local items = spec.items or {}
  local children = {}
  for index = 1, #items do children[index] = itemNode(ctx, items[index], index) end

  local args = merge.shallowCopy(spec.args or {})
  args.items = children
  if spec.columns ~= nil then args.columns = spec.columns end
   if spec.name ~= nil then args.name = spec.name end
   if spec.props ~= nil then args.props = spec.props end
   if spec.columnGap ~= nil then args.columnGap = spec.columnGap end
   if spec.rowGap ~= nil then args.rowGap = spec.rowGap end
   if spec.rowProps ~= nil then args.rowProps = spec.rowProps end
  if spec.external ~= nil then args.external = spec.external end
  if spec.events ~= nil then args.events = spec.events end
  if spec.userData ~= nil then args.userData = spec.userData end
  if spec.template ~= nil then args.template = spec.template end

  return ctx.component('grid', {
    role = 'root',
    variant = spec.variant,
    tone = spec.tone,
    density = spec.density,
    class = spec.class,
    classes = spec.classes,
    style = spec.style,
    args = args,
  })
end

return itemGrid
