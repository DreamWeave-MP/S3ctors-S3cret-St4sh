---@omw-context menu|player

local emptyOptions = {}

local appearance = require 'scripts.s3.ui.appearance'
local eventHandlers = require 'scripts.s3.components.eventHandlers'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local UtilVector2 = util.vector2
local defaultSize = UtilVector2(150, 0)

---Build an H3UI-owned single-line TextEdit layout by default.
---Allocates fresh layout, props, and external tables. `onChange` is composed with any caller-supplied
---`events.textChanged` callback so normal application code does not need raw event plumbing.
---@class H3.TextInputOptions
---@field text? string
---@field onChange? fun(value: string, layout: openmw.ui.Layout): any
---@field onCommit? fun(value: string, layout: openmw.ui.Layout): any Runs when editing focus is released.
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any
---@field template? openmw.ui.Template

---@param options? H3.TextInputOptions
---@return openmw.ui.Layout
local function textInput(options)
  options = options or emptyOptions

  local props = {}
  if options.props then
    for key, value in next, options.props do
      props[key] = value
    end
  end
  if props.textColor == nil then props.textColor = appearance.token 'color.text' end
  if props.textSize == nil then props.textSize = appearance.token 'textSize.normal' end
  if options.template == nil then
    if props.size == nil then props.size = defaultSize end
    if props.autoSize == nil then props.autoSize = true end
    if props.multiline == nil then props.multiline = false end
    if props.textAlignV == nil then props.textAlignV = ui.ALIGNMENT.Center end
  end

  if options.text ~= nil then props.text = options.text end

  local external
  if options.external then
    external = {}
    for key, value in next, options.external do
      external[key] = value
    end
  end

  local events = {}
  for key, value in next, options.events or {} do
    events[key] = value
  end
  if options.onChange then
    eventHandlers.add(events, 'textChanged', function(value, layout)
      layout.props.text = value
      return options.onChange(value, layout)
    end, true)
  end
  if options.onCommit then
    eventHandlers.add(events, 'focusLoss', function(_, layout)
      return options.onCommit(layout.props.text or '', layout)
    end)
  end

  return {
    type = ui.TYPE.TextEdit,
    name = options.name,
    props = props,
    external = external,
    events = next(events) and events or nil,
    userData = options.userData,
    template = options.template,
  }
end

return textInput
