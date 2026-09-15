---@omw-context player

local I = require 'openmw.interfaces'
local util = require 'openmw.util'

local column = require 'scripts.s3.components.column'
local row = require 'scripts.s3.components.row'
local spacer = require 'scripts.s3.components.spacer'
local text = require 'scripts.s3.components.text'

local UtilVector2 = util.vector2
local gap = UtilVector2(12, 0)

local function settings(scope, suffix, invalidate)
  return scope.build {
    recipe = 'settings',
    invalidate = invalidate,
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

local function action(scope, label, invalidate)
  return scope.build {
    component = 'button',
    invalidate = invalidate,
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

local function frame(scope, title, children, invalidate)
  return scope.build {
    component = 'bookFrame',
    invalidate = invalidate,
    args = {
      title = title,
      children = children,
    },
  }
end

---@param invalidate? fun()
---@return openmw.ui.Layout
local function h3ui(invalidate)
  local H3UI = I.H3UI
  local scoped = H3UI.scope { density = 'compact' }

  return column {
    name = 'ct_demo_h3ui',
    children = {
      text { text = 'H3UI: shared player-configured appearance' },
      row {
        children = {
          frame(H3UI, 'Configured appearance', {
            settings(H3UI, '(player settings)', invalidate),
            action(H3UI, 'Danger action', invalidate),
          }, invalidate),
          spacer { props = { size = gap } },
          frame(scoped, 'Compact scope', {
            settings(scoped, '(density only)', invalidate),
            action(scoped, 'Hover me', invalidate),
          }, invalidate),
        },
      },
    },
  }
end

return h3ui
