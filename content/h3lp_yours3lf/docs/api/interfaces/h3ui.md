---
title: H3UI
description: Build high-level H3 layouts from recipes and render them with the player's configured appearance.
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

For runtime `hover` and `pressed` styling, you may also pass `invalidate = function() ... end` in the build spec. H3UI calls it after a state transition changes a styled property, allowing the caller to update its mounted `Element` without transferring ownership to H3UI.
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

## Appearance and registered themes

H3UI uses the appearance selected in the player's settings. Scripts describe UI structure and meaning; they do not select the active palette.

```lua
local H3UI = require('openmw.interfaces').H3UI

H3UI.registerTheme {
    id = 'myMod:danger',
    name = 'Danger',
    description = 'A red-accented appearance.',
    author = 'My Mod',
    tokens = {
        color = {
            danger = require('openmw.util').color.rgb(1, 0.25, 0.2),
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

Registration adds a preset to `Settings → H3UI → Appearance`. It does not select the preset and there is no public theme-selection function or compiled-theme table.

The built-in presets are `Morrowind`, `Starwind`, and `Custom`. Selecting a preset copies its palette into the player settings. Editing a color changes the selection to `Custom`; resetting restores the canonical Morrowind palette. The default is Morrowind, unless an optional `scripts.s3.ui.defaultTheme` hint or the built-in Starwind content-file detection supplies another default.

The settings group uses the player section `SettingsPlayerH3UI`; its saved Custom palette lives separately in `SettingsPlayerH3UICustom`. The visible `theme` value is a registered theme ID or `custom`, and its color values are six-digit hexadecimal strings. Custom starts with the canonical Morrowind palette, keeps edits while presets are cycled, and is not reset when the visible settings group is reset. `menuTransparency` controls H3UI window backgrounds from transparent (`0.0`) to opaque (`1.0`) and defaults to `0.84`, matching OpenMW's default GUI setting. `textSizeNormal` defaults to `16`, matching OpenMW's default `font size`; `textSizeHeader` defaults to H3's `18`-pixel header size. Both can be configured independently in the H3UI settings page. The `enableDebugHotkeys` setting is disabled by default; enabling it allows F7 to cycle component demos and Shift+F7 to reload Lua. Writing the visible values is the supported integration point for a total conversion or curated setup that wants to configure the player's shared H3UI appearance.

The internal theme compiler still supports selectors, rules, and token references. A registered theme may provide additional rules and tokens, but its palette is resolved through the player's configured color settings.

The public registration shape is:

```lua
H3UI.registerTheme {
    id = 'myMod:theme',
    name = 'My Theme',
    tokens = { color = { accent = require('openmw.util').color.rgb(1, 0.5, 0) } },
    rules = {},
}
```

Theme IDs must be stable and unique. Namespaced IDs such as `myMod:theme` are recommended. A registered theme may use `extends` with another registered theme ID; otherwise it extends the built-in Morrowind rules internally. Token references are resolved against the final derived token set.

Unknown token paths, token cycles, unknown selector fields, unknown component names, and invalid style slots are errors rather than silent no-ops.

### Built-in presets

The canonical Morrowind and Starwind palettes are registered internally. Existing H3 primitives still provide their current Morrowind defaults; H3UI supplies the configured tokens without forcing low-level components through this facade. H3UI no longer reads `FontColor_*` GMST values during normal operation.

## Scopes

Scopes provide density, invalidation, and local recipes. Appearance remains shared and player-configured:

```lua
local MyH3UI = H3UI.scope {
    density = 'compact',
}

local layout = MyH3UI.build {
    recipe = 'settings',
    title = 'My Mod',
    fields = fields,
}
```

Scopes may provide local recipes without changing the shared appearance:

```lua
local MyH3UI = H3UI.scope {
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
5. state rules. State rules may be applied again at runtime for generated `hover` and `pressed` states.

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
| `window` | `caption`, `captionText` |
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

Window captions expose two separate slots: `caption` styles the caption container, while `captionText` styles the title text passed to the caption component.

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
