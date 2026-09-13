---@omw-context player

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local util = require 'openmw.util'

local collapsible = require 'scripts.s3.components.collapsible'
local column = require 'scripts.s3.components.column'
local constants = require 'scripts.omw.mwui.constants'
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
local gap = UtilVector2(0, 8)
local sliderSize = UtilVector2(260, 18)
local numberSize = UtilVector2(90, 24)
local modes = { 'Compact', 'Balanced', 'Verbose' }
local pages = { 'General', 'Filtering', 'Advanced' }
local headerTextProps = {
  textColor = constants.headerColor,
  textSize = constants.textHeaderSize,
}

local function pass() return true end

---@return openmw.ui.Layout
local function applicationForm()
  local summary = text { text = 'Ready' }

  local function setSummary(value)
    summary.props.text = value
    I.H3ComponentTest.refresh()
  end

  return column {
    name = 'ct_demo_application_form',
    children = {
      text { text = 'Application-style settings form', props = headerTextProps },
      tabs {
        items = pages,
        onSelect = function(_, item) setSummary('page: ' .. item) end,
      },

      spacer { props = { size = gap } },

      row {
        children = {
          text { text = 'Enabled' },
          toggle {
            value = true,
            onChange = function(value) setSummary('enabled: ' .. tostring(value)) end,
          },
        },
      },

      text { text = 'Intensity' },

      slider {
        value = 65,
        min = 0,
        max = 100,
        step = 5,
        props = { size = sliderSize },
        onChange = function(value) setSummary('intensity: ' .. tostring(value)) end,
      },

      row {
        children = {
          text { text = 'Page size' },
          numberInput {
            value = 20,
            min = 5,
            max = 100,
            step = 5,
            integer = true,
            props = { size = numberSize },
            events = {
              textChanged = async:callback(pass),
              focusLoss = async:callback(pass),
            },
            onCommit = function(value) setSummary('page size: ' .. tostring(value)) end,
          },
        },
      },

      row {
        children = {
          text { text = 'Mode' },
          selector {
            items = modes,
            selected = 2,
            onSelect = function(_, item) setSummary('mode: ' .. item) end,
          },
        },
      },

      searchInput {
        value = 'npc',
        inputEvents = { textChanged = async:callback(pass) },
        onChange = function(value) setSummary('filter: ' .. value) end,
      },

      collapsible {
        title = 'Advanced',
        expanded = false,
        onToggle = I.H3ComponentTest.refresh,
        children = {
          toggle {
            label = 'Experimental behavior',
            value = false,
            onChange = function(value) setSummary('experimental: ' .. tostring(value)) end,
          },
          text { text = 'A realistic disclosure section should remain stable.' },
        },
      },

      spacer { props = { size = gap } },
      summary,
    },
  }
end

return applicationForm
