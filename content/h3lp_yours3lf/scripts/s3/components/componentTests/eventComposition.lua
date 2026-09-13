---@omw-context player

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local util = require 'openmw.util'

local column = require 'scripts.s3.components.column'
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

---@return openmw.ui.Layout
local function eventComposition()
  local semantic = 0
  local lowLevel = 0
  local bubbled = 0
  local status = text { text = 'semantic=0 low=0 bubbled=0' }

  local function redraw()
    status.props.text = StrFormat('semantic=%d low=%d bubbled=%d', semantic, lowLevel, bubbled)
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

  local rootEvents = {
    mouseClick = async:callback(function()
      bubbled = bubbled + 1
      redraw()
      return true
    end),
  }

  return column {
    name = 'ct_demo_event_composition',
    events = rootEvents,
    children = {
      text { text = 'Semantic callbacks + existing low-level handlers + bubbling' },
      status,

      row {
        children = {
          toggle {
            label = 'Toggle',
            onChange = semanticHit,
            events = { mouseClick = async:callback(lowHit) },
          },
          pinButton {
            onToggle = semanticHit,
            events = { mouseClick = async:callback(lowHit) },
          },
        },
      },

      slider {
        value = 50,
        min = 0,
        max = 100,
        props = { size = sliderSize },
        onChange = semanticHit,
        events = {
          mousePress = async:callback(lowHit),
          mouseMove = async:callback(lowHit),
          mouseRelease = async:callback(lowHit),
        },
      },

      numberInput {
        value = 2,
        min = 0,
        max = 10,
        props = { size = inputSize },
        onChange = semanticHit,
        onCommit = I.H3ComponentTest.refresh,
        events = {
          textChanged = async:callback(lowHit),
          focusLoss = async:callback(lowHit),
        },
      },

      searchInput {
        value = 'compose',
        onChange = semanticHit,
        inputEvents = {
          textChanged = async:callback(lowHit),
        },
        events = {
          mouseClick = async:callback(lowHit),
        },
      },
    },
  }
end

return eventComposition
