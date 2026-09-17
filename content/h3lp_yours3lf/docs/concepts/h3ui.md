---
title: H3UI and Styling
description: Use one constructor facade for H3 components and recipes while keeping layout ownership explicit.
weight: 30
extra:
  kind: concept
---

H3UI is the application-facing UI surface for H3. The important design rule is simple:

> Application code should describe the interface it wants, not the module graph that happens to implement it.

Ordinary scripts therefore construct both primitive controls and higher-level recipes through the same object:

```lua
local I = require 'openmw.interfaces'
local ui = I.H3UI.scope { invalidate = refresh }

return ui.window {
    title = 'My Mod',
    ui.column {
        gap = 8,
        ui.text 'Settings',
        ui.settings { fields = fields },
        ui.button {
            label = 'Apply',
            tone = 'positive',
            onActivate = apply,
        },
    },
}
```

Whether `button` is a primitive component and `settings` is a recipe is useful information to H3's resolver and theme engine. It is not ceremony every mod author should repeat.

## A construction-time compiler, not a widget runtime

H3UI resolves recipes and styles while constructing ordinary OpenMW layouts:

```text
H3UI constructor call
    ↓
recipe expansion when needed
    ↓
semantic component nodes
    ↓
style resolution
    ↓
H3 component builders
    ↓
openmw.ui.Layout
    ↓
caller ui.create(...)
    ↓
caller element:update() / destroy()
```

There is no virtual DOM, retained style graph, polling loop, automatic root traversal, or extra `onFrame` work.

The caller still owns application state and the mounted root. If a callback changes what should be displayed, update or rebuild the caller-owned layout. H3UI's runtime hover/pressed support is deliberately narrower: it mutates generated style properties and may call a scope's `invalidate` callback, but it never takes ownership of the element.

## Components and recipes share one public path

The constructor facade deliberately hides require-spam:

```lua
ui.row {
    gap = 6,
    ui.text 'Name',
    ui.textInput { text = name, onChange = setName },
}
```

not:

```text
require row
require text
require textInput
assemble them manually
```

The low-level component modules still exist because H3 itself and recipe authors need them, but they are not the application-level teaching path.

String-based `ui.component(name, spec)` and `ui.recipe(name, spec)` remain available for dynamic or framework code. Known controls should use their named constructors so LuaLS and the documentation can expose their contracts directly.

## Structure, traits, presentation

A recipe owns **structure**: which H3 components are composed and how they nest.

A component node carries **traits**: component name, recipe identity, role, variant, tone, and classes.

A theme owns **presentation**: rules target those meanings and write through public component style slots. The player settings supply the active palette.

This keeps ordinary application code semantic:

```lua
ui.button {
    role = 'deleteCharacter',
    tone = 'negative',
    label = 'Delete',
}
```

instead of hard-coding whichever literal color happens to represent destructive actions today.

## Why roles instead of tree selectors

A confirm-dialog recipe may currently build:

```text
bookFrame
└── content
    ├── message
    └── actions row
```

A theme should not encode that exact tree. It can target:

```lua
selector = {
    recipe = 'confirmDialog',
    role = 'actions',
}
```

The recipe can later wrap or rearrange the row without breaking a theme that cares about its meaning.

## Why style slots instead of child traversal

A button's generated label is an implementation detail, but `labelProps` is a stable styling surface. The adapter exposes it as the `label` slot:

```text
button.label → button option labelProps
```

Themes never search through arbitrary generated child indexes hoping to find the label. The same rule applies to slots such as `window.captionText`, `itemSlot.count`, and `listItem.secondary`.

## Why recipes do not own models

`itemGrid` composes item slots, but it is not an inventory system. `searchableList` filters its supplied items during construction, but it does not own the query or search algorithm. `settings` composes controls, but it does not persist settings.

Recipes exist when recognizable semantic structure removes meaningful repeated assembly. They do not absorb application data models into H3.

That also sets the bar for adding recipes: if ordinary composition is already shorter and clearer, a new recipe is not justified.

## Why appearance is player-configured

H3 is shared by unrelated mods. A process-wide `setTheme()` would let one mod restyle another mod's interface. H3UI therefore has one player-owned appearance configuration, and every scope uses it:

```lua
local inventoryUi = H3UI.scope()
local journalUi = H3UI.scope()
```

Both use the same configured appearance while retaining independent recipes and invalidation behavior. Mods may register additional presets, but only the player settings select them.

## Runtime interaction state

Theme rules may target generated `hover` and `pressed` states:

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

H3UI applies hover on focus gain, pressed for the primary mouse button, and restores the previous generated style on focus loss or release. Explicit component options and inline style still win over theme state rules.

Application code does not set arbitrary component `state`. Semantic concepts belong to the components that actually implement them: `listItem`, `itemSlot`, and `iconButton` expose `selected`, while runtime `hover`/`pressed` remains theme-owned.

## Reference fixtures are part of the API design process

H3's component test suite is intentionally split between two jobs:

- small diagnostic fixtures isolate engine invariants such as sizing, boundaries, event composition, and window geometry;
- application-grade reference fixtures exercise the public H3UI surface the way a real mod would.

The reference fixtures include a Morrowind-style Magic menu, an inventory/item-grid surface, and a tabbed mod configuration window. They are meant to remain readable and screenshot-worthy, not merely dense widget torture tests.

When a realistic fixture requires the same awkward structure repeatedly, that is evidence for a new component or recipe. This keeps the high-level API usage-driven instead of growing abstractions in the abstract.

## Boundaries

H3UI intentionally does not include:

- CSS strings or a CSS parser;
- arbitrary ancestor/descendant selectors;
- sibling or `nth-child` selectors;
- general inherited style properties;
- animation or transitions;
- a public theme-selection API or a global mutable active theme;
- caller-supplied arbitrary component state;
- retained application models.

See [H3UI](@/h3lp_yours3lf/docs/api/interfaces/h3ui.md) for the concrete API and [UI Layouts and Lifecycle](@/h3lp_yours3lf/docs/concepts/ui-components.md) for mounting and update ownership.

For the underlying OpenMW UI ownership model and the path from a primitive layout to a reusable recipe, see Cod3x's [UI: From Nothing to Something](@/cod3x/docs/getting-started/ui.md).
