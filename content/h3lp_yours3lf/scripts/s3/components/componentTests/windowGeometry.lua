---@omw-context player

local I = require 'openmw.interfaces'
local util = require 'openmw.util'

local text = require 'scripts.s3.components.text'
local widget = require 'scripts.s3.components.widget'
local window = require 'scripts.s3.components.window'

local UtilVector2 = util.vector2
local canvasSize = UtilVector2(720, 410)
local referenceSize = canvasSize
local smallSize = UtilVector2(210, 150)
local wideSize = UtilVector2(250, 150)
local minimumSize = UtilVector2(160, 110)
local maximumSize = UtilVector2(300, 220)
local positionA = UtilVector2(10, 10)
local positionB = UtilVector2(240, 10)
local positionC = UtilVector2(10, 190)
local positionD = UtilVector2(290, 190)

local function body(label) return { text { text = label } } end

---@return openmw.ui.Layout
local function windowGeometry()
  local chrome

  chrome = window {
    name = 'chrome',
    title = 'Pin + close',
    position = positionC,
    size = wideSize,
    movable = false,
    resizable = false,
    pinnable = true,
    closable = true,
    referenceSize = referenceSize,
    onPin = I.H3ComponentTest.refresh,
    onClose = function()
      chrome.props.visible = false
      I.H3ComponentTest.refresh()
    end,
    children = body 'Controls must fit a 20px caption and remain clickable.',
  }

  return widget {
    name = 'ct_demo_window_geometry',
    props = { size = canvasSize },
    children = {
      window {
        name = 'plain',
        position = positionA,
        size = smallSize,
        movable = false,
        resizable = false,
        referenceSize = referenceSize,
        children = body 'No caption; body must start at the top inset.',
      },

      window {
        name = 'title_only',
        title = 'Title only',
        position = positionB,
        size = wideSize,
        movable = true,
        resizable = false,
        referenceSize = referenceSize,
        onMove = I.H3ComponentTest.refresh,
        children = body 'Drag the caption. Resize edges must do nothing.',
      },

      chrome,

      window {
        name = 'bounded',
        title = 'Bounded resize',
        position = positionD,
        size = smallSize,
        minSize = minimumSize,
        maxSize = maximumSize,
        movable = true,
        resizable = true,
        referenceSize = referenceSize,
        onMove = I.H3ComponentTest.refresh,
        onResize = I.H3ComponentTest.refresh,
        children = body 'Resize every edge/corner; min/max and clamp must hold.',
      },
    },
  }
end

return windowGeometry
