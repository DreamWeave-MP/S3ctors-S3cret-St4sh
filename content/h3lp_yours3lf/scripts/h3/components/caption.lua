---@omw-context menu|player

local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local appearance = require 'scripts.h3.ui.appearance'
local button = require 'scripts.h3.components.button'
local headBlock = require 'scripts.h3.components.headBlock'
local pinButton = require 'scripts.h3.components.pinButton'
local row = require 'scripts.h3.components.row'
local spacer = require 'scripts.h3.components.spacer'
local text = require 'scripts.h3.components.text'

local Assert, Next = assert, next

local UiAlignment, UiContent, UiType, UtilVector2 = ui.ALIGNMENT, ui.content, ui.TYPE, util.vector2

local EmptyOptions = {}

local ControlSize, Zero, RelativeWidth = UtilVector2(20, 20), UtilVector2(0, 0), UtilVector2(1, 0)

local HeadBlockWidth, CaptionTextPadding = 30, 12

---@param options? H3.CaptionOptions
---@return openmw.ui.Layout
local function caption(options)
  options = options or EmptyOptions

  local height = options.height or 20
  local minimumHeight = (options.pinnable or options.closable) and ControlSize.y or 4
  Assert(height >= minimumHeight, 'Caption height is too small for its controls')

  local heightSize = UtilVector2(0, height)
  local props = {}
  if options.props then
    for key, value in Next, options.props do
      props[key] = value
    end
  end

  props.size = props.size or heightSize
  props.relativeSize = props.relativeSize or RelativeWidth
  props.horizontal = true
  props.autoSize = false
  props.arrange = props.arrange or UiAlignment.Center

  local textProps = {}
  if options.textProps then
    for key, value in Next, options.textProps do
      textProps[key] = value
    end
  end

  if not textProps.textSize then textProps.textSize = appearance.token 'textSize.normal' end
  if not textProps.textColor then textProps.textColor = appearance.token 'color.text' end

  ---@param input? table
  ---@return table
  local function controlProps(input)
    local control = {}
    if input then
      for key, value in Next, input do
        control[key] = value
      end
    end

    control.size = control.size or ControlSize
    Assert(control.size.y <= height, 'Caption control is taller than the caption')
    control.propagateEvents = false
    return control
  end

  local children = {
    headBlock {
      props = {
        size = UtilVector2(HeadBlockWidth, height),
        relativeSize = Zero,
      },
      external = { grow = 1 },
      height = height,
    },

    row {
      name = 'text',
      props = { arrange = UiAlignment.Center },
      children = {
        spacer(CaptionTextPadding, 0),
        text {
          text = options.text or '',
          props = textProps,
        },
        spacer(CaptionTextPadding, 0),
      },
    },

    headBlock {
      props = {
        size = UtilVector2(HeadBlockWidth, height),
        relativeSize = Zero,
      },
      external = { grow = 1 },
      height = height,
    },
  }

  if options.pinnable then
    children[#children + 1] = pinButton {
      name = 'pin',
      pinned = options.pinned,
      onToggle = options.onPin,
      props = controlProps(options.pinProps),
    }
  end

  if options.closable then
    local onClose = options.onClose
    children[#children + 1] = button {
      name = 'close',
      label = options.closeLabel or 'X',
      props = controlProps(options.closeProps),
      events = {
        mouseClick = async:callback(
          ---@return nil
          function()
            if onClose then onClose() end
          end
        ),
      },
    }
  end

  return {
    type = UiType.Flex,
    name = options.name,
    props = props,
    external = options.external,
    events = options.events,
    userData = options.userData,
    content = UiContent(children),
  }
end

return caption
