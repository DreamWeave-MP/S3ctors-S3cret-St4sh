---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local activationEvents = require 'scripts.h3.components.activationEvents'
local appearance = require 'scripts.h3.ui.appearance'
local image = require 'scripts.h3.components.image'
local surface = require 'scripts.h3.ui.surface'
local text = require 'scripts.h3.components.text'

local Next, ToString = next, tostring

local UiContent, UtilVector2 = ui.content, util.vector2

local EmptyOptions = {}
local Center, BottomRight = UtilVector2(0.5, 0.5), UtilVector2(1, 1)

---Build a bordered item slot layout with optional icon and count label.
---Allocates fresh layout, props, external, and content tables. A texture options table passed as
---`resource` is converted by the image component; this primitive does not query game state or own any Element.
---@param options? H3.ItemSlotOptions
---@return openmw.ui.Layout
local function itemSlot(options)
  options = options or EmptyOptions

  local props = {}
  if options.props then
    for key, value in Next, options.props do
      props[key] = value
    end
  end

  -- Fixed-geometry slots are free-positioned Widget roots, so center the icon with anchor
  -- geometry. Auto-sized slots keep flow layout so the icon can size the slot.
  local fixedGeometry = props.size or props.relativeSize

  local iconProps = {}
  if options.iconProps then
    for key, value in Next, options.iconProps do
      iconProps[key] = value
    end
  end

  if options.resource then iconProps.resource = options.resource end
  iconProps.ignorePointerEvents = true
  if fixedGeometry then
    if not iconProps.anchor then iconProps.anchor = Center end
    if not iconProps.relativePosition then iconProps.relativePosition = Center end
  end

  local content = {
    image { name = 'icon', resource = options.resource, props = iconProps },
  }
  if options.count then
    local countProps = {}
    if options.countProps then
      for key, value in Next, options.countProps do
        countProps[key] = value
      end
    end
    if not countProps.textColor then countProps.textColor = appearance.token 'color.count' end
    if not countProps.textSize then countProps.textSize = appearance.token 'textSize.normal' end
    countProps.ignorePointerEvents = true
    if fixedGeometry then
      if not countProps.anchor then countProps.anchor = BottomRight end
      if not countProps.relativePosition then countProps.relativePosition = BottomRight end
      if not countProps.position then countProps.position = UtilVector2(-3, -3) end
    end
    content[#content + 1] = text { text = ToString(options.count), props = countProps }
  end

  local external
  if options.external then
    external = {}
    for key, value in Next, options.external do
      external[key] = value
    end
  end

  local layout = {
    name = options.name,
    props = props,
    external = external,
    events = activationEvents(options.events, options.onActivate),
    userData = options.userData,
    content = UiContent(content),
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
