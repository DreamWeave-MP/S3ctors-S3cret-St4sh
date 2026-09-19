---@omw-context menu|player

local ui = require 'openmw.ui'

local activation = require 'scripts.h3.ui.recipes.activation'

local Assert, Next, RawGet, StrFind, StrFormat, StrLower, ToString, Type =
  assert, next, rawget, string.find, string.format, string.lower, tostring, type

local UiCreate = ui.create

---@param ctx H3UI.Scope
---@param item H3UI.SearchableListItem
---@param index integer
---@param activate? H3UI.ActivationState
---@return openmw.ui.Layout
local function listItem(ctx, item, index, activate)
  if Type(item) == 'string' or Type(item) == 'number' then
    local layout = ctx.listItem {
      role = 'item',
      label = ToString(item),
      name = StrFormat('item_%s', ToString(index)),
    }
    return activation.bind(activate, layout, item, index)
  end

  Assert(Type(item) == 'table', 'H3 UI searchableList item must be text, number, descriptor, or layout')

  Assert(
    not RawGet(item, 'component') and not RawGet(item, 'recipe'),
    'H3 UI searchableList items must be descriptors or constructed layouts'
  )

  if item.type then
    ---@cast item openmw.ui.Layout
    return activation.bind(activate, item, item, index, true)
  end

  ---@cast item H3UI.ListItemOptions
  local spec = { name = item.name or StrFormat('item_%s', ToString(index)) }
  for key, value in Next, item do
    if key ~= 'name' then spec[key] = value end
  end
  spec.role = spec.role or 'item'

  return activation.bind(activate, ctx.listItem(spec), item, index)
end

---@param item H3UI.SearchableListItem
---@param index integer
---@param text? fun(item: H3UI.SearchableListItem, index: integer): string
---@return string
local function itemText(item, index, text)
  if text then return ToString(text(item, index) or '') end
  if Type(item) == 'string' or Type(item) == 'number' then return ToString(item) end
  if Type(item) ~= 'table' then return '' end

  return ToString(item.label or item.name or '')
end

---@param ctx H3UI.RecipeContext
---@param spec H3UI.SearchableListOptions
---@return openmw.ui.Layout
local function searchableList(ctx, spec)
  local items = spec.items or {}
  local activate = activation.new(spec.onActivate)
  local query = spec.query or ''

  Assert(Type(query) == 'string', 'H3 UI searchableList query must be a string')
  Assert(
    spec.text == nil or Type(spec.text) == 'function',
    'H3 UI searchableList text must be a function'
  )

  local searchText = {}
  for index = 1, #items do
    local item = items[index]
    searchText[index] = StrLower(itemText(item, index, spec.text))
  end

  local resultsElement
  local resultsUi = ctx.child {
    ---@return openmw.ui.Element?
    element = function() return resultsElement end,
    _ownsElement = true,
  }

  ---@param filter string
  ---@return openmw.ui.Layout[]
  local function matchingEntries(filter)
    local entries, normalizedQuery = {}, StrLower(filter)

    for index = 1, #items do
      if normalizedQuery == '' or StrFind(searchText[index], normalizedQuery, 1, true) then
        local item = items[index]

        entries[#entries + 1] = listItem(resultsUi, item, index, activate)
      end
    end

    return entries
  end

  local resultsLayout
  ---@param value string
  ---@param layout openmw.ui.Layout
  ---@return nil
  local function applyQuery(value, layout)
    if spec.onQueryChange then spec.onQueryChange(value, layout) end
    resultsUi.setChildren(resultsLayout, matchingEntries(value))
  end

  ---@type openmw.ui.LayoutOrElement[]
  local children = {
    ctx.searchInput {
      role = 'search',
      style = spec.searchStyle,
      value = query,
      onChange = applyQuery,
      clearable = spec.clearable,
      clearLabel = spec.clearLabel,
      props = spec.searchProps,
      inputProps = spec.inputProps,
    },
  }

  resultsLayout = resultsUi.list {
    role = 'results',
    style = spec.listStyle,
    items = matchingEntries(query),
    props = spec.listProps,
  }

  resultsElement = UiCreate(resultsLayout)
  children[#children + 1] = resultsElement

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
