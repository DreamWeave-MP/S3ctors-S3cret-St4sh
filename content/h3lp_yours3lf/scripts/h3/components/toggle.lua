---@omw-context menu|player

local button = require 'scripts.h3.components.button'

local StrFormat = string.format

local EmptyOptions = {}

---@param layout openmw.ui.Layout
---@return openmw.ui.Layout?
local function labelLayout(layout)
  local result = layout.content[1]
  while result.content do
    result = result.content[1]
  end
  return result
end

---@param options? H3.ToggleOptions
---@return openmw.ui.Layout
local function toggle(options)
  options = options or EmptyOptions

  local value = options.value == true
  local onLabel = options.onLabel or 'On'
  local offLabel = options.offLabel or 'Off'
  local prefix = options.label
  local enabled = prefix and StrFormat('%s: %s', prefix, onLabel) or onLabel
  local disabled = prefix and StrFormat('%s: %s', prefix, offLabel) or offLabel

  return button {
    name = options.name,
    label = value and enabled or disabled,
    props = options.props,
    labelProps = options.labelProps,
    external = options.external,
    events = options.events,
    userData = options.userData,
    template = options.template,
    ---@param event openmw.ui.MouseEvent
    ---@param layout openmw.ui.Layout
    ---@return boolean
    onActivate = function(event, layout)
      value = not value
      labelLayout(layout).props.text = value and enabled or disabled
      if options.onChange then options.onChange(value, layout) end
      return true
    end,
  }
end

return toggle
