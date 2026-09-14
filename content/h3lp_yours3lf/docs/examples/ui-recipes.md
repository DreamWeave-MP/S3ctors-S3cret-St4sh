---
title: UI Recipes
description: Copyable H3UI compositions for common OpenMW UI surfaces.
weight: 45
extra:
  kind: example
---

These recipes use H3UI's passive builders. Put them in a registered `menu` or `player` script; requiring a component does not run a script. Keep application state and the mounted root in your script, and call `element:update()` when a callback changes what should be displayed. Each content-only root uses `ui.TYPE.Container` so it sizes itself to its children.

{% usage_note(title="Two levels · recipes or direct components") %}
The examples below remain useful low-level compositions. H3 also installs `I.H3UI`, which can build the same kinds of surfaces from recipes and scoped themes. `H3UI.build` still returns an ordinary caller-owned layout; it does not replace `ui.create` or `element:update()`.
{% end %}

## H3UI settings panel

The high-level settings recipe removes the repeated row/label/control assembly while leaving values and redraw ownership in your script:

```lua
local ui = require 'openmw.ui'
local I = require 'openmw.interfaces'

local H3UI = I.H3UI
local enabled = true
local intensity = 50
local pageSize = 20
local element

local function build()
    return H3UI.build {
        recipe = 'settings',
        title = 'Settings',
        fields = {
            {
                kind = 'toggle',
                label = 'Enabled',
                value = enabled,
                onChange = function(value)
                    enabled = value
                    element:update()
                end,
            },
            {
                kind = 'slider',
                label = 'Intensity',
                value = intensity,
                min = 0,
                max = 100,
                step = 5,
                onChange = function(value)
                    intensity = value
                    element:update()
                end,
            },
            {
                kind = 'number',
                label = 'Page size',
                value = pageSize,
                min = 5,
                max = 100,
                step = 5,
                integer = true,
                onChange = function(value)
                    pageSize = value
                    element:update()
                end,
            },
        },
    }
end

element = ui.create {
    type = ui.TYPE.Container,
    layer = 'Windows',
    content = ui.content { build() },
}
```

The recipe does not persist any setting. It simply composes existing H3 controls.

## Scoped styling

```lua
local util = require 'openmw.util'
local H3UI = require('openmw.interfaces').H3UI

local dangerTheme = H3UI.theme {
    name = 'danger-demo',
    extends = H3UI.themes.morrowind,
    tokens = {
        color = {
            danger = util.color.rgb(1, 0.25, 0.2),
        },
    },
    rules = {
        {
            selector = {
                component = 'button',
                tone = 'danger',
                slot = 'label',
            },
            style = {
                props = {
                    textColor = H3UI.token('color.danger'),
                },
            },
        },
    },
}

local MyH3UI = H3UI.scope { theme = dangerTheme }

local deleteButton = MyH3UI.build {
    component = 'button',
    tone = 'danger',
    args = { label = 'Delete' },
}
```

The theme is local to `MyH3UI`; another mod or another scope can use `H3UI.themes.morrowind` at the same time. See [H3UI](@/h3lp_yours3lf/docs/api/interfaces/h3ui.md) for selectors, traits, tokens, classes, style slots, cascade order, and diagnostics.

## Settings panel

Compose a small settings surface from a column, labels, toggle, slider, and numeric input. Interactive callbacks update the mounted root after changing their state.

```lua
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local column = require 'scripts.s3.components.column'
local numberInput = require 'scripts.s3.components.numberInput'
local row = require 'scripts.s3.components.row'
local slider = require 'scripts.s3.components.slider'
local text = require 'scripts.s3.components.text'
local toggle = require 'scripts.s3.components.toggle'

local enabled = true
local intensity = 50
local pageSize = 20
local element

element = ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    column {
      children = {
        text {
          text = 'Settings',
        },
        row {
          children = {
            text {
              text = 'Enabled',
            },
            toggle {
              value = enabled,
              onChange = function(value)
                enabled = value
                element:update()
              end,
            },
          },
        },
        text {
          text = 'Intensity',
        },
        slider {
          value = intensity,
          min = 0,
          max = 100,
          step = 5,
          props = {
            size = util.vector2(260, 18),
          },
          onChange = function(value)
            intensity = value
            element:update()
          end,
        },
        row {
          children = {
            text {
              text = 'Page size',
            },
            numberInput {
              value = pageSize,
              min = 5,
              max = 100,
              step = 5,
              integer = true,
              onChange = function(value)
                pageSize = value
                element:update()
              end,
            },
          },
        },
      },
    },
  },
}
```

See [toggle](@/h3lp_yours3lf/docs/api/components/toggle.md), [slider](@/h3lp_yours3lf/docs/api/components/slider.md), and [numberInput](@/h3lp_yours3lf/docs/api/components/number-input.md).

## Inventory-ish grid

`grid` does not know anything about inventory. Give it item-slot layouts, then use focus events to show a caller-owned tooltip beside the grid.

```lua
local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local grid = require 'scripts.s3.components.grid'
local itemSlot = require 'scripts.s3.components.itemSlot'
local text = require 'scripts.s3.components.text'
local tooltip = require 'scripts.s3.components.tooltip'

local iconSize = util.vector2(72, 72)
local red = util.color.rgb(1, 0, 0)
local green = util.color.rgb(0, 1, 0)
local blue = util.color.rgb(0, 0, 1)

local tooltipText = text {
  text = '',
}
local tooltipLayout = tooltip {
  props = {
    position = util.vector2(320, 80),
    visible = false,
  },
  children = {
    tooltipText,
  },
}
local element

local function slot(label, count, color)
  return itemSlot {
    resource = {
      path = 'white',
    },
    count = count,
    iconProps = {
      size = iconSize,
      color = color,
    },
    events = {
      focusGain = async:callback(function()
        tooltipText.props.text = label
        tooltipLayout.props.visible = true
        element:update()
      end),
      focusLoss = async:callback(function()
        tooltipLayout.props.visible = false
        element:update()
      end),
    },
  }
end

element = ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    grid {
      columns = 3,
      items = {
        slot('Restore potion', 3, red),
        slot('Torch', 1, green),
        slot('Lockpick', 12, blue),
      },
    },
    tooltipLayout,
  },
}
```

For real inventory data, rebuild or update the owner when item data changes. See [grid](@/h3lp_yours3lf/docs/api/components/grid.md), [itemSlot](@/h3lp_yours3lf/docs/api/components/item-slot.md), and [tooltip](@/h3lp_yours3lf/docs/api/components/tooltip.md).

## Tabbed window

Tabs select a label and report the item; they do not own page content. Keep the page layout beside the tab strip and update it in `onSelect`.

```lua
local ui = require 'openmw.ui'
local column = require 'scripts.s3.components.column'
local tabs = require 'scripts.s3.components.tabs'
local text = require 'scripts.s3.components.text'
local window = require 'scripts.s3.components.window'

local pages = {
  'General',
  'Advanced',
}
local pageText = text {
  text = 'General settings',
}
local element

element = ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    window {
      title = 'Preferences',
      children = {
        column {
          children = {
            tabs {
              items = pages,
              onSelect = function(_, label)
                pageText.props.text = label .. ' settings'
                element:update()
              end,
            },
            pageText,
          },
        },
      },
    },
  },
}
```

See [tabs](@/h3lp_yours3lf/docs/api/components/tabs.md) and [window](@/h3lp_yours3lf/docs/api/components/window.md).

## Searchable list

Keep filter state outside the components. Replace the root's content and update the existing element when the query changes; do not destroy and recreate the root during the input callback.

```lua
local ui = require 'openmw.ui'
local column = require 'scripts.s3.components.column'
local list = require 'scripts.s3.components.list'
local listItem = require 'scripts.s3.components.listItem'
local searchInput = require 'scripts.s3.components.searchInput'

local names = {
  'Almalexia',
  'Baurus',
  'Caius Cosades',
}
local element

local function matches(name, query)
  return query == ''
    or string.find(string.lower(name), string.lower(query), 1, true) ~= nil
end

local function build(query)
  local items = {}
  for _, name in ipairs(names) do
    if matches(name, query) then
      items[#items + 1] = listItem {
        label = name,
      }
    end
  end

  return column {
    children = {
      searchInput {
        value = query,
        onChange = function(nextQuery)
          element.layout.content = ui.content {
            build(nextQuery),
          }
          element:update()
        end,
      },
      list {
        items = items,
      },
    },
  }
end

element = ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    build(''),
  },
}
```

See [searchInput](@/h3lp_yours3lf/docs/api/components/search-input.md) and [list](@/h3lp_yours3lf/docs/api/components/list.md).
