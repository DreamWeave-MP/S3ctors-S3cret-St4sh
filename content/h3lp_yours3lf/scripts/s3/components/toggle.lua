---@omw-context menu|player

local async = require 'openmw.async'

local button = require 'scripts.s3.components.button'

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
  options = options or {}
  local value = options.value == true
  local events = {}

  for key, event in pairs(options.events or {}) do
    events[key] = event
  end

  local previousClick = events.mouseClick
  events.mouseClick = async:callback(function(event, layout)
    value = not value
    local stateLabel = value and (options.onLabel or 'On') or (options.offLabel or 'Off')
    local label = options.label and options.label .. ': ' .. stateLabel or stateLabel
    local labelLayout = layout.content[1].content[1]
    labelLayout.props.text = label

    if options.onChange then options.onChange(value) end
    if previousClick then return previousClick(event, layout) end
    return true
  end)

  return button {
    name = options.name,
    label = options.label
        and options.label .. ': ' .. (value and (options.onLabel or 'On') or (options.offLabel or 'Off'))
      or (value and (options.onLabel or 'On') or (options.offLabel or 'Off')),
    props = options.props,
    labelProps = options.labelProps,
    external = options.external,
    events = events,
    userData = options.userData,
    template = options.template,
  }
end

return toggle
