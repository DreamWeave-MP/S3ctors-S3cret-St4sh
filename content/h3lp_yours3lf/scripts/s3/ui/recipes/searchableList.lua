---@omw-context menu|player

local merge = require 'scripts.s3.ui.merge'

local function listItem(ctx, item, index)
  if type(item) == 'string' or type(item) == 'number' then
    return ctx.component('listItem', {
      role = 'item',
      args = { label = tostring(item), name = 'item_' .. tostring(index) },
    })
  end

  if type(item) ~= 'table' then return item end
  if item.recipe then return ctx.build(item) end
  if item.component then return ctx.component(item.component, item) end
  if item.type ~= nil or item.template ~= nil or item.content ~= nil then return item end

  local args = merge.shallowCopy(item.args or {})
  if item.label ~= nil then args.label = item.label end
  if item.name ~= nil then args.name = item.name end
  if item.props ~= nil then args.props = item.props end
  if item.labelProps ~= nil then args.labelProps = item.labelProps end
  if item.external ~= nil then args.external = item.external end
  if item.events ~= nil then args.events = item.events end
  if item.userData ~= nil then args.userData = item.userData end
  args.name = args.name or ('item_' .. tostring(index))

  return ctx.component('listItem', {
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

local function searchableList(ctx, spec)
  local items = spec.items or {}
  local listItems = {}
  for index = 1, #items do listItems[index] = listItem(ctx, items[index], index) end

  local searchArgs = merge.shallowCopy(spec.searchArgs or {})
  searchArgs.value = spec.query ~= nil and spec.query or (spec.value ~= nil and spec.value or searchArgs.value)
  searchArgs.onChange = spec.onQueryChange or spec.onChange or searchArgs.onChange
  if spec.clearable ~= nil then searchArgs.clearable = spec.clearable end
  if spec.clearLabel ~= nil then searchArgs.clearLabel = spec.clearLabel end

  local listArgs = merge.shallowCopy(spec.listArgs or {})
  listArgs.items = listItems

  local children = {
    ctx.component('searchInput', {
      role = 'search',
      style = spec.searchStyle,
      args = searchArgs,
    }),
    ctx.component('list', {
      role = 'results',
      style = spec.listStyle,
      args = listArgs,
    }),
  }

  local args = merge.shallowCopy(spec.args or {})
  if spec.name ~= nil then args.name = spec.name end
  if spec.props ~= nil then args.props = spec.props end
  if spec.external ~= nil then args.external = spec.external end
  if spec.events ~= nil then args.events = spec.events end
  if spec.userData ~= nil then args.userData = spec.userData end
  if spec.template ~= nil then args.template = spec.template end
  args.children = children

  return ctx.component('column', {
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

return searchableList
