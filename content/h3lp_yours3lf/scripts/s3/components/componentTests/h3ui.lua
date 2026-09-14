---@omw-context player

local I = require 'openmw.interfaces'
local util = require 'openmw.util'

local bookFrame = require 'scripts.s3.components.bookFrame'
local column = require 'scripts.s3.components.column'
local row = require 'scripts.s3.components.row'
local spacer = require 'scripts.s3.components.spacer'
local text = require 'scripts.s3.components.text'

local UtilVector2 = util.vector2
local red = util.color.rgb(0.95, 0.25, 0.20)
local green = util.color.rgb(0.35, 0.90, 0.45)
local gap = UtilVector2(12, 0)

local function settings(scope, suffix)
  return scope.build {
    recipe = 'settings',
    title = 'H3UI settings ' .. suffix,
    fields = {
      {
        kind = 'toggle',
        label = 'Enabled',
        value = true,
        onChange = I.H3ComponentTest.refresh,
      },
      {
        kind = 'number',
        label = 'Page size',
        value = 20,
        min = 5,
        max = 100,
        step = 5,
        integer = true,
        onChange = I.H3ComponentTest.refresh,
      },
      {
        kind = 'selector',
        label = 'Mode',
        items = { 'Compact', 'Balanced', 'Verbose' },
        selected = 2,
        onSelect = I.H3ComponentTest.refresh,
      },
    },
  }
end

local function action(scope, label)
  return scope.build {
    component = 'button',
    tone = 'danger',
    classes = { 'wide' },
    args = { label = label },
    style = {
      label = {
        props = { textSize = 18 },
      },
    },
  }
end

---@return openmw.ui.Layout
local function h3ui()
  local H3UI = I.H3UI

  local alternate = H3UI.theme {
    name = 'component-test-alternate',
    extends = H3UI.themes.morrowind,
    tokens = {
      color = {
        danger = red,
        titleColor = green,
      },
    },
    rules = {
      {
        selector = { component = 'text', recipe = 'settings', role = 'title' },
        style = { props = { textColor = H3UI.token 'color.titleColor' } },
      },
      {
        selector = { component = 'text', density = 'compact' },
        style = { props = { textSize = 13 } },
      },
      {
        selector = { component = 'button', tone = 'danger', slot = 'label' },
        style = { props = { textColor = H3UI.token 'color.danger' } },
      },
      {
        selector = { class = 'wide' },
        style = { external = { grow = 1 } },
      },
    },
  }

  local vanilla = H3UI.scope { theme = H3UI.themes.morrowind }
  local styled = H3UI.scope { theme = alternate, density = 'compact' }

  return column {
    name = 'ct_demo_h3ui',
    children = {
      text { text = 'H3UI: identical recipes, isolated scoped themes' },
      row {
        children = {
          bookFrame {
            title = 'Morrowind scope',
            children = {
              settings(vanilla, '(default)'),
              action(vanilla, 'Danger action'),
            },
          },
          spacer { props = { size = gap } },
          bookFrame {
            title = 'Alternate compact scope',
            children = {
              settings(styled, '(styled)'),
              action(styled, 'Danger action'),
            },
          },
        },
      },
    },
  }
end

return h3ui
