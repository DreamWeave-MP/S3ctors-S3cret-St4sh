---@omw-context menu|player

local button = require 'scripts.h3.components.button'
local row = require 'scripts.h3.components.row'

local MathFloor, MathMax, MathMin, Next, StrFormat, Type =
  math.floor, math.max, math.min, next, string.format, type

local EmptyOptions, EmptyItems = {}, {}

---@param layout openmw.ui.Layout
---@return openmw.ui.Layout
local function labelLayout(layout)
  ---@type openmw.ui.Layout
  local result = layout.content[1]

  while result.content do
    result = result.content[1]
  end

  return result
end

---@param item string|H3.TabItem
---@return string
local function itemLabel(item)
  if Type(item) == 'table' then
    ---@cast item H3.TabItem
    return item.label
  end

  ---@cast item string
  return item
end

---@param target table
---@param base? table
---@param overrides? table
---@return table
local function mergeInto(target, base, overrides)
  for key in Next, target do
    target[key] = nil
  end

  if base then
    for key, value in Next, base do
      target[key] = value
    end
  end

  if overrides then
    for key, value in Next, overrides do
      target[key] = value
    end
  end

  return target
end

---@param options? H3.TabsOptions
---@return openmw.ui.Layout
local function tabs(options)
  options = options or EmptyOptions

  local items = options.items or EmptyItems
  local selected = MathFloor(options.selected or 1)
  selected = MathMax(1, MathMin(selected, MathMax(#items, 1)))

  local selectedPrefix = options.selectedPrefix or '[ '
  local selectedSuffix = options.selectedSuffix or ' ]'
  local onSelect = options.onSelect
  local children = {}
  local baseButtonProps = {}
  local baseLabelProps = {}

  ---@param target table
  ---@param base table
  ---@param overrides? table
  ---@param enabled boolean
  ---@return nil
  local function applyOverrides(target, base, overrides, enabled)
    if not overrides then return end

    for key, value in Next, overrides do
      target[key] = enabled and value or base[key]
    end
  end

  ---@param layout openmw.ui.Layout
  ---@param index integer
  ---@param isSelected boolean
  ---@return nil
  local function setTabState(layout, index, isSelected)
    local label = itemLabel(items[index])
    if isSelected then label = StrFormat('%s%s%s', selectedPrefix, label, selectedSuffix) end

    local labelTextLayout = labelLayout(layout)
    applyOverrides(layout.props, baseButtonProps[index], options.selectedProps, isSelected)
    applyOverrides(
      labelTextLayout.props,
      baseLabelProps[index],
      options.selectedLabelProps,
      isSelected
    )

    labelTextLayout.props.text = label
  end

  for index = 1, #items do
    local item = items[index]
    local itemIndex = index
    ---@param _ openmw.ui.MouseEvent
    ---@param layout openmw.ui.Layout
    ---@return boolean
    local function activate(_, layout)
      if itemIndex == selected then return true end
      setTabState(children[selected], selected, false)
      selected = itemIndex
      setTabState(layout, itemIndex, true)
      if onSelect then onSelect(itemIndex, item) end
      return true
    end

    local label = itemLabel(item)
    if index == selected then label = StrFormat('%s%s%s', selectedPrefix, label, selectedSuffix) end

    children[index] = button {
      name = StrFormat('tab_%s', index),
      label = label,
      props = mergeInto({}, options.buttonProps),
      labelProps = mergeInto({}, options.labelProps),
      onActivate = activate,
    }

    local child = children[index]

    baseButtonProps[index] = mergeInto({}, child.props)
    baseLabelProps[index] = mergeInto({}, labelLayout(child).props)

    if index == selected then setTabState(child, index, true) end
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
