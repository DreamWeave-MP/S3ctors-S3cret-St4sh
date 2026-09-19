---@omw-context menu|player

local emptyOptions = {}

local appearance = require 'scripts.s3.ui.appearance'
local button = require 'scripts.s3.components.button'
local chrome = require 'scripts.s3.ui.chrome'
local row = require 'scripts.s3.components.row'
local textInput = require 'scripts.s3.components.textInput'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local UtilVector2 = util.vector2
local defaultInputWidth = 150

---@class H3.SearchInputOptions
---@field value? string
---@field onChange? fun(value: string, layout: openmw.ui.Layout): any
---@field onCommit? fun(value: string, layout: openmw.ui.Layout): any Runs when editing focus is released.
---@field clearable? boolean
---@field clearLabel? string
---@field bordered? boolean
---@field gap? number
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any
---@field inputProps? table
---@field inputExternal? table
---@field inputEvents? table
---@field template? openmw.ui.Template

---@param options? H3.SearchInputOptions
---@return openmw.ui.Layout
local function searchInput(options)
  options = options or emptyOptions

  local inputProps = {}
  for key, value in next, options.inputProps or {} do
    inputProps[key] = value
  end
  if inputProps.textAlignV == nil then inputProps.textAlignV = ui.ALIGNMENT.Center end

  local input = textInput {
    name = 'input',
    text = options.value or '',
    props = inputProps,
    external = options.inputExternal,
    events = options.inputEvents,
    userData = options.userData,
    template = options.template,
    onChange = options.onChange,
    onCommit = options.onCommit,
  }

  local inputContent = input
  if options.bordered ~= false then
    local minHeight = appearance.token 'textSize.normal' + 2 * appearance.token 'border.normal'
    local size = inputProps.size
    local width = size and size.x or defaultInputWidth
    local height = math.max(size and size.y or minHeight + 4, minHeight + 4)
    local inset = 2
    input.props.size = UtilVector2(math.max(0, width - 2 * inset), height - 2 * inset)
    inputContent = chrome.frame {
      skin = appearance.chrome 'frame.thin',
      props = { size = UtilVector2(width, height) },
      tint = appearance.token 'color.chromeBorder',
      alpha = appearance.token 'transparency.chrome',
      inset = inset,
      content = { input },
    }
  end

  local children = { inputContent }
  if options.clearable ~= false then
    children[#children + 1] = button {
      name = 'clear',
      label = options.clearLabel or 'X',
      padding = 3,
      onActivate = function()
        input.props.text = ''
        if options.onChange then options.onChange('', input) end
        if options.onCommit then options.onCommit('', input) end
        return true
      end,
    }
  end

  return row {
    name = options.name,
    props = options.props,
    external = options.external,
    events = options.events,
    userData = options.userData,
    gap = options.gap or 4,
    children = children,
  }
end

return searchInput
