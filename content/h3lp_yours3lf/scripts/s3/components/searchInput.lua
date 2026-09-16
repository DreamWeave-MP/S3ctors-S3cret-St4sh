---@omw-context menu|player

local emptyOptions = {}

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local appearance = require 'scripts.s3.ui.appearance'
local button = require 'scripts.s3.components.button'
local chrome = require 'scripts.s3.ui.chrome'
local constants = require 'scripts.omw.mwui.constants'
local row = require 'scripts.s3.components.row'
local textInput = require 'scripts.s3.components.textInput'

local UtilVector2 = util.vector2
local inputPadding = 2 * constants.border * 2
local defaultInputWidth = 150

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

---@param options? H3.SearchInputOptions
---@return openmw.ui.Layout
local function searchInput(options)
  options = options or emptyOptions

  local initialValue = options.value or ''
  local onChange = options.onChange
  local inputLayout
  local input
  local inputProps = {}
  local inputEvents = {}

  if options.inputProps then
    for key, value in next, options.inputProps do
      inputProps[key] = value
    end
  end

  if options.bordered ~= false then
    local minimumInputHeight = (appearance.token 'textSize.normal' or constants.textNormalSize)
      + 2 * constants.border
    local inputSize = inputProps.size
    local inputWidth = inputSize and inputSize.x or defaultInputWidth
    local inputHeight = inputSize and inputSize.y or minimumInputHeight + inputPadding
    inputProps.size =
      UtilVector2(inputWidth, math.max(minimumInputHeight, inputHeight - inputPadding))
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

  input = textInput {
    name = 'input',
    text = initialValue,
    props = inputProps,
    external = options.inputExternal,
    events = inputEvents,
    userData = options.userData,
    template = options.template,
  }

  local inputContent = input
  if options.bordered ~= false then
    local paddedInput = {
      template = I.MWUI.templates.padding,
      props = { ignorePointerEvents = false },
      content = ui.content { input },
    }
    local spacedInput = {
      template = I.MWUI.templates.padding,
      props = { ignorePointerEvents = false },
      content = ui.content { paddedInput },
    }
    inputContent = chrome.box {
      skin = appearance.chrome 'frame.thin',
      tint = appearance.token 'color.chromeBorder',
      alpha = appearance.token 'transparency.chrome',
      content = { spacedInput },
    }
  end

  local children = { inputContent }

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

  inputLayout = input
  return layout
end

return searchInput
