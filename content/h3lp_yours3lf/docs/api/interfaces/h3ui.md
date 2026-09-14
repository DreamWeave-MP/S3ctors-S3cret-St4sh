---
title: H3UI
description: Build high-level H3 layouts from recipes and style them with scoped themes.
weight: 15
extra:
  kind: api
---

{{ api_signature(value="require 'openmw.interfaces'.H3UI → H3UI") }}

`I.H3UI` is H3's high-level UI layer. It sits above the ordinary component builders: recipes produce component nodes, theme rules resolve into component style slots, and `build` returns the same caller-owned `openmw.ui.Layout` values used everywhere else in H3.

{% usage_note(title="Installed interface · Menu and player") %}
The plugin installs `I.H3UI` in menu and player contexts. You may also `require 'scripts.s3.ui'` directly from either context. Local and global scripts cannot use OpenMW UI and do not receive this facade.
{% end %}

{% usage_note(title="Build is not mount") %}
`H3UI.build(...)` never calls `ui.create`, chooses a layer, owns a root element, updates your root, or persists application state. Mount the returned layout yourself and call `element:update()` when your application changes visible layout state.
{% end %}

## Build a recipe

```lua
local ui = require 'openmw.ui'
local I = require 'openmw.interfaces'
local util = require 'openmw.util'

local H3UI = I.H3UI
local element

local layout = H3UI.build {
    recipe = 'dialog',
    variant = 'confirm',
    tone = 'danger',
    props = {
        position = util.vector2(80, 80),
        size = util.vector2(320, 120),
    },
    title = 'Delete save?',
    body = 'There is no undo.',
    actions = {
        {
            role = 'cancel',
            label = 'Cancel',
            onActivate = function()
                element:destroy()
            end,
        },
        {
            role = 'confirm',
            tone = 'danger',
            label = 'Delete',
            onActivate = function()
                element:destroy()
            end,
        },
    },
}

element = ui.create {
    type = ui.TYPE.Container,
    layer = 'Windows',
    content = ui.content { layout },
}
```

## Build a styled primitive

Recipes are optional. An H3UI build can apply the same theme machinery to an existing H3 primitive:

```lua
local button = H3UI.build {
    component = 'button',
    tone = 'danger',
    classes = { 'wide' },
    args = {
        label = 'Delete',
    },
}
```

The component name is the H3 builder name (`button`, `row`, `itemSlot`, `searchInput`, and so on). `args` are ordinary options for that component. Behavioral values stay in `args`; visual overrides belong in `style` or the theme.

## Themes

Create a compiled theme with `H3UI.theme`:

```lua
local dangerColor = require('openmw.util').color.rgb(1, 0.25, 0.2)

local theme = H3UI.theme {
    name = 'myMod',
    extends = H3UI.themes.morrowind,
    tokens = {
        color = {
            danger = dangerColor,
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
```

A theme may extend another compiled theme. Parent tokens are merged first, child tokens override them, parent rules keep their source order, and child rules follow them. Token references are resolved against the final derived token set, so overriding a token also affects inherited rules that reference it.

Unknown token paths, token cycles, unknown selector fields, unknown component names, and invalid style slots are errors rather than silent no-ops.

### Built-in theme

`H3UI.themes.morrowind` is the compatibility theme. Existing H3 primitives still provide their current Morrowind defaults; the theme supplies shared tokens and a base for derived themes without forcing the low-level components through H3UI.

## Scoped themes

Themes are intentionally not global mutable state:

```lua
local MyH3UI = H3UI.scope {
    theme = theme,
    density = 'compact',
}

local layout = MyH3UI.build {
    recipe = 'settings',
    title = 'My Mod',
    fields = fields,
}
```

Two scopes may use different themes in the same script without affecting one another. A scope may also provide local recipes:

```lua
local MyH3UI = H3UI.scope {
    theme = theme,
    recipes = {
        ['myMod:characterCard'] = function(ctx, spec)
            return ctx.component('column', {
                role = 'root',
                args = {
                    children = {
                        ctx.component('text', {
                            role = 'name',
                            args = { text = spec.name },
                        }),
                    },
                },
            })
        end,
    },
}
```

Local recipes shadow built-ins only inside that scope.

## Selectors

Version 1 selectors are explicit Lua data:

```lua
selector = {
    component = 'button',
    recipe = 'dialog',
    role = 'confirm',
    variant = 'primary',
    tone = 'danger',
    density = 'compact',
    class = 'important',
    state = 'selected',
    slot = 'label',
}
```

All supplied fields must match. `class` tests membership in the node's class set. `slot` chooses the component style target and does not itself increase specificity.

Selectors match component traits such as `variant`, `tone`, `density`, `role`, and `class`.

H3 intentionally does not parse CSS selector strings and does not implement descendant, sibling, `nth-child`, or arbitrary tree selectors. Recipes expose `role` values so themes can target a component's job instead of incidental child positions.

## Cascade

Matched rules apply from lower to higher precedence:

1. generic/component rules;
2. recipe/role rules;
3. `variant`, `tone`, or `density` rules;
4. class rules;
5. state rules.

Inside one tier, a rule with more selector constraints wins; exact ties use later source order. Component options supplied in `args` override theme-provided style values, and explicit instance `style` is applied last.

A primitive's own defaults remain below the H3UI style cascade because the component builder receives the resolved options and fills anything still absent.

## Style slots

A slot is a stable styling target exposed by a component adapter. Root slots generally support:

```lua
style = {
    root = {
        props = { ... },
        external = { ... },
        template = someTemplate,
    },
}
```

Generated subparts expose narrower slots when the underlying component already has a stable public option for them. Examples include:

| Component | Extra slots |
| --- | --- |
| `button` | `label` |
| `dialog`, `bookFrame` | `title` |
| `iconButton` | `icon`, `label` |
| `itemSlot` | `icon`, `count` |
| `meter`, `slider` | `fill`, `empty` |
| `listItem`, `toggle` | `label` |
| `tooltip` | `text` |
| `window` | `caption` |
| `grid` | `row` |
| `tabs` | `button`, `selected`, `label`, `selectedLabel` |
| `selector` | `button`, `icon`, `label` |
| `searchInput` | `input` |

Use `H3UI.slots('button')` to inspect the registered slot names for a component.

Generated-child slots do not grant permission to traverse caller-owned custom content. If a component option such as `content`/`children` replaces the generated label or text child, the corresponding slot may have no rendered target; H3 does not mutate the replacement tree on the theme's behalf.

A rule with `selector.slot` writes directly to that slot:

```lua
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
}
```

A rule without `slot` targets `root`.

## Inline style and `H3UI.UNSET`

Inline styles can address multiple slots and always apply after theme rules and ordinary component arguments:

```lua
H3UI.build {
    component = 'button',
    args = { label = 'Wide' },
    style = {
        root = {
            external = { grow = 1 },
        },
        label = {
            props = { textSize = 20 },
        },
    },
}
```

Use `H3UI.UNSET` when a later style must explicitly remove an inherited style key instead of replacing it with another value.

## Built-in recipes

### `dialog`

Inputs include `title`, `body`, `children`/`content`, `tone`, `density`, `classes`, and ordinary dialog options. `variant = 'confirm'` selects the confirm structure. Because the result is a `ui.TYPE.Widget`, provide `props.size` or `props.relativeSize` when mounting it directly.

### `dialog` + `variant = 'confirm'`

Adds an `actions` row. Each action may supply `role`, `label`, `tone`, `classes`, `style`, `args`, and `onActivate`. If `actions` is omitted while `onConfirm` or `onCancel` is supplied, H3 generates conventional Cancel/Confirm actions.

### `settings`

Builds labelled fields from existing H3 controls. `fields`/`entries` support `toggle`, `slider`, `number`, `selector`, `text`, or an explicit `component`. Application state remains caller-owned.

### `itemGrid`

Builds `grid` + `itemSlot` composition. Item descriptors are presentation data only; the recipe does not query or own inventory.

### `tabbedWindow`

Builds `window` + `tabs` + page content. Tabs retain only the same local selection behavior as the existing H3 tabs component; page/application state remains yours.

### `searchableList`

Builds `searchInput` + `list` + `listItem`. It does not filter your data. Pass already filtered `items`, update your query in `onQueryChange`, rebuild or replace the caller-owned layout as needed, and update the mounted root.

## Diagnostics

`H3UI.explain(spec)` resolves the same build without mounting it and returns:

```lua
{
    layout = resolvedLayout,
    theme = 'theme name',
    nodes = {
        {
            component = 'button',
            recipe = 'dialog',
            role = 'confirm',
            matched = {
                -- matching rule selectors, tier, specificity and source order
            },
            themeStyle = { ... },
            inlineStyle = { ... },
        },
    },
}
```

Use it when a theme rule does not appear to win the way you expect.
