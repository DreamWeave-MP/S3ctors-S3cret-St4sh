---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local appearance = require 'scripts.h3.ui.appearance'
local button = require 'scripts.h3.components.button'
local chrome = require 'scripts.h3.ui.chrome'
local row = require 'scripts.h3.components.row'
local textInput = require 'scripts.h3.components.textInput'

local MathMax, Next = math.max, next

local UiAlignment, UtilVector2 = ui.ALIGNMENT, util.vector2

local EmptyOptions = {}

local DefaultInputWidth = 150

---@param options? H3.SearchInputOptions
---@return openmw.ui.Layout
local function searchInput(options)
  options = options or EmptyOptions

  local inputProps = {}
  if options.inputProps then
    for key, value in Next, options.inputProps do
      inputProps[key] = value
    end
  end
  if not inputProps.textAlignV then inputProps.textAlignV = UiAlignment.Center end

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
    local width = size and size.x or DefaultInputWidth
    local height = MathMax(size and size.y or minHeight + 4, minHeight + 4)
    local inset = 2
    input.props.size = UtilVector2(MathMax(0, width - 2 * inset), height - 2 * inset)
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
      ---@return boolean
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
