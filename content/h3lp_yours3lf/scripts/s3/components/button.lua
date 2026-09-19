---@omw-context menu|player

local emptyOptions = {}
local activationEvents = require 'scripts.s3.components.activationEvents'
local appearance = require 'scripts.s3.ui.appearance'
local chrome = require 'scripts.s3.ui.chrome'
local inset = require 'scripts.s3.components.inset'
local surface = require 'scripts.s3.ui.surface'
local text = require 'scripts.s3.components.text'
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local fullSize = util.vector2(1, 1)
local ButtonPaddingX = 8
local ButtonPaddingY = 4

---@class H3.ButtonOptions
---@field label? string
---@field padding? number Uniform slot inset in pixels. Defaults to roomy button padding.
---@field onActivate? fun(event: table, layout: openmw.ui.Layout): any
---@field name? string
---@field props? table
---@field labelProps? table
---@field external? table
---@field events? table
---@field userData? any
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field children? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field template? openmw.ui.Template

---Build a text button. Prefer `onActivate` over raw `events.mouseClick`.
---@param options? H3.ButtonOptions
---@return openmw.ui.Layout
local function button(options)
  options = options or emptyOptions

  local labelProps = {
    textColor = appearance.token 'color.text',
    textSize = appearance.token 'textSize.normal',
  }
  for key, value in next, options.labelProps or {} do
    labelProps[key] = value
  end
  if labelProps.ignorePointerEvents == nil then labelProps.ignorePointerEvents = true end

  local children = options.content or options.children
  local fixedSize = options.props
    and (options.props.size ~= nil or options.props.relativeSize ~= nil)
  if not children then
    if fixedSize then
      labelProps.autoSize = false
      labelProps.relativeSize = fullSize
      labelProps.textAlignH = ui.ALIGNMENT.Center
      labelProps.textAlignV = ui.ALIGNMENT.Center
    end
    local label = text { text = options.label, props = labelProps }
    local padX, padY = ButtonPaddingX, ButtonPaddingY
    if options.padding ~= nil then
      assert(
        type(options.padding) == 'number' and options.padding >= 0,
        'H3 button padding must be non-negative'
      )
      padX, padY = options.padding, options.padding
    end
    children = fixedSize and { label } or { inset(label, nil, padX, padY) }
  end

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
  if options.template then
    return {
      template = options.template,
      name = options.name,
      props = props,
      external = external,
      events = events,
      userData = options.userData,
      content = ui.content(children),
    }
  end

  local frame = fixedSize and chrome.frame or surface.build
  return frame {
    skin = appearance.chrome 'frame.button',
    name = options.name,
    props = props,
    external = external,
    events = events,
    userData = options.userData,
    tint = appearance.token 'color.chromeBorder',
    alpha = appearance.token 'transparency.chrome',
    content = children,
  }
end

return button
