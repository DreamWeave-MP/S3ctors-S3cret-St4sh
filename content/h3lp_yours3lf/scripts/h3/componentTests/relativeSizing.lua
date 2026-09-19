---@omw-context player

local I = require 'openmw.interfaces'
local util = require 'openmw.util'

local appearance = require 'scripts.h3.ui.appearance'
local column = require 'scripts.h3.components.column'
local meter = require 'scripts.h3.components.meter'
local row = require 'scripts.h3.components.row'
local slider = require 'scripts.h3.components.slider'
local spacer = require 'scripts.h3.components.spacer'
local text = require 'scripts.h3.components.text'
local widget = require 'scripts.h3.components.widget'

local UtilVector2 = util.vector2
local FullSize, FullWidth, HalfWidth, FixedPanelSize, RelativeSliderSize, RelativeMeterSize, HalfMeterSize, RowSize, Gap =
  UtilVector2(1, 1),
  UtilVector2(1, 0),
  UtilVector2(0.5, 0),
  UtilVector2(520, 150),
  UtilVector2(-40, 18),
  UtilVector2(-40, 16),
  UtilVector2(-12, 16),
  UtilVector2(0, 16),
  UtilVector2(12, 0)

---@return table
local function headerTextProps()
  return {
    textColor = appearance.token 'color.header',
    textSize = appearance.token 'textSize.header',
  }
end
---@return nil
local function refresh() I.H3ComponentTest.refresh() end

---@return openmw.ui.Layout
local function relativeSizing()
  return widget {
    name = 'ct_demo_relative_sizing',

    props = { size = FixedPanelSize },

    children = {
      column {
        props = {
          autoSize = false,
          relativeSize = FullSize,
        },

        children = {
          text {
            text = 'Relative sizing in a fixed Widget coordinate space',
            props = headerTextProps(),
          },

          text {
            text = 'Drag the slider to verify redraw with a relative-width track.',
          },

          slider {
            value = 25,
            min = 0,
            max = 100,
            trackWidth = 480,
            onChange = refresh,
            props = {
              size = RelativeSliderSize,
              relativeSize = FullWidth,
            },
          },

          meter {
            value = 50,
            max = 100,
            props = {
              size = RelativeMeterSize,
              relativeSize = FullWidth,
            },
          },

          row {
            props = {
              autoSize = false,
              relativeSize = FullWidth,
              size = RowSize,
            },

            children = {
              meter {
                value = 25,
                max = 100,
                props = {
                  size = HalfMeterSize,
                  relativeSize = HalfWidth,
                },
              },

              spacer { props = { size = Gap } },

              meter {
                value = 75,
                max = 100,
                props = {
                  size = HalfMeterSize,
                  relativeSize = HalfWidth,
                },
              },
            },
          },
        },
      },
    },
  }
end

return relativeSizing
