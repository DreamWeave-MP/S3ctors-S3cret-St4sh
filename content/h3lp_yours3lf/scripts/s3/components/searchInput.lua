---@omw-context menu|player

local async = require 'openmw.async'

local button = require 'scripts.s3.components.button'
local row = require 'scripts.s3.components.row'
local textInput = require 'scripts.s3.components.textInput'

---@class H3.SearchInputOptions
---@field value? string
---@field onChange? fun(value: string)
---@field clearable? boolean
---@field clearLabel? string
---@field name? string
---@field props? table
---@field inputProps? table
---@field inputEvents? table
---@field inputExternal? table
---@field external? table
---@field events? table
---@field userData? any
---@field template? openmw.ui.Template

---@param options? H3.SearchInputOptions
---@return openmw.ui.Layout
local function searchInput(options)
  options = options or {}
  local value = options.value or ''
  local inputLayout
  local inputEvents = {}

  for key, event in pairs(options.inputEvents or {}) do
    inputEvents[key] = event
  end

  local previousTextChanged = inputEvents.textChanged
  inputEvents.textChanged = async:callback(function(text, layout)
    value = text
    layout.props.text = value
    if options.onChange then options.onChange(value) end
    if previousTextChanged then return previousTextChanged(text, layout) end
    return true
  end)

  local children = {
    textInput {
      name = 'input',
      text = value,
      props = options.inputProps,
      external = options.inputExternal,
      events = inputEvents,
      userData = options.userData,
      template = options.template,
    },
  }

  if options.clearable ~= false then
    children[#children + 1] = button {
      name = 'clear',
      label = options.clearLabel or 'X',
      events = {
        mouseClick = async:callback(function()
          value = ''
          inputLayout.props.text = value
          if options.onChange then options.onChange(value) end
          return true
        end),
      },
    }
  end

  local layout = row {
    name = options.name,
    props = options.props,
    external = options.external,
    events = options.events,
    userData = options.userData,
    children = children,
  }
  inputLayout = children[1]
  return layout
end

return searchInput
