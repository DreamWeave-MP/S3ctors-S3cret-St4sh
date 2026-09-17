---@omw-context menu|player

local emptyOptions = {}

local activationEvents = require 'scripts.s3.components.activationEvents'
local appearance = require 'scripts.s3.ui.appearance'
local chrome = require 'scripts.s3.ui.chrome'
local image = require 'scripts.s3.components.image'
local text = require 'scripts.s3.components.text'
local ui = require 'openmw.ui'

---@class H3.ItemSlotOptions
---@field resource? openmw.ui.TextureResource|openmw.ui.TextureResourceOptions
---@field count? string|number
---@field onActivate? fun(event: table, layout: openmw.ui.Layout): any
---@field name? string
---@field props? table
---@field iconProps? table
---@field countProps? table
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

  local iconProps = {}
  if options.iconProps then
    for key, value in next, options.iconProps do
      iconProps[key] = value
    end
  end

  if options.resource ~= nil then iconProps.resource = options.resource end
  iconProps.ignorePointerEvents = true

  local content = {
    image { name = 'icon', resource = options.resource, props = iconProps },
  }
  if options.count ~= nil then
    local countProps = {
      textColor = appearance.token 'color.count',
      textSize = appearance.token 'textSize.normal',
    }
    if options.countProps then
      for key, value in next, options.countProps do
        countProps[key] = value
      end
    end

    countProps.ignorePointerEvents = true
    content[#content + 1] = text { text = tostring(options.count), props = countProps }
  end

  local props = {}
  if options.props then
    for key, value in next, options.props do
      props[key] = value
    end
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

  return chrome.box {
    skin = appearance.chrome 'frame.thin',
    name = layout.name,
    props = layout.props,
    external = layout.external,
    events = layout.events,
    userData = layout.userData,
    tint = appearance.token 'color.chromeBorder',
    alpha = appearance.token 'transparency.chrome',
    content = content,
  }
end

return itemSlot
