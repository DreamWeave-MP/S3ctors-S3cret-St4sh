---@omw-context menu|player

local emptyOptions = {}

local I = require 'openmw.interfaces'
local appearance = require 'scripts.s3.ui.appearance'
local async = require 'openmw.async'
local ui = require 'openmw.ui'

---Build a list item row layout.
---Allocates fresh row, props, external, and content tables. If `content`/`children` is omitted, a text
---label child is created. The caller owns events and mounted element lifetime.
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

---@param options? {label?: string, name?: string, props?: table, labelProps?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.LayoutOrElement[], children?: openmw.ui.Content|openmw.ui.LayoutOrElement[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function listItem(options)
  options = options or emptyOptions

  local labelProps = {
    textColor = appearance.token 'color.text',
    textSize = appearance.token 'textSize.normal',
  }
  if options.labelProps then
    for key, value in next, options.labelProps do
      labelProps[key] = value
    end
  end

  if options.label ~= nil then labelProps.text = options.label end
  if labelProps.ignorePointerEvents == nil then labelProps.ignorePointerEvents = true end

  local children = options.content
    or options.children
    or {
      {
        template = I.MWUI.templates.textNormal,
        props = labelProps,
      },
    }

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

  return {
    template = options.template or I.MWUI.templates.padding,
    name = options.name,
    props = props,
    external = external,
    events = activationEvents(options),
    userData = options.userData,
    content = ui.content(children),
  }
end

return listItem
