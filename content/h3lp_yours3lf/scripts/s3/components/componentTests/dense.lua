---@omw-context player

local I = require 'openmw.interfaces'
local util = require 'openmw.util'

local column = require 'scripts.s3.components.column'
local constants = require 'scripts.omw.mwui.constants'
local meter = require 'scripts.s3.components.meter'
local row = require 'scripts.s3.components.row'
local selector = require 'scripts.s3.components.selector'
local slider = require 'scripts.s3.components.slider'
local spacer = require 'scripts.s3.components.spacer'
local text = require 'scripts.s3.components.text'
local toggle = require 'scripts.s3.components.toggle'

local MathFloor = math.floor
local StrFormat = string.format
local UtilVector2 = util.vector2

local bankGap = UtilVector2(12, 0)
local labelSize = UtilVector2(42, 18)
local sliderSize = UtilVector2(180, 18)
local meterSize = UtilVector2(180, 18)
local selectLabelSize = UtilVector2(52, 19)
local choices = { 'Low', 'Med', 'High' }
local sliderSteps = { 1, 5, 10 }
local meterValues = { 0, 100, 14, 86, 28, 72, 42, 58, 56, 44, 70, 30, 84, 16, 96, 4 }
local headerTextProps = {
  textColor = constants.headerColor,
  textSize = constants.textHeaderSize,
}
local passiveProps = { ignorePointerEvents = true }

local function refresh() I.H3ComponentTest.refresh() end

local function makeSliderRow(index)
  local step = sliderSteps[(index - 1) % #sliderSteps + 1]
  local value = MathFloor((index - 1) * 100 / 15 / step + 0.5) * step
  local valueLabel = text {
    name = 'dense_slider_value_' .. index,
    text = StrFormat('%02d  %3d', index, value),
    props = {
      autoSize = false,
      size = labelSize,
    },
  }

  return row {
    name = 'dense_slider_row_' .. index,
    children = {
      valueLabel,
      slider {
        value = value,
        min = 0,
        max = 100,
        step = step,
        props = { size = sliderSize },
        onChange = refresh,
      },
    },
  }
end

local function makeMeterRow(index)
  local value = meterValues[index]
  return row {
    name = 'dense_meter_row_' .. index,
    props = passiveProps,
    children = {
      text {
        name = 'dense_meter_value_' .. index,
        text = StrFormat('%02d  %3d', index, value),
        props = {
          autoSize = false,
          size = labelSize,
        },
      },
      meter {
        value = value,
        max = 100,
        props = { size = meterSize },
      },
    },
  }
end

local function makeControlRow(index)
  return row {
    name = 'dense_control_row_' .. index,
    children = {
      text {
        name = 'dense_control_value_' .. index,
        text = StrFormat('%02d', index),
        props = {
          autoSize = false,
          size = labelSize,
        },
      },
      toggle {
        value = index % 2 == 0,
        onChange = refresh,
      },
      selector {
        items = choices,
        selected = index % #choices + 1,
        labelProps = {
          autoSize = false,
          size = selectLabelSize,
        },
        onSelect = refresh,
      },
    },
  }
end

---@return openmw.ui.Layout
local function dense()
  local sliderRows = { text { text = 'Interactive sliders', props = headerTextProps } }
  local meterRows = { text { text = 'Passive meters', props = headerTextProps } }
  local controlRows = { text { text = 'Toggle / select controls', props = headerTextProps } }

  for index = 1, 16 do
    sliderRows[#sliderRows + 1] = makeSliderRow(index)
    meterRows[#meterRows + 1] = makeMeterRow(index)
    controlRows[#controlRows + 1] = makeControlRow(index)
  end

  return column {
    name = 'ct_demo_dense',
    children = {
      text {
        text = 'Dense component banks: construction, layout, and semantic update stress',
        props = headerTextProps,
      },
      row {
        children = {
          column {
            name = 'dense_sliders',
            external = { grow = 1 },
            children = sliderRows,
          },

          spacer { props = { size = bankGap } },

          column {
            name = 'dense_meters',
            props = passiveProps,
            external = { grow = 1 },
            children = meterRows,
          },

          spacer { props = { size = bankGap } },

          column {
            name = 'dense_controls',
            external = { grow = 1 },
            children = controlRows,
          },
        },
      },
    },
  }
end

return dense
