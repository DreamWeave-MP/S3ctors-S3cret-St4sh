---@omw-context player

local I = require 'openmw.interfaces'
local util = require 'openmw.util'

local appearance = require 'scripts.s3.ui.appearance'
local collapsible = require 'scripts.s3.components.collapsible'
local column = require 'scripts.s3.components.column'
local numberInput = require 'scripts.s3.components.numberInput'
local row = require 'scripts.s3.components.row'
local searchInput = require 'scripts.s3.components.searchInput'
local selector = require 'scripts.s3.components.selector'
local slider = require 'scripts.s3.components.slider'
local tabs = require 'scripts.s3.components.tabs'
local text = require 'scripts.s3.components.text'
local toggle = require 'scripts.s3.components.toggle'

local UtilVector2 = util.vector2
local sliderSize = UtilVector2(260, 18)
local numberSize = UtilVector2(90, 24)
local modes = { 'Compact', 'Balanced', 'Verbose' }
local pages = { 'General', 'Filtering', 'Advanced' }

local function headerTextProps()
  return {
    textColor = appearance.token 'color.header',
    textSize = appearance.token 'textSize.header',
  }
end

---@return openmw.ui.Layout
local function applicationForm()
  local summary = text 'Ready'

  local function setSummary(value)
    summary.props.text = value
    I.H3ComponentTest.refresh()
  end

  return column {
    name = 'ct_demo_application_form',
    gap = 8,

    text { text = 'Application-style settings form', props = headerTextProps() },
    tabs {
      items = pages,
      onSelect = function(_, item) setSummary('page: ' .. item) end,
    },

    row {
      gap = 8,
      text 'Enabled',
      toggle {
        value = true,
        onChange = function(value) setSummary('enabled: ' .. tostring(value)) end,
      },
    },

    text 'Intensity',
    slider {
      value = 65,
      min = 0,
      max = 100,
      step = 5,
      props = { size = sliderSize },
      onChange = function(value) setSummary('intensity: ' .. tostring(value)) end,
    },

    row {
      gap = 8,
      text 'Page size',
      numberInput {
        value = 20,
        min = 5,
        max = 100,
        step = 5,
        integer = true,
        props = { size = numberSize },
        onCommit = function(value) setSummary('page size: ' .. tostring(value)) end,
      },
    },

    row {
      gap = 8,
      text 'Mode',
      selector {
        items = modes,
        selected = 2,
        onSelect = function(_, item) setSummary('mode: ' .. item) end,
      },
    },

    searchInput {
      value = 'npc',
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
        text 'A realistic disclosure section should remain stable.',
      },
    },

    summary,
  }
end

return applicationForm
