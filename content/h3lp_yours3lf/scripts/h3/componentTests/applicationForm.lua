---@omw-context player

local I = require 'openmw.interfaces'
local util = require 'openmw.util'

local UtilVector2 = util.vector2
local WindowSize, SliderSize, NumberSize, TextInputSize =
  UtilVector2(560, 360), UtilVector2(260, 18), UtilVector2(90, 24), UtilVector2(260, 24)
local Modes = { 'Compact', 'Balanced', 'Verbose' }

---@param state H3ComponentTest.ApplicationFormState
---@return nil
local function initializeState(state)
  if state.initialized then return end
  state.initialized = true
  state.selectedPage = 1
  state.enabled = true
  state.selectedMode = 2
  state.intensity = 65
  state.defaultFilter = 'npc'
  state.pageSize = 20
  state.searchQuery = ''
  state.showExperimental = true
  state.unsafeMode = false
end

---@param invalidate? fun(): nil
---@param rebuild? fun(): nil
---@param state? H3ComponentTest.ApplicationFormState
---@return openmw.ui.Layout
local function applicationForm(invalidate, rebuild, state)
  rebuild = rebuild or
    ---@return nil
    function() end
  state = state or {}
  initializeState(state)

  local ui = I.H3UI.scope { invalidate = invalidate }

  local general = ui.settings {
    title = 'General',
    gap = 8,
    fieldGap = 12,
    fields = {
      {
        label = 'Enabled',
        kind = 'toggle',
        value = state.enabled,
        ---@param value boolean
        ---@return nil
        onChange = function(value) state.enabled = value end,
      },
      {
        label = 'Mode',
        kind = 'selector',
        items = Modes,
        selected = state.selectedMode,
        ---@param index integer
        ---@return nil
        onSelect = function(index) state.selectedMode = index end,
      },
      {
        label = 'Intensity',
        kind = 'slider',
        value = state.intensity,
        min = 0,
        max = 100,
        step = 5,
        props = { size = SliderSize },
        ---@param value number
        ---@return nil
        onChange = function(value) state.intensity = value end,
      },
    },
    children = {
      ui.divider(),

      ui.text {
        text = 'This page is built from settings; tabbedWindow only renders the selected page.',
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
        text = state.defaultFilter,
        props = { size = TextInputSize },
        ---@param value string
        ---@return nil
        onChange = function(value) state.defaultFilter = value end,
      },
      {
        label = 'Page size',
        kind = 'numberInput',
        value = state.pageSize,
        min = 5,
        max = 100,
        step = 5,
        integer = true,
        props = { size = NumberSize },
        ---@param value number
        ---@return nil
        onCommit = function(value) state.pageSize = value end,
      },
    },
    children = {
      ui.divider(),

      ui.searchableList {
        query = state.searchQuery,
        items = {
          'Actors',
          'Creatures',
          'Containers',
          'Doors',
          'Weapons',
        },
        ---@param value string
        ---@return nil
        onQueryChange = function(value) state.searchQuery = value end,
      },
    },
  }

  local advanced = ui.column {
    gap = 8,
    ui.text { text = 'Advanced', role = 'title' },

    ui.collapsible {
      title = 'Experimental behavior',
      expanded = state.showExperimental,
      ---@param value boolean
      ---@return nil
      onToggle = function(value) state.showExperimental = value end,
      children = {
        ui.settings {
          fields = {
            {
              label = 'Unsafe mode',
              kind = 'toggle',
              value = state.unsafeMode,
              tone = 'negative',
              ---@param value boolean
              ---@return nil
              onChange = function(value) state.unsafeMode = value end,
            },
          },
        },

        ui.text {
          text = 'Reference fixtures own their state and rebuild only when structure or controlled values change.',
          tone = 'muted',
        },
      },
    },
    ui.divider(),

    ui.row {
      gap = 6,
      ui.spacer { grow = 1 },

      ui.button {
        label = 'Reset',
        ---@return boolean
        onActivate = function()
          state.initialized = nil
          initializeState(state)
          rebuild()
          return true
        end,
      },

      ui.button {
        label = 'Apply',
        tone = 'positive',
        ---@return boolean
        onActivate = function() return true end,
      },
    },
  }

  return ui.tabbedWindow {
    name = 'ct_demo_application_form',
    title = 'H3UI Mod Configuration',
    size = WindowSize,
    resizable = false,
    pinnable = true,
    selected = state.selectedPage,
    tabs = {
      { label = 'General', content = general },
      { label = 'Filtering', content = filtering },
      { label = 'Advanced', content = advanced },
    },
    ---@param index integer
    ---@return nil
    onSelect = function(index)
      state.selectedPage = index
      rebuild()
    end,
  }
end

return applicationForm
