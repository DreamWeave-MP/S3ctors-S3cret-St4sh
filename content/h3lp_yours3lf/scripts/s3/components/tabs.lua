---@omw-context menu|player

local async = require 'openmw.async'

local button = require 'scripts.s3.components.button'
local row = require 'scripts.s3.components.row'

---@class H3.TabItem
---@field label string
---@field value? any

---@class H3.TabsOptions
---@field items? (string|H3.TabItem)[]
---@field selected? number
---@field onSelect? fun(index: number, item: string|H3.TabItem)
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any
---@field buttonProps? table
---@field selectedProps? table
---@field labelProps? table
---@field selectedLabelProps? table
---@field selectedPrefix? string
---@field selectedSuffix? string

local function itemLabel(item) return type(item) == 'table' and item.label or item end

local function replaceTable(target, source)
  for key in pairs(target) do
    target[key] = nil
  end
  for key, value in pairs(source or {}) do
    target[key] = value
  end
end

local function mergedTable(base, overrides)
  local merged = {}
  for key, value in pairs(base or {}) do
    merged[key] = value
  end
  for key, value in pairs(overrides or {}) do
    merged[key] = value
  end
  return merged
end

---@param options? H3.TabsOptions
---@return openmw.ui.Layout
local function tabs(options)
  options = options or {}
  local items = options.items or {}
  local selected = math.floor(options.selected or 1)
  selected = math.max(1, math.min(selected, math.max(#items, 1)))
  local children = {}

  local function setTabState(layout, index, isSelected)
    local label = itemLabel(items[index])
    if isSelected then
      label = (options.selectedPrefix or '[ ') .. label .. (options.selectedSuffix or ' ]')
    end

    local labelLayout = layout.content[1].content[1]
    labelLayout.props.text = label
    replaceTable(
      layout.props,
      mergedTable(options.buttonProps, isSelected and options.selectedProps or nil)
    )
    replaceTable(
      labelLayout.props,
      mergedTable(options.labelProps, isSelected and options.selectedLabelProps or nil)
    )
    labelLayout.props.text = label
  end

  for index, item in ipairs(items) do
    local itemEvents = {}
    itemEvents.mouseClick = async:callback(function(event, layout)
      if index == selected then return true end
      setTabState(children[selected], selected, false)
      selected = index
      setTabState(layout, index, true)
      if options.onSelect then options.onSelect(index, item) end
      return true
    end)
    local label = itemLabel(item)
    if index == selected then
      label = (options.selectedPrefix or '[ ') .. label .. (options.selectedSuffix or ' ]')
    end
    children[#children + 1] = button {
      name = 'tab_' .. index,
      label = label,
      props = mergedTable(options.buttonProps, index == selected and options.selectedProps or nil),
      labelProps = mergedTable(
        options.labelProps,
        index == selected and options.selectedLabelProps or nil
      ),
      events = itemEvents,
    }
  end

  return row {
    name = options.name,
    props = options.props,
    external = options.external,
    events = options.events,
    userData = options.userData,
    children = children,
  }
end

return tabs
