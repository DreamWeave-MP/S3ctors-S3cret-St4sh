---@omw-context menu|player

local emptyOptions = {}

local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local appearance = require 'scripts.s3.ui.appearance'
local button = require 'scripts.s3.components.button'
local constants = require 'scripts.omw.mwui.constants'
local headBlock = require 'scripts.s3.components.headBlock'
local pinButton = require 'scripts.s3.components.pinButton'
local row = require 'scripts.s3.components.row'
local spacer = require 'scripts.s3.components.spacer'
local text = require 'scripts.s3.components.text'

local UtilVector2 = util.vector2

local controlSize = UtilVector2(20, 20)
local headBlockWidth = 30
local captionTextPadding = 12
local zero = UtilVector2(0, 0)
local relativeWidth = UtilVector2(1, 0)

---@class H3.CaptionOptions
---@field text? string
---@field pinnable? boolean
---@field pinned? boolean
---@field onPin? fun(pinned: boolean)
---@field closable? boolean
---@field onClose? fun()
---@field closeLabel? string
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any
---@field height? number
---@field textProps? table
---@field pinProps? table
---@field closeProps? table

---@param options? H3.CaptionOptions
---@return openmw.ui.Layout
local function caption(options)
  options = options or emptyOptions

  local height = options.height or 20
  local minimumHeight = (options.pinnable or options.closable) and controlSize.y or 4
  assert(height >= minimumHeight, 'Caption height is too small for its controls')

  local heightSize = UtilVector2(0, height)
  local props = {}
  if options.props then
    for key, value in next, options.props do
      props[key] = value
    end
  end

  props.size = props.size or heightSize
  props.relativeSize = props.relativeSize or relativeWidth
  props.horizontal = true
  props.autoSize = false
  props.arrange = props.arrange or ui.ALIGNMENT.Center

  local textProps = {
    textSize = appearance.token 'textSize.normal' or constants.textNormalSize,
    textColor = appearance.token 'color.text' or constants.normalColor,
  }
  if options.textProps then
    for key, value in next, options.textProps do
      textProps[key] = value
    end
  end

  local function controlProps(input)
    local control = {}
    if input then
      for key, value in next, input do
        control[key] = value
      end
    end

    control.size = control.size or controlSize
    assert(control.size.y <= height, 'Caption control is taller than the caption')
    control.propagateEvents = false
    return control
  end

  local children = {
    headBlock {
      props = {
        size = UtilVector2(headBlockWidth, height),
        relativeSize = zero,
      },
      external = { grow = 1 },
      height = height,
    },
    row {
      name = 'text',
      props = { arrange = ui.ALIGNMENT.Center },
      children = {
        spacer(captionTextPadding, 0),
        text {
          text = options.text or '',
          props = textProps,
        },
        spacer(captionTextPadding, 0),
      },
    },
    headBlock {
      props = {
        size = UtilVector2(headBlockWidth, height),
        relativeSize = zero,
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
        mousePress = async:callback(function() end),
        mouseClick = async:callback(function()
          if onClose then onClose() end
        end),
      },
    }
  end

  return {
    type = ui.TYPE.Flex,
    name = options.name,
    props = props,
    external = options.external,
    events = options.events,
    userData = options.userData,
    content = ui.content(children),
  }
end

return caption
