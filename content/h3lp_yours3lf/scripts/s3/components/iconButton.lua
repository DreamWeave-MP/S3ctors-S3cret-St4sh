---@omw-context menu|player

local emptyOptions = {}

local activationEvents = require 'scripts.s3.components.activationEvents'
local appearance = require 'scripts.s3.ui.appearance'
local image = require 'scripts.s3.components.image'
local inset = require 'scripts.s3.components.inset'
local row = require 'scripts.s3.components.row'
local surface = require 'scripts.s3.ui.surface'
local text = require 'scripts.s3.components.text'
local ui = require 'openmw.ui'

local IconButtonPadding = 4

---@class H3.IconButtonOptions
---@field resource? openmw.ui.TextureResource|openmw.ui.TextureResourceOptions
---@field label? string
---@field selected? boolean Highlight the button using the active theme color.
---@field onActivate? fun(event: table, layout: openmw.ui.Layout): any
---@field gap? number
---@field name? string
---@field props? table
---@field iconProps? table
---@field labelProps? table
---@field external? table
---@field events? table
---@field userData? any
---@field template? openmw.ui.Template

---Build a button with an icon and optional label.
---@param options? H3.IconButtonOptions
---@return openmw.ui.Layout
local function iconButton(options)
  options = options or emptyOptions

  local iconProps = {}
  for key, value in next, options.iconProps or {} do
    iconProps[key] = value
  end
  if options.resource ~= nil then iconProps.resource = options.resource end
  iconProps.ignorePointerEvents = true

  local children = { image { resource = options.resource, props = iconProps } }
  if options.label ~= nil then
    local labelProps = {}
    for key, value in next, options.labelProps or {} do
      labelProps[key] = value
    end
    if labelProps.textColor == nil and options.selected then
      labelProps.textColor = appearance.token 'color.active'
    end
    labelProps.ignorePointerEvents = true
    children[#children + 1] = text { text = options.label, props = labelProps }
  end

  local content = row {
    gap = options.gap or 4,
    props = { arrange = ui.ALIGNMENT.Center, ignorePointerEvents = true },
    children = children,
  }

  local props = {}
  for key, value in next, options.props or {} do
    props[key] = value
  end
  local external
  if options.external then
    external = {}
    for key, value in next, options.external do
      external[key] = value
    end
  end

  local events = activationEvents(options.events, options.onActivate)
  local padded = inset(content, nil, IconButtonPadding)

  if options.template then
    return {
      template = options.template,
      name = options.name,
      props = props,
      external = external,
      events = events,
      userData = options.userData,
      content = ui.content { padded },
    }
  end

  return surface.build {
    skin = appearance.chrome 'frame.button',
    name = options.name,
    props = props,
    external = external,
    events = events,
    userData = options.userData,
    tint = appearance.token(options.selected and 'color.active' or 'color.chromeBorder'),
    alpha = appearance.token 'transparency.chrome',
    content = { padded },
  }
end

return iconButton
