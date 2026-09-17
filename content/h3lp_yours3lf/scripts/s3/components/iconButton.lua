---@omw-context menu|player

local emptyOptions = {}

local appearance = require 'scripts.s3.ui.appearance'
local async = require 'openmw.async'
local chrome = require 'scripts.s3.ui.chrome'
local image = require 'scripts.s3.components.image'
local inset = require 'scripts.s3.components.inset'
local row = require 'scripts.s3.components.row'
local text = require 'scripts.s3.components.text'
local ui = require 'openmw.ui'

local function activationEvents(options)
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

---Build a button with an icon and optional label.
---@param options? table
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

  local events = activationEvents(options)
  local padded = inset(content)

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

  return chrome.box {
    skin = appearance.chrome 'frame.button',
    name = options.name,
    props = props,
    external = external,
    events = events,
    userData = options.userData,
    tint = appearance.token 'color.chromeBorder',
    alpha = appearance.token 'transparency.chrome',
    content = { padded },
  }
end

return iconButton
