---
title: H3UI and Styling
description: Build high-level UI from recipes and style it with scoped themes without changing H3's layout lifecycle.
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
recipes + scoped themes
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

If a callback changes application state, H3UI still cannot know which mounted root should redraw. The caller owns that decision.

## Structure, traits, presentation

A recipe owns **structure**: which H3 components are composed and how they nest.

A component node carries **traits**: component name, recipe, role, variant, tone, density, classes, and optional state.

A theme owns **presentation**: rules that target those meanings and write through public component style slots.

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

## Why themes are scoped

H3 is shared by unrelated mods. A process-wide `setTheme()` would let one mod accidentally restyle another mod's interface. Instead, a scope carries an immutable theme selection into one build tree:

```lua
local InventoryH3UI = H3UI.scope { theme = inventoryTheme }
local JournalH3UI = H3UI.scope { theme = journalTheme }
```

Both can coexist in the same player/menu context.

## Why recipes do not own models

`itemGrid` composes item slots, but it is not an inventory system. `searchableList` composes a search field and list, but it does not own the query or filter your collection. `settings` composes controls, but it does not persist settings.

Recipes remove repeated UI assembly. They do not absorb application data models into H3.

## Version 1 boundaries

The initial engine intentionally does not include:

- CSS strings or a CSS parser;
- arbitrary ancestor/descendant selectors;
- sibling or `nth-child` selectors;
- general inherited style properties;
- animation or transitions;
- dynamic hover/pressed machinery that would require a new retained lifecycle;
- a global mutable active theme.

`state` exists in the selector vocabulary for explicit/build-time node state and future growth, but H3 does not create an automatic browser-like pseudo-state engine.

See [H3UI](@/h3lp_yours3lf/docs/api/interfaces/h3ui.md) for the concrete API and [UI Layouts and Lifecycle](@/h3lp_yours3lf/docs/concepts/ui-components.md) for mounting and update ownership.
