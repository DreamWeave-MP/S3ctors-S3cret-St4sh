---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local activationEvents = require 'scripts.h3.components.activationEvents'
local appearance = require 'scripts.h3.ui.appearance'
local chrome = require 'scripts.h3.ui.chrome'
local inset = require 'scripts.h3.components.inset'
local surface = require 'scripts.h3.ui.surface'
local text = require 'scripts.h3.components.text'

local Assert, Next, Type = assert, next, type

local UiAlignment, UiContent, UtilVector2 = ui.ALIGNMENT, ui.content, util.vector2

local EmptyOptions = {}

local FullSize = UtilVector2(1, 1)

local ButtonPaddingX, ButtonPaddingY = 8, 4

---Build a text button. Prefer `onActivate` over raw `events.mouseClick`.
---@param options? H3.ButtonOptions
---@return openmw.ui.Layout
local function button(options)
  options = options or EmptyOptions

  local labelProps = {}
  if options.labelProps then
    for key, value in Next, options.labelProps do
      labelProps[key] = value
    end
  end

  if not labelProps.textColor then labelProps.textColor = appearance.token 'color.text' end
  if not labelProps.textSize then labelProps.textSize = appearance.token 'textSize.normal' end
  if labelProps.ignorePointerEvents == nil then labelProps.ignorePointerEvents = true end

  local children = options.content or options.children
  local fixedSize = options.props and (options.props.size or options.props.relativeSize)
  if not children then
    if fixedSize then
      labelProps.autoSize = false
      labelProps.relativeSize = FullSize
      labelProps.textAlignH = UiAlignment.Center
      labelProps.textAlignV = UiAlignment.Center
    end
    local label = text { text = options.label, props = labelProps }
    local padX, padY = ButtonPaddingX, ButtonPaddingY
    if options.padding then
      Assert(
        Type(options.padding) == 'number' and options.padding >= 0,
        'H3 button padding must be non-negative'
      )
      padX, padY = options.padding, options.padding
    end
    children = fixedSize and { label } or { inset(label, nil, padX, padY) }
  end

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
  if options.template then
    return {
      template = options.template,
      name = options.name,
      props = props,
      external = external,
      events = events,
      userData = options.userData,
      content = UiContent(children),
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
