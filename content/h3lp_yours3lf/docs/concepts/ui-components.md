---
title: UI Layouts and Lifecycle
description: Build, mount, update, and own OpenMW UI layouts.
weight: 25
extra:
  kind: concept
---

H3 components build OpenMW layout tables. They do not create elements, choose layers, retain your state, or own the lifetime of a rendered surface.

{% usage_note(title="Runnable context · Register a menu or player script") %}
UI code runs in a registered `menu` or `player` script. Requiring `openmw.ui` does not register a script or make code execute. Add the script to your mod's `.omwscripts` or plugin configuration and enable that content.
{% end %}

{% usage_note(title="Menu and player layouts · Caller owns the element") %}
Keep the root element, choose its layer, and decide when to rebuild or destroy it. Keep interactive state in your script. For interactive H3UI, give the scope an `element` resolver; H3 redraws its own semantic mutations while the application retains element lifetime and state ownership.
{% end %}

## Layout, mount, and update

A layout is a Lua table that describes one widget and its children. An element is the live OpenMW object created from that table. H3 components return layouts; `ui.create` gives you the element.

```lua
local ui = require 'openmw.ui'
local I = require 'openmw.interfaces'

local element
local h3ui = I.H3UI.scope {
  element = function() return element end,
}

local enabled = false
local status = h3ui.text 'Disabled'
local toggle = h3ui.toggle {
  value = enabled,
  onChange = function(value)
    enabled = value
    status.props.text = value and 'Enabled' or 'Disabled'
  end,
}

element = ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    h3ui.column {
      toggle,
      status,
    },
  },
}
```

`toggle` and `status` are layouts. `element` is the live mounted OpenMW object. The toggle mutates its own label, runs `onChange`, then H3 redraws through the scope's element resolver, so the dependent `status` mutation is included in the same update. For localized structural replacement, use `h3ui.setChildren(layout, children)` so the parent layout keeps its identity. Rebuild the root only when the structure genuinely requires it. A full rebuild destroys the old OpenMW widgets, including TextEdit focus, so do not rebuild a search/form root for every `textChanged` event.

## Callbacks and context

H3 semantic callbacks such as `button.onActivate`, `toggle.onChange`, and `selector.onSelect` are ordinary Lua functions. Raw OpenMW callbacks supplied through an `events` table still use OpenMW event semantics, but normal controls should not require that plumbing. Interactive components update their own layout state before calling your callback, but they do not know which root owns the rendered tree.

Keep these components in `menu` or `player` scripts. A global or local script can coordinate state, but it cannot directly use the UI package.

Use the [H3UI interface](@/h3lp_yours3lf/docs/api/interfaces/h3ui.md) as the normal constructor surface. The [UI Components API](@/h3lp_yours3lf/docs/api/components/_index.md) documents individual option contracts, while the [UI Recipes](@/h3lp_yours3lf/docs/examples/ui-recipes.md) show larger copyable compositions.
