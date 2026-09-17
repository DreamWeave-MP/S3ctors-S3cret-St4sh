---@omw-context menu|player

local node = require 'scripts.s3.ui.node'

---@class H3UI.SearchableListOptions
---@field query? string
---@field items? (string|number|table|openmw.ui.Layout)[]
---@field text? fun(item: any, index: integer): string Text used for construction-time matching.
---@field onQueryChange? fun(value: string, layout: openmw.ui.Layout): any
---@field clearable? boolean
---@field clearLabel? string
---@field gap? number
---@field searchStyle? table
---@field searchProps? table
---@field inputProps? table
---@field listStyle? table
---@field listProps? table
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

local function listItem(ctx, item, index)
  if type(item) == 'string' or type(item) == 'number' then
    return ctx.listItem {
      role = 'item',
      label = tostring(item),
      name = 'item_' .. tostring(index),
    }
  end
  if type(item) ~= 'table' then return item end
  if node.isComponent(item) or node.isRecipe(item) then return item end
  assert(
    item.component == nil and item.recipe == nil,
    'H3 UI searchableList items must be descriptors or constructed layouts'
  )
  if item.type ~= nil then return item end
  local spec = { name = item.name or ('item_' .. tostring(index)) }
  for key, value in next, item do
    if key ~= 'name' then spec[key] = value end
  end
  spec.role = spec.role or 'item'
  return ctx.listItem(spec)
end

local function itemText(item, index, text)
  if text then return tostring(text(item, index) or '') end
  if type(item) == 'string' or type(item) == 'number' then return tostring(item) end
  if type(item) ~= 'table' then return '' end
  return tostring(item.label or item.name or '')
end

local function searchableList(ctx, spec)
  local items = spec.items or {}
  local query = spec.query or ''
  assert(type(query) == 'string', 'H3 UI searchableList query must be a string')
  assert(
    spec.text == nil or type(spec.text) == 'function',
    'H3 UI searchableList text must be a function'
  )
  local normalizedQuery = string.lower(query)
  local listItems = {}
  for index = 1, #items do
    if
      normalizedQuery == ''
      or string.find(
        string.lower(itemText(items[index], index, spec.text)),
        normalizedQuery,
        1,
        true
      )
    then
      listItems[#listItems + 1] = listItem(ctx, items[index], index)
    end
  end
  local children = {
    ctx.searchInput {
      role = 'search',
      style = spec.searchStyle,
      value = query,
      onChange = spec.onQueryChange,
      clearable = spec.clearable,
      clearLabel = spec.clearLabel,
      props = spec.searchProps,
      inputProps = spec.inputProps,
    },
    ctx.list { role = 'results', style = spec.listStyle, items = listItems, props = spec.listProps },
  }
  return ctx.column {
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
    gap = spec.gap or ctx.token 'spacing.sm',
    children = children,
  }
end
return searchableList
