---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local appearance = require 'scripts.h3.ui.appearance'
local chrome = require 'scripts.h3.ui.chrome'
local iconButton = require 'scripts.h3.components.iconButton'
local inset = require 'scripts.h3.components.inset'
local row = require 'scripts.h3.components.row'
local text = require 'scripts.h3.components.text'

local MathFloor, MathMax, Next, Type = math.floor, math.max, next, type

local UiAlignment, UtilClamp, UtilVector2 = ui.ALIGNMENT, util.clamp, util.vector2

local EmptyOptions, EmptyItems = {}, {}

local DefaultIconProps = { size = UtilVector2(16, 16) }

---@param item string|H3.SelectorItem
---@return string
local function itemLabel(item)
  if Type(item) == 'table' then
    ---@cast item H3.SelectorItem
    return item.label
  end

  ---@cast item string
  return item
end

---@param options? H3.SelectorOptions
---@return openmw.ui.Layout
local function selector(options)
  options = options or EmptyOptions

  local items = options.items or EmptyItems
  local selected = MathFloor(options.selected or 1)
  selected = UtilClamp(selected, 1, MathMax(#items, 1))
  local previousTexture = chrome.texture(appearance.chrome 'scroll.left')
  local nextTexture = chrome.texture(appearance.chrome 'scroll.right')
  local arrowIconProps = {}
  if options.iconProps then
    for key, value in Next, options.iconProps do
      arrowIconProps[key] = value
    end
  else
    for key, value in Next, DefaultIconProps do
      arrowIconProps[key] = value
    end
  end
  if not arrowIconProps.color then arrowIconProps.color = appearance.token 'color.chromeBorder' end
  if not arrowIconProps.alpha then arrowIconProps.alpha = appearance.token 'transparency.chrome' end

  local onSelect = options.onSelect
  local valueLayout

  ---@param index integer
  ---@return nil
  local function choose(index)
    if index < 1 or index > #items or index == selected then return end

    local item = items[index]
    selected = index
    valueLayout.props.text = itemLabel(item)

    if onSelect then onSelect(index, item) end
  end

  ---@param name string
  ---@param resource openmw.ui.TextureResource
  ---@param offset integer
  ---@return openmw.ui.Layout
  local function makeButton(name, resource, offset)
    return iconButton {
      name = name,
      resource = resource,
      props = options.buttonProps,
      iconProps = arrowIconProps,
      ---@return boolean
      onActivate = function()
        choose(selected + offset)
        return true
      end,
    }
  end

  local item = items[selected]
  local label = item and itemLabel(item) or (options.emptyLabel or '')
  local labelProps = {}
  if options.labelProps then
    for key, value in Next, options.labelProps do
      labelProps[key] = value
    end
  end
  if not labelProps.textAlignH then labelProps.textAlignH = UiAlignment.Center end
  if not labelProps.textAlignV then labelProps.textAlignV = UiAlignment.Center end

  local rowProps = {}
  if options.props then
    for key, value in Next, options.props do
      rowProps[key] = value
    end
  end
  if not rowProps.arrange then rowProps.arrange = UiAlignment.Center end

  valueLayout = text {
    name = 'value',
    text = label,
    props = labelProps,
    template = options.labelTemplate,
  }
  local valueContent = valueLayout
  if labelProps.autoSize ~= false then valueContent = inset(valueContent, true) end

  local children = {
    makeButton('previous', previousTexture, -1),
    valueContent,
    makeButton('next', nextTexture, 1),
  }

  return row {
    name = options.name,
    props = rowProps,
    external = options.external,
    events = options.events,
    userData = options.userData,
    children = children,
  }
end

return selector
