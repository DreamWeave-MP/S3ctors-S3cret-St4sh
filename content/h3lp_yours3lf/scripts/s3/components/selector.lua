---@omw-context menu|player

local emptyOptions = {}

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local iconButton = require 'scripts.s3.components.iconButton'
local row = require 'scripts.s3.components.row'
local text = require 'scripts.s3.components.text'

local MathFloor = math.floor
local MathMax = math.max
local UtilClamp = util.clamp
local UtilVector2 = util.vector2

local emptyItems = {}
local defaultIconProps = { size = UtilVector2(16, 16) }
local previousTexture = ui.texture { path = 'textures/omw_menu_scroll_left.dds' }
local nextTexture = ui.texture { path = 'textures/omw_menu_scroll_right.dds' }

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
      iconProps = options.iconProps or defaultIconProps,
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
  local children = {
    makeButton('previous', previousTexture, -1),
    text {
      name = 'value',
      text = label,
      props = options.labelProps,
      template = options.labelTemplate or I.MWUI.templates.textNormal,
    },
    makeButton('next', nextTexture, 1),
  }

  valueLayout = children[2]

  return row {
    name = options.name,
    props = options.props,
    external = options.external,
    events = options.events,
    userData = options.userData,
    children = children,
  }
end

return selector
