---@omw-context menu|player

local async = require 'openmw.async'

local button = require 'scripts.s3.components.button'

local emptyOptions = {}
local StrFormat = string.format

---@class H3.ToggleOptions
---@field value? boolean
---@field onChange? fun(value: boolean)
---@field onLabel? string
---@field offLabel? string
---@field name? string
---@field props? table
---@field labelProps? table
---@field external? table
---@field events? table
---@field userData? any
---@field template? openmw.ui.Template
---@field label? string Prefix shown before the state label.

---Build a state-labelled yes/no button. The event mutates its label before notifying the caller.
---@param options? H3.ToggleOptions
---@return openmw.ui.Layout
local function toggle(options)
  options = options or emptyOptions

  local value = options.value == true
  local onLabel = options.onLabel or 'On'
  local offLabel = options.offLabel or 'Off'
  local prefix = options.label
  local onChange = options.onChange
  local events = {}

  if options.events then
    for key, event in next, options.events do
      events[key] = event
    end
  end

  local enabledLabel = prefix and StrFormat('%s: %s', prefix, onLabel) or onLabel
  local disabledLabel = prefix and StrFormat('%s: %s', prefix, offLabel) or offLabel

  local previousClick = events.mouseClick
  events.mouseClick = async:callback(function(event, layout)
    value = not value
    layout.content[1].content[1].props.text = value and enabledLabel or disabledLabel

    if onChange then onChange(value) end
    if previousClick then return previousClick(event, layout) end
    return true
  end)

  return button {
    name = options.name,
    label = value and enabledLabel or disabledLabel,
    props = options.props,
    labelProps = options.labelProps,
    external = options.external,
    events = events,
    userData = options.userData,
    template = options.template,
  }
end

return toggle
