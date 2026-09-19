---@omw-context player

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local util = require 'openmw.util'

local appearance = require 'scripts.h3.ui.appearance'
local column = require 'scripts.h3.components.column'
local numberInput = require 'scripts.h3.components.numberInput'
local pinButton = require 'scripts.h3.components.pinButton'
local row = require 'scripts.h3.components.row'
local searchInput = require 'scripts.h3.components.searchInput'
local slider = require 'scripts.h3.components.slider'
local text = require 'scripts.h3.components.text'
local toggle = require 'scripts.h3.components.toggle'

local StrFormat = string.format

local UtilVector2 = util.vector2
local SliderSize, InputSize = UtilVector2(220, 18), UtilVector2(120, 24)

---@return table
local function headerTextProps()
  return {
    textColor = appearance.token 'color.header',
    textSize = appearance.token 'textSize.header',
  }
end

---@param label string
---@return openmw.ui.Layout status
---@return fun(): nil semanticHit
---@return fun(): boolean lowHit
local function makeCounter(label)
  local semantic = 0
  local lowLevel = 0
  local status = text {
    text = StrFormat('%s: semantic=0 low=0', label),
  }

  ---@return nil
  local function redraw()
    status.props.text = StrFormat('%s: semantic=%d low=%d', label, semantic, lowLevel)
    I.H3ComponentTest.refresh()
  end

  ---@return nil
  local function semanticHit()
    semantic = semantic + 1
    redraw()
  end

  ---@return boolean
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
  local searchStatus, searchSemanticHit, searchLowHit =
    makeCounter 'Search input (type, blur, or clear)'
  local bubbled = 0
  local bubbleStatus = text {
    text = 'Root bubbles (toggle/search clicks): 0',
  }

  local rootEvents = {
    mouseClick = async:callback(
      ---@return boolean
      function()
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
        props = headerTextProps(),
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
        props = { size = SliderSize },
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
        props = { size = InputSize },
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
        onCommit = searchSemanticHit,
        inputEvents = {
          textChanged = async:callback(searchLowHit),
          focusLoss = async:callback(searchLowHit),
        },
        events = {
          mouseClick = async:callback(searchLowHit),
        },
      },
    },
  }
end

return eventComposition
