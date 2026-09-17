---@omw-context player

local I = require 'openmw.interfaces'
local util = require 'openmw.util'

local UtilVector2 = util.vector2
local windowSize = UtilVector2(560, 360)
local sliderSize = UtilVector2(260, 18)
local numberSize = UtilVector2(90, 24)
local textInputSize = UtilVector2(260, 24)
local modes = { 'Compact', 'Balanced', 'Verbose' }

local function ignore() end

---@param invalidate? fun()
---@return openmw.ui.Layout
local function applicationForm(invalidate)
  local refresh = invalidate or ignore
  local ui = I.H3UI.scope { invalidate = invalidate }

  local general = ui.settings {
    title = 'General',
    gap = 8,
    fieldGap = 12,
    fields = {
      {
        label = 'Enabled',
        kind = 'toggle',
        value = true,
        onChange = refresh,
      },
      {
        label = 'Mode',
        kind = 'selector',
        items = modes,
        selected = 2,
        onSelect = refresh,
      },
      {
        label = 'Intensity',
        kind = 'slider',
        value = 65,
        min = 0,
        max = 100,
        step = 5,
        props = { size = sliderSize },
        onChange = refresh,
      },
    },
    children = {
      ui.divider(),
      ui.text {
        text = 'This page is built from the settings recipe; the surrounding window and page switching come from tabbedWindow.',
        tone = 'muted',
      },
    },
  }

  local filtering = ui.settings {
    title = 'Filtering',
    gap = 8,
    fieldGap = 12,
    fields = {
      {
        label = 'Default filter',
        kind = 'textInput',
        text = 'npc',
        props = { size = textInputSize },
        onChange = refresh,
      },
      {
        label = 'Page size',
        kind = 'numberInput',
        value = 20,
        min = 5,
        max = 100,
        step = 5,
        integer = true,
        props = { size = numberSize },
        onCommit = refresh,
      },
    },
    children = {
      ui.divider(),
      ui.searchableList {
        query = '',
        items = {
          'Actors',
          'Creatures',
          'Containers',
          'Doors',
          'Weapons',
        },
        onQueryChange = ignore,
      },
    },
  }

  local advanced = ui.column {
    gap = 8,
    ui.text { text = 'Advanced', role = 'title' },
    ui.collapsible {
      title = 'Experimental behavior',
      expanded = true,
      onToggle = refresh,
      children = {
        ui.settings {
          fields = {
            {
              label = 'Unsafe mode',
              kind = 'toggle',
              value = false,
              tone = 'negative',
              onChange = refresh,
            },
          },
        },
        ui.text {
          text = 'Application examples are intentionally written as copyable mod code rather than synthetic widget banks.',
          tone = 'muted',
        },
      },
    },
    ui.divider(),
    ui.row {
      gap = 6,
      ui.spacer { grow = 1 },
      ui.button { label = 'Reset', onActivate = ignore },
      ui.button { label = 'Apply', tone = 'positive', onActivate = ignore },
    },
  }

  return ui.tabbedWindow {
    name = 'ct_demo_application_form',
    title = 'H3UI Mod Configuration',
    size = windowSize,
    resizable = false,
    pinnable = true,
    selected = 1,
    tabs = {
      { label = 'General', content = general },
      { label = 'Filtering', content = filtering },
      { label = 'Advanced', content = advanced },
    },
    onSelect = refresh,
  }
end

return applicationForm
