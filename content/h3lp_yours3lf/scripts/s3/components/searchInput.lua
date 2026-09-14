---@omw-context menu|player

local emptyOptions = {}

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local auxUi = require 'openmw_aux.ui'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local constants = require 'scripts.omw.mwui.constants'

local button = require 'scripts.s3.components.button'
local row = require 'scripts.s3.components.row'
local textInput = require 'scripts.s3.components.textInput'

---@class H3.SearchInputOptions
---@field value? string
---@field onChange? fun(value: string)
---@field clearable? boolean
---@field clearLabel? string
---@field bordered? boolean
---@field name? string
---@field props? table
---@field inputProps? table
---@field inputEvents? table
---@field inputExternal? table
---@field external? table
---@field events? table
---@field userData? any
---@field template? openmw.ui.Template

local function borderedTemplate(template)
  local result = auxUi.deepLayoutCopy(template)
  local content = result.content or ui.content {}

  content:add {
    template = I.MWUI.templates.horizontalLine,
  }
  content:add {
    template = I.MWUI.templates.horizontalLine,
    props = {
      position = util.vector2(0, -constants.border),
      relativePosition = util.vector2(0, 1),
    },
  }
  content:add {
    template = I.MWUI.templates.verticalLine,
  }

  result.content = content
  return result
end

---@param options? H3.SearchInputOptions
---@return openmw.ui.Layout
local function searchInput(options)
  options = options or emptyOptions

  local initialValue = options.value or ''
  local onChange = options.onChange
  local inputLayout
  local inputProps = {}
  local inputEvents = {}

  if options.inputProps then
    for key, value in next, options.inputProps do
      inputProps[key] = value
    end
  end

  if inputProps.textAlignV == nil then inputProps.textAlignV = ui.ALIGNMENT.Center end

  if options.inputEvents then
    for key, event in next, options.inputEvents do
      inputEvents[key] = event
    end
  end

  local previousTextChanged = inputEvents.textChanged
  inputEvents.textChanged = async:callback(function(text, layout)
    layout.props.text = text

    if onChange then onChange(text) end
    if previousTextChanged then return previousTextChanged(text, layout) end
    return true
  end)

  local children = {
    textInput {
      name = 'input',
      text = initialValue,
      props = inputProps,
      external = options.inputExternal,
      events = inputEvents,
      userData = options.userData,
      template = options.bordered == false and options.template
        or borderedTemplate(options.template or I.MWUI.templates.textEditLine),
    },
  }

  if options.clearable ~= false then
    children[#children + 1] = button {
      name = 'clear',
      label = options.clearLabel or 'X',
      events = {
        mouseClick = async:callback(function()
          inputLayout.props.text = ''

          if onChange then onChange '' end
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
