---@omw-context player

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local util = require 'openmw.util'

local column = require 'scripts.s3.components.column'
local constants = require 'scripts.omw.mwui.constants'
local numberInput = require 'scripts.s3.components.numberInput'
local pinButton = require 'scripts.s3.components.pinButton'
local row = require 'scripts.s3.components.row'
local searchInput = require 'scripts.s3.components.searchInput'
local slider = require 'scripts.s3.components.slider'
local text = require 'scripts.s3.components.text'
local toggle = require 'scripts.s3.components.toggle'

local UtilVector2 = util.vector2
local StrFormat = string.format
local sliderSize = UtilVector2(220, 18)
local inputSize = UtilVector2(120, 24)
local headerTextProps = {
  textColor = constants.headerColor,
  textSize = constants.textHeaderSize,
}

local function makeCounter(label)
  local semantic = 0
  local lowLevel = 0
  local status = text {
    text = StrFormat('%s: semantic=0 low=0', label),
  }

  local function redraw()
    status.props.text = StrFormat('%s: semantic=%d low=%d', label, semantic, lowLevel)
    I.H3ComponentTest.refresh()
  end

  local function semanticHit()
    semantic = semantic + 1
    redraw()
  end

  local function lowHit()
    lowLevel = lowLevel + 1
    redraw()
    return true
  end

  return status, semanticHit, lowHit
end

---@return openmw.ui.Layout
local function eventComposition()
  local toggleStatus, toggleSemanticHit, toggleLowHit = makeCounter 'Toggle'
  local pinStatus, pinSemanticHit, pinLowHit = makeCounter 'Pin button (no bubble)'
  local sliderStatus, sliderSemanticHit, sliderLowHit = makeCounter 'Slider (drag)'
  local numberStatus, numberSemanticHit, numberLowHit = makeCounter 'Number input (type, then blur)'
  local searchStatus, searchSemanticHit, searchLowHit = makeCounter 'Search input (type or clear)'
  local bubbled = 0
  local bubbleStatus = text {
    text = 'Root bubbles (toggle/search clicks): 0',
  }

  local rootEvents = {
    mouseClick = async:callback(function()
      bubbled = bubbled + 1
      bubbleStatus.props.text = StrFormat('Root bubbles (toggle/search clicks): %d', bubbled)
      I.H3ComponentTest.refresh()
      return true
    end),
  }

  return column {
    name = 'ct_demo_event_composition',
    events = rootEvents,
    children = {
      text {
        text = 'Callback layers: semantic callbacks, raw handlers, and bubbling',
        props = headerTextProps,
      },
      text {
        text = 'semantic = component callback | low = supplied raw event | root = bubbled click',
      },
      toggleStatus,

      row {
        children = {
          toggle {
            label = 'Toggle',
            onChange = toggleSemanticHit,
            events = { mouseClick = async:callback(toggleLowHit) },
          },
          pinButton {
            onToggle = pinSemanticHit,
            events = { mouseClick = async:callback(pinLowHit) },
          },
        },
      },

      pinStatus,
      bubbleStatus,
      sliderStatus,
      slider {
        value = 50,
        min = 0,
        max = 100,
        props = { size = sliderSize },
        onChange = sliderSemanticHit,
        events = {
          mousePress = async:callback(sliderLowHit),
          mouseMove = async:callback(sliderLowHit),
          mouseRelease = async:callback(sliderLowHit),
        },
      },

      numberStatus,
      numberInput {
        value = 2,
        min = 0,
        max = 10,
        props = { size = inputSize },
        onChange = numberSemanticHit,
        onCommit = I.H3ComponentTest.refresh,
        events = {
          textChanged = async:callback(numberLowHit),
          focusLoss = async:callback(numberLowHit),
        },
      },

      searchStatus,
      searchInput {
        value = 'compose',
        onChange = searchSemanticHit,
        inputEvents = {
          textChanged = async:callback(searchLowHit),
        },
        events = {
          mouseClick = async:callback(searchLowHit),
        },
      },
    },
  }
end

return eventComposition
