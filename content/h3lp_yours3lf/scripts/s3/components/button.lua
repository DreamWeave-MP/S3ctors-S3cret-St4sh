---@omw-context menu|player

local emptyOptions = {}
local activationEvents = require 'scripts.s3.components.activationEvents'
local appearance = require 'scripts.s3.ui.appearance'
local chrome = require 'scripts.s3.ui.chrome'
local inset = require 'scripts.s3.components.inset'
local text = require 'scripts.s3.components.text'
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local fullSize = util.vector2(1, 1)

---@class H3.ButtonOptions
---@field label? string
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
  local fixedSize = options.props and options.props.size ~= nil
  if not children then
    if fixedSize then
      labelProps.autoSize = false
      labelProps.relativeSize = fullSize
      labelProps.textAlignH = ui.ALIGNMENT.Center
      labelProps.textAlignV = ui.ALIGNMENT.Center
    end
    local label = text { text = options.label, props = labelProps }
    children = fixedSize and { label } or { inset(label) }
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

  local frame = fixedSize and chrome.frame or chrome.box
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
