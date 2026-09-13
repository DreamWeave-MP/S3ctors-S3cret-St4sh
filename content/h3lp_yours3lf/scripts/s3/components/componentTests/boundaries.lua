---@omw-context player

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local util = require 'openmw.util'

local collapsible = require 'scripts.s3.components.collapsible'
local column = require 'scripts.s3.components.column'
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

local function pass() return true end
local function refresh() I.H3ComponentTest.refresh() end

---@return openmw.ui.Layout
local function boundaries()
  return column {
    name = 'ct_demo_boundaries',
    children = {
      text { text = 'Boundary, empty, clamp, and normalization cases' },
      spacer { props = { size = gap } },

      text { text = 'Meters: below zero / zero / exact max / above max / max = 0' },
      meter { value = -10, max = 100, props = { size = meterSize } },
      meter { value = 0, max = 100, props = { size = meterSize } },
      meter { value = 100, max = 100, props = { size = meterSize } },
      meter { value = 150, max = 100, props = { size = meterSize } },
      meter { value = 5, max = 0, props = { size = meterSize } },

      spacer { props = { size = gap } },
      text { text = 'Sliders: min / max / stepped initial normalization / negative range' },

      slider { value = 0, min = 0, max = 10, onChange = refresh, props = { size = sliderSize } },
      slider { value = 10, min = 0, max = 10, onChange = refresh, props = { size = sliderSize } },
      slider {
        value = 53,
        min = 0,
        max = 100,
        step = 5,
        onChange = refresh,
        props = { size = sliderSize },
      },
      slider {
        value = -0.37,
        min = -1,
        max = 1,
        step = 0.25,
        onChange = refresh,
        props = { size = sliderSize },
      },

      spacer { props = { size = gap } },
      text { text = 'Number inputs: clamps, fractional steps, invalid text rollback on blur' },

      row {
        children = {
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
      text { text = 'Empty and singleton navigation controls' },
      selector { items = {}, emptyLabel = '<empty>' },
      selector { items = { 'Only' }, selected = 99 },
      tabs { items = {} },
      tabs { items = { 'Only' }, selected = 99 },

      spacer { props = { size = gap } },
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
