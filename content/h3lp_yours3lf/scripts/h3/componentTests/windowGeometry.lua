---@omw-context player

local I = require 'openmw.interfaces'
local util = require 'openmw.util'

local text = require 'scripts.h3.components.text'
local widget = require 'scripts.h3.components.widget'
local window = require 'scripts.h3.components.window'

local UtilVector2 = util.vector2
local CanvasSize = UtilVector2(720, 410)
local SmallSize, WideSize, MinimumSize, MaximumSize, PositionA, PositionB, PositionC, PositionD =
  UtilVector2(210, 150),
  UtilVector2(250, 150),
  UtilVector2(160, 110),
  UtilVector2(300, 220),
  UtilVector2(10, 10),
  UtilVector2(240, 10),
  UtilVector2(10, 190),
  UtilVector2(290, 190)
local ReferenceSize = CanvasSize

---@param label string
---@return openmw.ui.Layout[]
local function body(label) return { text { text = label } } end

---@return openmw.ui.Layout
local function windowGeometry()
  local chrome

  chrome = window {
    name = 'chrome',
    title = 'Pin + close',
    position = PositionC,
    size = WideSize,
    movable = false,
    resizable = false,
    pinnable = true,
    closable = true,
    referenceSize = ReferenceSize,
    onPin = I.H3ComponentTest.refresh,
    ---@return nil
    onClose = function()
      chrome.props.visible = false
      I.H3ComponentTest.refresh()
    end,
    children = body 'Controls must fit a 20px caption and remain clickable.',
  }

  return widget {
    name = 'ct_demo_window_geometry',
    props = { size = CanvasSize },
    children = {
      window {
        name = 'plain',
        position = PositionA,
        size = SmallSize,
        movable = false,
        resizable = false,
        referenceSize = ReferenceSize,
        children = body 'No caption; body must start at the top inset.',
      },

      window {
        name = 'title_only',
        title = 'Title only',
        position = PositionB,
        size = WideSize,
        movable = true,
        resizable = false,
        referenceSize = ReferenceSize,
        onMove = I.H3ComponentTest.refresh,
        children = body 'Drag the caption. Resize edges must do nothing.',
      },

      chrome,

      window {
        name = 'bounded',
        title = 'Bounded resize',
        position = PositionD,
        size = SmallSize,
        minSize = MinimumSize,
        maxSize = MaximumSize,
        movable = true,
        resizable = true,
        referenceSize = ReferenceSize,
        onMove = I.H3ComponentTest.refresh,
        onResize = I.H3ComponentTest.refresh,
        children = body 'Resize every edge/corner; min/max and clamp must hold.',
      },
    },
  }
end

return windowGeometry
