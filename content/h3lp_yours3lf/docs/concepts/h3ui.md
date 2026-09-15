---
title: H3UI and Styling
description: Build high-level UI from recipes and render it with the player's configured appearance without changing H3's layout lifecycle.
weight: 30
extra:
  kind: concept
---

H3's low-level components answer **how do I build this OpenMW layout?** H3UI answers **what interface should I build, and how should it look?**

The layers are deliberately one-way:

```text
OpenMW UI
    ↑
H3 primitive components
    ↑
component style adapters
    ↑
component nodes + style resolver
    ↑
recipes + player-configured appearance
```

The low-level component library does not depend on H3UI. Existing code that directly requires `scripts.s3.components.button`, `row`, `window`, or any other primitive keeps working unchanged.

## A construction-time compiler, not a widget runtime

`H3UI.build` expands recipes and resolves styles while constructing a layout. Once built, the result is an ordinary OpenMW layout table. There is no virtual DOM, retained style graph, polling loop, automatic root traversal, or extra `onFrame` work.

That keeps H3's existing lifecycle intact:

```text
UI description
    ↓
recipe expansion
    ↓
component nodes
    ↓
style resolution
    ↓
existing H3 component builders
    ↓
openmw.ui.Layout
    ↓
caller ui.create(...)
    ↓
caller element:update() / destroy()
```

If a callback changes application state, H3UI still cannot know which mounted root should redraw. The caller owns that decision. Theme state rules are narrower: H3UI may update the generated style tables for `hover` and `pressed` events, but it never owns the mounted element or application state.

## Structure, traits, presentation

A recipe owns **structure**: which H3 components are composed and how they nest.

A component node carries **traits**: component name, recipe, role, variant, tone, density, classes, and optional state.

A theme owns **presentation**: rules that target those meanings and write through public component style slots. The player settings supply its active palette.

This is the useful part of CSS without importing CSS syntax or DOM assumptions into OpenMW Lua.

## Why roles instead of descendant selectors

A dialog recipe may currently build:

```text
dialog
└── column
    ├── message
    └── actions row
```

A theme should not need to encode that exact tree. It can target:

```lua
selector = {
    recipe = 'dialog',
    role = 'actions',
}
```

The recipe can later wrap or rearrange that row without breaking a theme that cares about its meaning.

## Why style slots instead of child traversal

A button's generated label is an implementation detail, but `labelProps` is already a stable public styling surface. The component adapter exposes that surface as the `label` slot.

The style engine therefore says:

```text
button.label → button option labelProps
```

It does **not** search through `layout.content[1].content[1]` and mutate whatever happens to be there today.

This keeps component implementation refactors from becoming theme-breaking API changes.

## Why appearance is player-configured

H3 is shared by unrelated mods. A process-wide `setTheme()` would let one mod accidentally or deliberately restyle another mod's interface. H3UI therefore has one player-owned appearance configuration, and every scope uses it:

```lua
local InventoryH3UI = H3UI.scope { density = 'compact' }
local JournalH3UI = H3UI.scope()
```

Both use the same configured palette while retaining independent density, recipes, and invalidation behavior. Mods may register additional presets, but only the player settings select them.

## Why recipes do not own models

`itemGrid` composes item slots, but it is not an inventory system. `searchableList` composes a search field and list, but it does not own the query or filter your collection. `settings` composes controls, but it does not persist settings.

Recipes remove repeated UI assembly. They do not absorb application data models into H3.

## Runtime state rules

`state` rules can style generated component slots while the component's layout is alive:

```lua
{
    selector = {
        component = 'button',
        slot = 'label',
        state = 'hover',
    },
    style = {
        props = {
            textColor = H3UI.token('color.textHover'),
        },
    },
}
```

H3UI applies `hover` on `focusGain`, `pressed` for the primary mouse button, and restores the previous state on `focusLoss` or mouse release. State rules only change properties exposed through registered slots. Explicit component arguments and inline style properties remain protected, so a caller's value wins over a state rule.

For now, an explicit component `state` is mutually exclusive with these runtime interaction states; H3UI does not install hover or pressed handlers when a component already has a state.

This is deliberately not a retained UI system. H3UI adds event callbacks to the returned layout and mutates the generated style tables; the caller still mounts, updates, and destroys the layout. If runtime state styling is used, pass an optional `invalidate` callback in the build spec. H3UI calls it only after a state transition changes a styled property, so the caller can update its mounted element without giving H3UI ownership of that element:

```lua
local ui = require 'openmw.ui'
local element
local layout = H3UI.build {
    component = 'button',
    args = { label = 'Refreshes on hover' },
    invalidate = function()
        if element and element.layout then element:update() end
    end,
}

element = ui.create {
    layer = 'Windows',
    content = ui.content { layout },
}
```

## Version 1 boundaries

The initial engine intentionally does not include:

- CSS strings or a CSS parser;
- arbitrary ancestor/descendant selectors;
- sibling or `nth-child` selectors;
- general inherited style properties;
- animation or transitions;
- a public theme-selection API or a global mutable active theme.

H3 still does not parse CSS strings or create a general pseudo-state engine. Runtime state is limited to the generated slot properties described above.

See [H3UI](@/h3lp_yours3lf/docs/api/interfaces/h3ui.md) for the concrete API and [UI Layouts and Lifecycle](@/h3lp_yours3lf/docs/concepts/ui-components.md) for mounting and update ownership.
