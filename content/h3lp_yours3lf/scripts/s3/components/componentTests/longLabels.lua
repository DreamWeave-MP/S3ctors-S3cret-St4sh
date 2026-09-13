---@omw-context player

local I = require 'openmw.interfaces'
local util = require 'openmw.util'

local caption = require 'scripts.s3.components.caption'
local collapsible = require 'scripts.s3.components.collapsible'
local column = require 'scripts.s3.components.column'
local searchInput = require 'scripts.s3.components.searchInput'
local selector = require 'scripts.s3.components.selector'
local spacer = require 'scripts.s3.components.spacer'
local tabs = require 'scripts.s3.components.tabs'
local text = require 'scripts.s3.components.text'
local toggle = require 'scripts.s3.components.toggle'

local UtilVector2 = util.vector2
local narrow = UtilVector2(360, 0)
local gap = UtilVector2(0, 6)
local long = 'A deliberately obnoxious label that is much longer than normal UI copy'
local function refresh() I.H3ComponentTest.refresh() end

---@return openmw.ui.Layout
local function longLabels()
  return column {
    name = 'ct_demo_long_labels',
    props = { size = narrow },
    children = {
      text { text = 'Long-label and cramped-width behavior' },
      spacer { props = { size = gap } },
      caption {
        text = long,
        pinnable = true,
        closable = true,
      },
      toggle {
        label = long,
        onLabel = 'ENABLED',
        offLabel = 'DISABLED',
        onChange = refresh,
      },
      selector {
        items = {
          long .. ' / one',
          long .. ' / two',
          long .. ' / three',
        },
        selected = 2,
        onSelect = refresh,
      },
      tabs {
        items = {
          'First tab with a lot of text',
          'Second tab with even more text than the first one',
          'Third',
        },
        selected = 2,
        selectedPrefix = '<',
        selectedSuffix = '>',
        onSelect = refresh,
      },
      searchInput {
        value = long,
        clearLabel = 'CLEAR',
        onChange = refresh,
      },
      collapsible {
        title = long,
        expanded = true,
        onToggle = refresh,
        children = {
          text { text = long .. ' inside the disclosure body as well.' },
        },
      },
    },
  }
end

return longLabels
