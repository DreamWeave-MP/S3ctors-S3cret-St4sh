---@omw-context menu|player

local function listItem(ctx, item, index)
  if type(item) == 'string' or type(item) == 'number' then
    return ctx.component(
      'listItem',
      { role = 'item', label = tostring(item), name = 'item_' .. tostring(index) }
    )
  end
  if type(item) ~= 'table' then return item end
  if item.recipe then return ctx.build(item) end
  if item.component then return ctx.component(item.component, item) end
  if item.type ~= nil then return item end
  local spec = {}
  for key, value in next, item do
    spec[key] = value
  end
  spec.role = spec.role or 'item'
  spec.name = spec.name or ('item_' .. tostring(index))
  return ctx.component('listItem', spec)
end

local function searchableList(ctx, spec)
  local items = spec.items or {}
  local listItems = {}
  for index = 1, #items do
    listItems[index] = listItem(ctx, items[index], index)
  end
  local children = {
    ctx.component('searchInput', {
      role = 'search',
      style = spec.searchStyle,
      value = spec.query or spec.value,
      onChange = spec.onQueryChange or spec.onChange,
      clearable = spec.clearable,
      clearLabel = spec.clearLabel,
      props = spec.searchProps,
      inputProps = spec.inputProps,
    }),
    ctx.component(
      'list',
      { role = 'results', style = spec.listStyle, items = listItems, props = spec.listProps }
    ),
  }
  return ctx.component('column', {
    role = 'root',
    variant = spec.variant,
    tone = spec.tone,
    class = spec.class,
    classes = spec.classes,
    style = spec.style,
    name = spec.name,
    props = spec.props,
    external = spec.external,
    events = spec.events,
    userData = spec.userData,
    template = spec.template,
    gap = spec.gap or 4,
    children = children,
  })
end
return searchableList
