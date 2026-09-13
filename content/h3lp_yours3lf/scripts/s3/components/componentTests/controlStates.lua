---@omw-context player

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local util = require 'openmw.util'

local collapsible = require 'scripts.s3.components.collapsible'
local column = require 'scripts.s3.components.column'
local numberInput = require 'scripts.s3.components.numberInput'
local row = require 'scripts.s3.components.row'
local searchInput = require 'scripts.s3.components.searchInput'
local selector = require 'scripts.s3.components.selector'
local slider = require 'scripts.s3.components.slider'
local spacer = require 'scripts.s3.components.spacer'
local tabs = require 'scripts.s3.components.tabs'
local text = require 'scripts.s3.components.text'
local toggle = require 'scripts.s3.components.toggle'

local UtilVector2 = util.vector2
local StrFormat = string.format
local gap = UtilVector2(0, 6)
local sliderSize = UtilVector2(220, 18)
local inputSize = UtilVector2(120, 24)
local selectItems = {
  { label = 'Alpha', value = 'a' },
  { label = 'Beta', value = 'b' },
  { label = 'Gamma', value = 'c' },
}
local tabItems = {
  { label = 'One', value = 1 },
  { label = 'Two', value = 2 },
  { label = 'Three', value = 3 },
}

local function pass() return true end

---@return openmw.ui.Layout
local function controlStates()
  local toggleValue = text { text = 'toggle = true' }
  local sliderValue = text { text = 'slider = 35' }
  local numberValue = text { text = 'number = 4' }
  local selectValue = text { text = 'select = Alpha' }
  local tabValue = text { text = 'tab = One' }
  local searchValue = text { text = 'search = "seed"' }
  local collapseValue = text { text = 'expanded = true' }

  return column {
    name = 'ct_demo_control_states',
    children = {
      text { text = 'State mutation and semantic callback coverage' },
      spacer { props = { size = gap } },

      row {
        children = {
          toggle {
            label = 'Enabled',
            value = true,
            onChange = function(value)
              toggleValue.props.text = 'toggle = ' .. tostring(value)
              I.H3ComponentTest.refresh()
            end,
          },
          toggleValue,
        },
      },

      slider {
        value = 35,
        min = 0,
        max = 100,
        step = 5,
        props = { size = sliderSize },
        onChange = function(value)
          sliderValue.props.text = 'slider = ' .. tostring(value)
          I.H3ComponentTest.refresh()
        end,
      },

      sliderValue,

      row {
        children = {
          numberInput {
            value = 4,
            min = -10,
            max = 10,
            step = 2,
            integer = true,
            props = { size = inputSize },
            events = {
              textChanged = async:callback(pass),
              focusLoss = async:callback(pass),
            },
            onChange = function(value) numberValue.props.text = 'number = ' .. tostring(value) end,
            onCommit = I.H3ComponentTest.refresh,
          },
          numberValue,
        },
      },

      row {
        children = {
          selector {
            items = selectItems,
            selected = 1,
            onSelect = function(_, item)
              selectValue.props.text = 'select = ' .. item.label
              I.H3ComponentTest.refresh()
            end,
          },
          selectValue,
        },
      },

      tabs {
        items = tabItems,
        selected = 1,
        onSelect = function(_, item)
          tabValue.props.text = 'tab = ' .. item.label
          I.H3ComponentTest.refresh()
        end,
      },

      tabValue,

      searchInput {
        value = 'seed',
        inputEvents = {
          textChanged = async:callback(pass),
        },
        onChange = function(value)
          searchValue.props.text = StrFormat('search = "%s"', value)
          I.H3ComponentTest.refresh()
        end,
      },

      searchValue,

      collapsible {
        title = 'Disclosure',
        expanded = true,
        onToggle = function(expanded)
          collapseValue.props.text = 'expanded = ' .. tostring(expanded)
          I.H3ComponentTest.refresh()
        end,
        children = {
          text { text = 'This text must disappear and return without rebuilding.' },
        },
      },

      collapseValue,
    },
  }
end

return controlStates
