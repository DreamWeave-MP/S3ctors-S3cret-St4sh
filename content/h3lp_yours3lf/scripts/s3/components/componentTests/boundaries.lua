---@omw-context player

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local util = require 'openmw.util'

local collapsible = require 'scripts.s3.components.collapsible'
local column = require 'scripts.s3.components.column'
local constants = require 'scripts.omw.mwui.constants'
local meter = require 'scripts.s3.components.meter'
local numberInput = require 'scripts.s3.components.numberInput'
local row = require 'scripts.s3.components.row'
local searchInput = require 'scripts.s3.components.searchInput'
local selector = require 'scripts.s3.components.selector'
local slider = require 'scripts.s3.components.slider'
local spacer = require 'scripts.s3.components.spacer'
local tabs = require 'scripts.s3.components.tabs'
local text = require 'scripts.s3.components.text'

local UtilVector2 = util.vector2
local gap = UtilVector2(0, 6)
local meterSize = UtilVector2(180, 14)
local sliderSize = UtilVector2(220, 18)
local inputSize = UtilVector2(120, 24)
local headerTextProps = {
  textColor = constants.headerColor,
  textSize = constants.textHeaderSize,
}

local function pass() return true end
local function refresh() I.H3ComponentTest.refresh() end

---@return openmw.ui.Layout
local function boundaries()
  return column {
    name = 'ct_demo_boundaries',
    children = {
      text {
        text = 'Boundary, empty, clamp, and normalization cases',
        props = headerTextProps,
      },
      spacer { props = { size = gap } },

      text { text = 'Meters', props = headerTextProps },
      row {
        children = {
          text { text = 'below zero — expected: empty' },
          meter { value = -10, max = 100, props = { size = meterSize } },
        },
      },
      row {
        children = {
          text { text = 'zero — expected: empty' },
          meter { value = 0, max = 100, props = { size = meterSize } },
        },
      },
      row {
        children = {
          text { text = 'exact max — expected: full' },
          meter { value = 100, max = 100, props = { size = meterSize } },
        },
      },
      row {
        children = {
          text { text = 'above max — expected: full' },
          meter { value = 150, max = 100, props = { size = meterSize } },
        },
      },
      row {
        children = {
          text { text = 'max = 0 — expected: empty' },
          meter { value = 5, max = 0, props = { size = meterSize } },
        },
      },

      spacer { props = { size = gap } },
      text { text = 'Sliders', props = headerTextProps },

      row {
        children = {
          text { text = 'minimum — expected initial: 0' },
          slider { value = 0, min = 0, max = 10, onChange = refresh, props = { size = sliderSize } },
        },
      },
      row {
        children = {
          text { text = 'maximum — expected initial: 10' },
          slider { value = 10, min = 0, max = 10, onChange = refresh, props = { size = sliderSize } },
        },
      },
      row {
        children = {
          text { text = '53, step 5 — expected initial: 55' },
          slider {
            value = 53,
            min = 0,
            max = 100,
            step = 5,
            onChange = refresh,
            props = { size = sliderSize },
          },
        },
      },
      row {
        children = {
          text {
            text = 'negative stepped — expected initial: -0.25',
          },
          slider {
            value = -0.37,
            min = -1,
            max = 1,
            step = 0.25,
            onChange = refresh,
            props = { size = sliderSize },
          },
        },
      },

      spacer { props = { size = gap } },
      text {
        text = 'Number inputs: clamps, fractional steps, invalid text rollback on blur',
        props = headerTextProps,
      },

      row {
        children = {
          text { text = '-99 → -5' },
          numberInput {
            value = -99,
            min = -5,
            max = 5,
            integer = true,
            props = { size = inputSize },
            events = {
              textChanged = async:callback(pass),
              focusLoss = async:callback(pass),
            },
            onCommit = I.H3ComponentTest.refresh,
          },
        },
      },
      row {
        children = {
          text { text = '99 → 5' },
          numberInput {
            value = 99,
            min = -5,
            max = 5,
            integer = true,
            props = { size = inputSize },
            events = {
              textChanged = async:callback(pass),
              focusLoss = async:callback(pass),
            },
            onCommit = I.H3ComponentTest.refresh,
          },
        },
      },
      row {
        children = {
          text { text = '0.37, step 0.25 → 0.25' },
          numberInput {
            value = 0.37,
            min = -1,
            max = 1,
            step = 0.25,
            props = { size = inputSize },
            events = {
              textChanged = async:callback(pass),
              focusLoss = async:callback(pass),
            },
            onCommit = I.H3ComponentTest.refresh,
          },
        },
      },

      spacer { props = { size = gap } },
      text { text = 'Empty and singleton navigation controls', props = headerTextProps },
      text { text = '<empty> selector — arrows do nothing' },
      selector { items = {}, emptyLabel = '<empty>' },
      text { text = 'Only selector — arrows do nothing' },
      selector { items = { 'Only' }, selected = 99 },
      text { text = 'Empty tabs — renders no tabs' },
      tabs { items = {} },
      text { text = '[ Only ] tabs — selection cannot change' },
      tabs { items = { 'Only' }, selected = 99 },

      spacer { props = { size = gap } },
      text {
        text = 'Empty search with clearable=false — no clear button',
      },
      searchInput { value = '', clearable = false },
      collapsible {
        title = 'Starts collapsed',
        expanded = false,
        onToggle = refresh,
        children = { text { text = 'Hidden boundary content' } },
      },
    },
  }
end

return boundaries
