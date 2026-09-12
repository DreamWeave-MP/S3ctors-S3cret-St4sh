---@omw-context menu|player

local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local iconButton = require 'scripts.s3.components.iconButton'
local row = require 'scripts.s3.components.row'
local text = require 'scripts.s3.components.text'

local vector2 = util.vector2

local previousTexture = ui.texture { path = 'textures/omw_menu_scroll_left.dds' }
local nextTexture = ui.texture { path = 'textures/omw_menu_scroll_right.dds' }

---@class H3.SelectItem
---@field label string
---@field value? any

---@class H3.SelectOptions
---@field items? (string|H3.SelectItem)[]
---@field selected? number
---@field onSelect? fun(index: number, item: string|H3.SelectItem)
---@field emptyLabel? string
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any
---@field buttonProps? table
---@field iconProps? table
---@field labelProps? table

local function itemLabel(item) return type(item) == 'table' and item.label or item end

---@param options? H3.SelectOptions
---@return openmw.ui.Layout
local function select(options)
  options = options or {}
  local items = options.items or {}
  local selected = math.floor(options.selected or 1)
  selected = util.clamp(selected, 1, math.max(#items, 1))
  local valueLayout

  local function choose(index)
    if index < 1 or index > #items or index == selected then return end
    local item = items[index]
    selected = index
    valueLayout.props.text = itemLabel(item)
    if options.onSelect then options.onSelect(index, item) end
  end

  local function makeButton(name, resource, offset)
    return iconButton {
      name = name,
      resource = resource,
      props = options.buttonProps,
      iconProps = options.iconProps or { size = vector2(16, 16) },
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

return select
