---@omw-context menu|player

local emptyOptions = {}
local appearance = require 'scripts.s3.ui.appearance'
local async = require 'openmw.async'
local chrome = require 'scripts.s3.ui.chrome'
local inset = require 'scripts.s3.components.inset'
local text = require 'scripts.s3.components.text'
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local fullSize = util.vector2(1, 1)

local function eventsFor(options)
  local events = {}
  for key, value in next, options.events or {} do
    events[key] = value
  end
  if options.onActivate then
    local previous = events.mouseClick
    events.mouseClick = async:callback(function(event, layout)
      local result = options.onActivate(event, layout)
      if previous then
        local previousResult = previous(event, layout)
        if previousResult ~= nil then return previousResult end
      end
      if result ~= nil then return result end
      return true
    end)
  end
  return next(events) and events or nil
end

---Build a text button. Prefer `onActivate` over raw `events.mouseClick`.
---@param options? table
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

  local events = eventsFor(options)
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
