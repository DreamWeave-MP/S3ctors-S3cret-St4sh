---@omw-context menu|player

local emptyOptions = {}

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local appearance = require 'scripts.s3.ui.appearance'
local chrome = require 'scripts.s3.ui.chrome'
local iconButton = require 'scripts.s3.components.iconButton'
local row = require 'scripts.s3.components.row'
local text = require 'scripts.s3.components.text'

local MathFloor = math.floor
local MathMax = math.max
local UtilClamp = util.clamp
local UtilVector2 = util.vector2

local emptyItems = {}
local defaultIconProps = { size = UtilVector2(16, 16) }

---@class H3.SelectorItem
---@field label string
---@field value? any

---@class H3.SelectorOptions
---@field items? (string|H3.SelectorItem)[]
---@field selected? number
---@field onSelect? fun(index: number, item: string|H3.SelectorItem)
---@field emptyLabel? string
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any
---@field buttonProps? table
---@field iconProps? table
---@field labelProps? table
---@field labelTemplate? openmw.ui.Template

local function itemLabel(item)
  if type(item) == 'table' then return item.label end
  return item
end

---@param options? H3.SelectorOptions
---@return openmw.ui.Layout
local function selector(options)
  options = options or emptyOptions

  local items = options.items or emptyItems
  local selected = MathFloor(options.selected or 1)
  selected = UtilClamp(selected, 1, MathMax(#items, 1))
  local previousTexture = chrome.texture(appearance.chrome 'scroll.left')
  local nextTexture = chrome.texture(appearance.chrome 'scroll.right')
  local arrowIconProps = {}
  for key, value in next, options.iconProps or defaultIconProps do
    arrowIconProps[key] = value
  end
  if arrowIconProps.color == nil then
    arrowIconProps.color = appearance.token 'color.chromeBorder'
  end

  local onSelect = options.onSelect
  local valueLayout

  local function choose(index)
    if index < 1 or index > #items or index == selected then return end

    local item = items[index]
    selected = index
    valueLayout.props.text = itemLabel(item)

    if onSelect then onSelect(index, item) end
  end

  local function makeButton(name, resource, offset)
    return iconButton {
      name = name,
      resource = resource,
      props = options.buttonProps,
      iconProps = arrowIconProps,
      events = {
        mouseClick = async:callback(function()
          choose(selected + offset)
          return true
        end),
      },
    }
  end

  local item = items[selected]
  local label = item and itemLabel(item) or (options.emptyLabel or '')
  local labelProps = {}
  if options.labelProps then
    for key, value in next, options.labelProps do
      labelProps[key] = value
    end
  end
  if labelProps.textAlignH == nil then labelProps.textAlignH = ui.ALIGNMENT.Center end
  if labelProps.textAlignV == nil then labelProps.textAlignV = ui.ALIGNMENT.Center end

  local rowProps = {}
  if options.props then
    for key, value in next, options.props do
      rowProps[key] = value
    end
  end
  if rowProps.arrange == nil then rowProps.arrange = ui.ALIGNMENT.Center end

  valueLayout = text {
    name = 'value',
    text = label,
    props = labelProps,
    template = options.labelTemplate,
  }
  local valueContent = valueLayout
  if labelProps.autoSize ~= false then
    for _ = 1, 3 do
      valueContent = {
        template = I.MWUI.templates.padding,
        props = { ignorePointerEvents = true },
        content = ui.content { valueContent },
      }
    end
  end

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
