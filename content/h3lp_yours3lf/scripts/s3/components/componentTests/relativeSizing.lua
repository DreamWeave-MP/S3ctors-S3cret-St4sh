---@omw-context player

local I = require 'openmw.interfaces'
local util = require 'openmw.util'

local column = require 'scripts.s3.components.column'
local constants = require 'scripts.omw.mwui.constants'
local meter = require 'scripts.s3.components.meter'
local row = require 'scripts.s3.components.row'
local slider = require 'scripts.s3.components.slider'
local spacer = require 'scripts.s3.components.spacer'
local text = require 'scripts.s3.components.text'
local widget = require 'scripts.s3.components.widget'

local UtilVector2 = util.vector2
local fullSize = UtilVector2(1, 1)
local fullWidth = UtilVector2(1, 0)
local halfWidth = UtilVector2(0.5, 0)
local fixedPanelSize = UtilVector2(520, 150)
local relativeSliderSize = UtilVector2(-40, 18)
local relativeMeterSize = UtilVector2(-40, 16)
local halfMeterSize = UtilVector2(-12, 16)
local rowSize = UtilVector2(0, 16)
local gap = UtilVector2(12, 0)

local headerTextProps = {
  textColor = constants.headerColor,
  textSize = constants.textHeaderSize,
}
local function refresh() I.H3ComponentTest.refresh() end

---@return openmw.ui.Layout
local function relativeSizing()
  return widget {
    name = 'ct_demo_relative_sizing',

    props = { size = fixedPanelSize },

    children = {
      column {
        props = {
          autoSize = false,
          relativeSize = fullSize,
        },

        children = {
          text {
            text = 'Relative sizing in a fixed Widget coordinate space',
            props = headerTextProps,
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
              size = relativeSliderSize,
              relativeSize = fullWidth,
            },
          },

          meter {
            value = 50,
            max = 100,
            props = {
              size = relativeMeterSize,
              relativeSize = fullWidth,
            },
          },

          row {
            props = {
              autoSize = false,
              relativeSize = fullWidth,
              size = rowSize,
            },

            children = {
              meter {
                value = 25,
                max = 100,
                props = {
                  size = halfMeterSize,
                  relativeSize = halfWidth,
                },
              },

              spacer { props = { size = gap } },

              meter {
                value = 75,
                max = 100,
                props = {
                  size = halfMeterSize,
                  relativeSize = halfWidth,
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
