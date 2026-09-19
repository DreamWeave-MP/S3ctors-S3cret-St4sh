---@omw-context player

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local util = require 'openmw.util'

local appearance = require 'scripts.h3.ui.appearance'
local collapsible = require 'scripts.h3.components.collapsible'
local column = require 'scripts.h3.components.column'
local numberInput = require 'scripts.h3.components.numberInput'
local row = require 'scripts.h3.components.row'
local searchInput = require 'scripts.h3.components.searchInput'
local selector = require 'scripts.h3.components.selector'
local slider = require 'scripts.h3.components.slider'
local spacer = require 'scripts.h3.components.spacer'
local tabs = require 'scripts.h3.components.tabs'
local text = require 'scripts.h3.components.text'
local toggle = require 'scripts.h3.components.toggle'

local StrFormat, ToString = string.format, tostring

local UtilVector2 = util.vector2
local Gap, SliderSize, InputSize = UtilVector2(0, 6), UtilVector2(220, 18), UtilVector2(120, 24)

---@return table
local function headerTextProps()
  return {
    textColor = appearance.token 'color.header',
    textSize = appearance.token 'textSize.header',
  }
end
local SelectItems = {
  { label = 'Alpha', value = 'a' },
  { label = 'Beta', value = 'b' },
  { label = 'Gamma', value = 'c' },
}
local TabItems = {
  { label = 'One', value = 1 },
  { label = 'Two', value = 2 },
  { label = 'Three', value = 3 },
}

---@return boolean
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
      text { text = 'State mutation and semantic callback coverage', props = headerTextProps() },
      spacer { props = { size = Gap } },

      row {
        children = {
          toggle {
            label = 'Enabled',
            value = true,
            ---@param value boolean
            ---@return nil
            onChange = function(value)
              toggleValue.props.text = StrFormat('toggle = %s', ToString(value))
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
        props = { size = SliderSize },
        ---@param value number
        ---@return nil
        onChange = function(value)
          sliderValue.props.text = StrFormat('slider = %s', ToString(value))
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
            props = { size = InputSize },
            events = {
              textChanged = async:callback(pass),
              focusLoss = async:callback(pass),
            },
            ---@param value boolean
            ---@return nil
            onChange = function(value)
              numberValue.props.text = StrFormat('number = %s', ToString(value))
            end,
            onCommit = I.H3ComponentTest.refresh,
          },

          numberValue,
        },
      },

      row {
        children = {
          selector {
            items = SelectItems,
            selected = 1,
            ---@param _ integer
            ---@param item H3.SelectorItem
            ---@return nil
            onSelect = function(_, item)
              selectValue.props.text = StrFormat('select = %s', item.label)
              I.H3ComponentTest.refresh()
            end,
          },

          selectValue,
        },
      },

      tabs {
        items = TabItems,
        selected = 1,
        ---@param _ integer
        ---@param item H3.TabItem
        ---@return nil
        onSelect = function(_, item)
          tabValue.props.text = StrFormat('tab = %s', item.label)
          I.H3ComponentTest.refresh()
        end,
      },

      tabValue,

      searchInput {
        value = 'seed',
        inputEvents = {
          textChanged = async:callback(pass),
        },
        ---@param value number
        ---@return nil
        onChange = function(value)
          searchValue.props.text = StrFormat('search = "%s"', value)
          I.H3ComponentTest.refresh()
        end,
      },

      searchValue,

      collapsible {
        title = 'Disclosure',
        expanded = true,
        ---@param expanded boolean
        ---@return nil
        onToggle = function(expanded)
          collapseValue.props.text = StrFormat('expanded = %s', ToString(expanded))
          I.H3ComponentTest.refresh()
        end,
        children = {
          text {
            text = 'This text must disappear and return without rebuilding.',
          },
        },
      },

      collapseValue,
    },
  }
end

return controlStates
