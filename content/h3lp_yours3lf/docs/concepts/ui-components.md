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
Keep the root element, choose its layer, and decide when to rebuild or destroy it. Keep interactive state in your script. H3 callbacks report the new value after updating the component layout; refresh the mounted root with `element:update()` when the visual tree needs to change.
{% end %}

## Layout, mount, and update

A layout is a Lua table that describes one widget and its children. An element is the live OpenMW object created from that table. H3 components return layouts; `ui.create` gives you the element.

```lua
local ui = require 'openmw.ui'
local I = require 'openmw.interfaces'

local status = I.H3UI.text {
  text = 'Ready',
}

local element = ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    status,
  },
}

status.props.text = 'Updated'
element:update()
```

`status` is a layout. `element` is the live mounted OpenMW object. Mutating the layout table does not redraw the engine until the owning element is updated. Use a `Container` for a content-fitting root; use a `Widget` when you need explicit `size` or `relativeSize`. Rebuild the root for structural changes; use `element:update()` for property changes. A full rebuild destroys the old OpenMW widgets, including TextEdit focus. Do not rebuild a search/form root from every `textChanged` event: keep the edited value in `onChange`, then rebuild on `onCommit`/focus loss, or update a stable mounted subtree without replacing the focused editor.

## Callbacks and context

H3 semantic callbacks such as `button.onActivate`, `toggle.onChange`, and `selector.onSelect` are ordinary Lua functions. Raw OpenMW callbacks supplied through an `events` table still use OpenMW event semantics, but normal controls should not require that plumbing. Interactive components update their own layout state before calling your callback, but they do not know which root owns the rendered tree.

Keep these components in `menu` or `player` scripts. A global or local script can coordinate state, but it cannot directly use the UI package.

Use the [H3UI interface](@/h3lp_yours3lf/docs/api/interfaces/h3ui.md) as the normal constructor surface. The [UI Components API](@/h3lp_yours3lf/docs/api/components/_index.md) documents individual option contracts, while the [UI Recipes](@/h3lp_yours3lf/docs/examples/ui-recipes.md) show larger copyable compositions.
