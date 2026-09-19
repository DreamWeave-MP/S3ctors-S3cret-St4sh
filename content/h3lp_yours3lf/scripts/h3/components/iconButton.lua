---@omw-context menu|player

local ui = require 'openmw.ui'

local activationEvents = require 'scripts.h3.components.activationEvents'
local appearance = require 'scripts.h3.ui.appearance'
local image = require 'scripts.h3.components.image'
local inset = require 'scripts.h3.components.inset'
local row = require 'scripts.h3.components.row'
local surface = require 'scripts.h3.ui.surface'
local text = require 'scripts.h3.components.text'

local Next = next

local UiAlignment, UiContent = ui.ALIGNMENT, ui.content

local EmptyOptions = {}
local IconButtonPadding = 4

---Build a button with an icon and optional label.
---@param options? H3.IconButtonOptions
---@return openmw.ui.Layout
local function iconButton(options)
  options = options or EmptyOptions

  local iconProps = {}
  if options.iconProps then
    for key, value in Next, options.iconProps do
      iconProps[key] = value
    end
  end

  if options.resource then iconProps.resource = options.resource end
  iconProps.ignorePointerEvents = true

  local children = { image { resource = options.resource, props = iconProps } }
  if options.label then
    local labelProps = {}
    if options.labelProps then
      for key, value in Next, options.labelProps do
        labelProps[key] = value
      end
    end

    if not labelProps.textColor then labelProps.textColor = appearance.token 'color.text' end
    labelProps.ignorePointerEvents = true
    children[#children + 1] = text { text = options.label, props = labelProps }
  end

  local content = row {
    gap = options.gap or 4,
    props = { arrange = UiAlignment.Center, ignorePointerEvents = true },
    children = children,
  }

  local props = {}
  if options.props then
    for key, value in Next, options.props do
      props[key] = value
    end
  end

  local external
  if options.external then
    external = {}
    for key, value in Next, options.external do
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
      content = UiContent { padded },
    }
  end

  return surface.build {
    skin = appearance.chrome 'frame.button',
    name = options.name,
    props = props,
    external = external,
    events = events,
    userData = options.userData,
    tint = appearance.token 'color.chromeBorder',
    alpha = appearance.token 'transparency.chrome',
    selected = {
      props = options.selectionProps,
      tint = appearance.token 'color.active',
      alpha = appearance.token 'transparency.chrome',
    },
    content = { padded },
  }
end

return iconButton
