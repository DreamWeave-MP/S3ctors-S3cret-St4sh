---@omw-context menu|player

local async = require 'openmw.async'
local openmwUi = require 'openmw.ui'
local StrFind = string.find
local StrLower = string.lower

---@class H3UI.SearchableListOptions
---@field query? string
---@field items? (string|number|table|openmw.ui.Layout)[]
---@field text? fun(item: any, index: integer): string Text used for construction-time matching.
---@field onActivate? fun(item: any, index: integer, layout: openmw.ui.Layout): any
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

local function listItem(ctx, item, index, activate)
  if type(item) == 'string' or type(item) == 'number' then
    local layout = ctx.listItem {
      role = 'item',
      label = tostring(item),
      name = 'item_' .. tostring(index),
    }
    if activate then activate.targets[layout] = { item = item, index = index } end
    return layout
  end
  if type(item) ~= 'table' then return item end
  assert(
    item.component == nil and item.recipe == nil,
    'H3 UI searchableList items must be descriptors or constructed layouts'
  )
  if item.type ~= nil then
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
  local spec = { name = item.name or ('item_' .. tostring(index)) }
  for key, value in next, item do
    if key ~= 'name' then spec[key] = value end
  end
  spec.role = spec.role or 'item'
  local layout = ctx.listItem(spec)
  if activate then
    activate.targets[layout] = {
      item = item,
      index = index,
      callback = layout.events and layout.events.mouseClick,
    }
  end
  return layout
end

local function itemText(item, index, text)
  if text then return tostring(text(item, index) or '') end
  if type(item) == 'string' or type(item) == 'number' then return tostring(item) end
  if type(item) ~= 'table' then return '' end
  return tostring(item.label or item.name or '')
end

local function searchableList(ctx, spec)
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
  local query = spec.query or ''
  assert(type(query) == 'string', 'H3 UI searchableList query must be a string')
  assert(
    spec.text == nil or type(spec.text) == 'function',
    'H3 UI searchableList text must be a function'
  )

  local searchText = {}
  for index = 1, #items do
    searchText[index] = StrLower(itemText(items[index], index, spec.text))
  end

  local resultsElement
  local resultsUi = ctx.child {
    element = function() return resultsElement end,
    _ownsElement = true,
  }

  local function matchingEntries(filter)
    local normalizedQuery = StrLower(filter)
    local entries = {}
    for index = 1, #items do
      if normalizedQuery == '' or StrFind(searchText[index], normalizedQuery, 1, true) then
        local entry = listItem(resultsUi, items[index], index, activate)
        if activate and entry and type(entry) == 'table' then
          local events = entry.events or {}
          events.mouseClick = activate.callback
          entry.events = events
        end
        entries[#entries + 1] = entry
      end
    end
    return entries
  end

  local resultsLayout
  local function applyQuery(value, layout)
    if spec.onQueryChange then spec.onQueryChange(value, layout) end
    resultsUi.setChildren(resultsLayout, matchingEntries(value))
  end

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
  resultsElement = openmwUi.create(resultsLayout)
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
