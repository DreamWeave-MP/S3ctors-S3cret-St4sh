---@omw-context menu|player

local emptyOptions = {}

local activationEvents = require 'scripts.s3.components.activationEvents'
local appearance = require 'scripts.s3.ui.appearance'
local image = require 'scripts.s3.components.image'
local surface = require 'scripts.s3.ui.surface'
local text = require 'scripts.s3.components.text'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local UtilVector2 = util.vector2
local Center = UtilVector2(0.5, 0.5)
local BottomRight = UtilVector2(1, 1)

---@class H3.ItemSlotOptions
---@field resource? openmw.ui.TextureResource|openmw.ui.TextureResourceOptions
---@field count? string|number
---@field selected? boolean Highlight the slot using the active theme color.
---@field onActivate? fun(event: table, layout: openmw.ui.Layout): any
---@field name? string
---@field props? table
---@field iconProps? table
---@field countProps? table
---@field selectionProps? table
---@field external? table
---@field events? table
---@field userData? any
---@field template? openmw.ui.Template

---Build a bordered item slot layout with optional icon and count label.
---Allocates fresh layout, props, external, and content tables. A texture options table passed as
---`resource` is converted by the image component; this primitive does not query game state or own any Element.
---@param options? H3.ItemSlotOptions
---@return openmw.ui.Layout
local function itemSlot(options)
  options = options or emptyOptions

  local props = {}
  if options.props then
    for key, value in next, options.props do
      props[key] = value
    end
  end

  -- Fixed-geometry slots are free-positioned Widget roots, so center the icon with anchor
  -- geometry. Auto-sized slots keep flow layout so the icon can size the slot.
  local fixedGeometry = props.size ~= nil or props.relativeSize ~= nil

  local iconProps = {}
  if options.iconProps then
    for key, value in next, options.iconProps do
      iconProps[key] = value
    end
  end

  if options.resource ~= nil then iconProps.resource = options.resource end
  iconProps.ignorePointerEvents = true
  if fixedGeometry then
    if iconProps.anchor == nil then iconProps.anchor = Center end
    if iconProps.relativePosition == nil then iconProps.relativePosition = Center end
  end

  local content = {
    image { name = 'icon', resource = options.resource, props = iconProps },
  }
  if options.count ~= nil then
    local countProps = {}
    if options.countProps then
      for key, value in next, options.countProps do
        countProps[key] = value
      end
    end
    if countProps.textColor == nil then countProps.textColor = appearance.token 'color.count' end
    if countProps.textSize == nil then countProps.textSize = appearance.token 'textSize.normal' end
    countProps.ignorePointerEvents = true
    if fixedGeometry then
      if countProps.anchor == nil then countProps.anchor = BottomRight end
      if countProps.relativePosition == nil then countProps.relativePosition = BottomRight end
      if countProps.position == nil then countProps.position = UtilVector2(-3, -3) end
    end
    content[#content + 1] = text { text = tostring(options.count), props = countProps }
  end

  local external
  if options.external then
    external = {}
    for key, value in next, options.external do
      external[key] = value
    end
  end

  local layout = {
    name = options.name,
    props = props,
    external = external,
    events = activationEvents(options.events, options.onActivate),
    userData = options.userData,
    content = ui.content(content),
  }

  if options.template then
    layout.template = options.template
    return layout
  end

  return surface.build {
    skin = appearance.chrome 'frame.thin',
    name = layout.name,
    props = layout.props,
    external = layout.external,
    events = layout.events,
    userData = layout.userData,
    tint = appearance.token 'color.chromeBorder',
    alpha = appearance.token 'transparency.chrome',
    selected = {
      props = options.selectionProps,
      tint = appearance.token 'color.active',
      alpha = appearance.token 'transparency.chrome',
    },
    content = content,
  }
end

return itemSlot
