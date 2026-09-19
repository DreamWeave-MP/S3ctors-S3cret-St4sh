---
title: H3UI
description: Build H3 interfaces through one ergonomic constructor facade and render them with the player's configured appearance.
weight: 15
extra:
  kind: api
---

{{ api_signature(value="require 'openmw.interfaces'.H3UI → H3UI") }}

`I.H3UI` is the normal entry point for H3 interface code. Components and recipes are exposed through the same constructor facade, so ordinary mod code does not need to know which module implements a control or whether a higher-level surface is internally a recipe.

```lua
local I = require 'openmw.interfaces'

local ui = I.H3UI.scope {
    invalidate = refresh,
}

return ui.window {
    title = 'My Mod',

    ui.column {
        gap = 8,
        ui.text 'Configuration',
        ui.toggle {
            label = 'Enabled',
            value = enabled,
            onChange = setEnabled,
        },
        ui.button {
            label = 'Apply',
            tone = 'positive',
            onActivate = apply,
        },
    },
}
```

There is no component import list in normal H3UI code. `ui.window`, `ui.column`, `ui.button`, `ui.settings`, `ui.itemGrid`, and the rest all return ordinary caller-owned `openmw.ui.Layout` values.

{% usage_note(title="Installed interface · Menu and player") %}
The plugin installs `I.H3UI` in menu and player contexts. Local and global scripts cannot use OpenMW UI and do not receive this facade.
{% end %}

{% usage_note(title="Construction is not mounting") %}
H3UI never calls `ui.create`, chooses a layer, owns a root element, or persists application state. Mount the returned layout yourself. When application state changes what should be visible, update your mounted element.

Pass `invalidate` to a scope so H3 redraws its own in-place mutations: runtime hover/pressed transitions and semantic controls (toggles, sliders, selectors, windows) mutate their own layouts and then call it. Application callbacks run before the redraw, so dependent properties changed there are included. Use `ui.setChildren()` for localized structural replacement, and rebuild the root only when genuinely necessary.
{% end %}

## The normal constructor surface

The public component constructors are:

| Constructor | Component |
| --- | --- |
| [`bookFrame`](@/h3lp_yours3lf/docs/api/components/book-frame.md) | Framed book-style content. |
| [`box`](@/h3lp_yours3lf/docs/api/components/box.md) | Fixed or relative-size container. |
| [`button`](@/h3lp_yours3lf/docs/api/components/button.md) | Activatable labelled control. |
| [`collapsible`](@/h3lp_yours3lf/docs/api/components/collapsible.md) | Expandable content region. |
| [`column`](@/h3lp_yours3lf/docs/api/components/column.md) | Vertical flex layout. |
| [`divider`](@/h3lp_yours3lf/docs/api/components/divider.md) | Horizontal or vertical rule. |
| [`grid`](@/h3lp_yours3lf/docs/api/components/grid.md) | Multi-column item layout. |
| [`iconButton`](@/h3lp_yours3lf/docs/api/components/icon-button.md) | Activatable icon control. |
| [`image`](@/h3lp_yours3lf/docs/api/components/image.md) | Image or texture layout. |
| [`itemSlot`](@/h3lp_yours3lf/docs/api/components/item-slot.md) | Item icon and count layout. |
| [`list`](@/h3lp_yours3lf/docs/api/components/list.md) | List content container. |
| [`listItem`](@/h3lp_yours3lf/docs/api/components/list-item.md) | Activatable labelled list row. |
| [`meter`](@/h3lp_yours3lf/docs/api/components/meter.md) | Bounded fill meter. |
| [`numberInput`](@/h3lp_yours3lf/docs/api/components/number-input.md) | Numeric text input. |
| [`row`](@/h3lp_yours3lf/docs/api/components/row.md) | Horizontal flex layout. |
| [`searchInput`](@/h3lp_yours3lf/docs/api/components/search-input.md) | Search text input with clear control. |
| [`selector`](@/h3lp_yours3lf/docs/api/components/selector.md) | Previous/next value selector. |
| [`slider`](@/h3lp_yours3lf/docs/api/components/slider.md) | Bounded pointer-controlled value. |
| [`spacer`](@/h3lp_yours3lf/docs/api/components/spacer.md) | Empty fixed or growing space. |
| [`tabs`](@/h3lp_yours3lf/docs/api/components/tabs.md) | Tab-selection row. |
| [`text`](@/h3lp_yours3lf/docs/api/components/text.md) | Text layout. |
| [`textInput`](@/h3lp_yours3lf/docs/api/components/text-input.md) | Single-line text input. |
| [`toggle`](@/h3lp_yours3lf/docs/api/components/toggle.md) | Boolean labelled control. |
| [`tooltip`](@/h3lp_yours3lf/docs/api/components/tooltip.md) | Tooltip content layout. |
| [`window`](@/h3lp_yours3lf/docs/api/components/window.md) | Movable and resizable window. |

The built-in high-level recipe constructors are:

| Constructor | Relevant components |
| --- | --- |
| `confirmDialog` | [`bookFrame`](@/h3lp_yours3lf/docs/api/components/book-frame.md), [`button`](@/h3lp_yours3lf/docs/api/components/button.md), [`row`](@/h3lp_yours3lf/docs/api/components/row.md) |
| `dialog` | [`bookFrame`](@/h3lp_yours3lf/docs/api/components/book-frame.md) |
| `itemGrid` | [`grid`](@/h3lp_yours3lf/docs/api/components/grid.md), [`itemSlot`](@/h3lp_yours3lf/docs/api/components/item-slot.md) |
| `searchableList` | [`searchInput`](@/h3lp_yours3lf/docs/api/components/search-input.md), [`list`](@/h3lp_yours3lf/docs/api/components/list.md), [`listItem`](@/h3lp_yours3lf/docs/api/components/list-item.md) |
| `section` | [`column`](@/h3lp_yours3lf/docs/api/components/column.md), [`row`](@/h3lp_yours3lf/docs/api/components/row.md), [`text`](@/h3lp_yours3lf/docs/api/components/text.md), [`divider`](@/h3lp_yours3lf/docs/api/components/divider.md) |
| `settings` | [`column`](@/h3lp_yours3lf/docs/api/components/column.md), [`row`](@/h3lp_yours3lf/docs/api/components/row.md), [`text`](@/h3lp_yours3lf/docs/api/components/text.md), [`toggle`](@/h3lp_yours3lf/docs/api/components/toggle.md), [`slider`](@/h3lp_yours3lf/docs/api/components/slider.md), [`numberInput`](@/h3lp_yours3lf/docs/api/components/number-input.md), [`selector`](@/h3lp_yours3lf/docs/api/components/selector.md), [`textInput`](@/h3lp_yours3lf/docs/api/components/text-input.md) |
| `tabbedWindow` | [`window`](@/h3lp_yours3lf/docs/api/components/window.md), [`tabs`](@/h3lp_yours3lf/docs/api/components/tabs.md), [`column`](@/h3lp_yours3lf/docs/api/components/column.md) |

From the caller's perspective they work the same way:

```lua
local ui = I.H3UI

local title = ui.text 'Inventory'

local actions = ui.row {
    gap = 6,
    ui.button { label = 'Equip', onActivate = equip },
    ui.button { label = 'Drop', tone = 'negative', onActivate = drop },
}

local settings = ui.settings {
    fields = {
        {
            label = 'Enabled',
            kind = 'toggle',
            value = enabled,
            onChange = setEnabled,
        },
    },
}
```

`text` accepts a string or number shorthand. `row` and `column` accept children directly in the array part of their option table and may insert spacing with `gap`. `spacer(width, height)` is available when fixed spacing is clearer than an options table.

Component options are flat. H3UI metadata such as `role`, `variant`, `tone`, `class`/`classes`, `style`, and `invalidate` sits beside ordinary component options:

```lua
ui.button {
    role = 'destructiveAction',
    tone = 'negative',
    label = 'Delete',
    onActivate = delete,
}
```

## Semantic callbacks

Normal controls expose callbacks for their ordinary interaction instead of requiring raw OpenMW event plumbing. Examples include:

```lua
ui.button {
    label = 'Apply',
    onActivate = apply,
}

ui.textInput {
    text = filter,
    onChange = setFilter,
}

ui.toggle {
    value = enabled,
    onChange = setEnabled,
}

ui.selector {
    items = modes,
    selected = selectedMode,
    onSelect = selectMode,
}
```

Raw `events` remain available for behavior outside a component's semantic contract.

## Scopes

Use a scope when a mounted surface needs an invalidation callback or local recipes:

```lua
local ui = I.H3UI.scope {
    invalidate = function()
        if element and element.layout then element:update() end
    end,
}
```

Appearance is shared and player-configured; a scope does not create a private theme.

A scope may also define local recipes:

```lua
local ui = I.H3UI.scope {
    recipes = {
        characterCard = function(ui, spec)
            return ui.column {
                role = 'root',
                gap = 4,
                ui.text { role = 'name', text = spec.name },
                ui.text { role = 'level', text = 'Level ' .. tostring(spec.level) },
            }
        end,
    },
}

local card = ui.characterCard {
    name = 'Jiub',
    level = 1,
}
```

Local recipes become named constructors on that scope automatically. Recipe callbacks receive the same constructor vocabulary for public components and recipes, while preserving recipe identity for theme selectors. `ui.component(name, ...)` and `ui.recipe(name, ...)` remain available when a name is genuinely dynamic.

A scope also provides `ui.setChildren(layout, children)` for replacing the content of an already-mounted layout:

```lua
local function refilter()
    ui.setChildren(spellBox, { buildListBody() })
end
```

The layout keeps its identity; child layouts are rebuilt by the caller. Removed layouts leave the rendered subtree on update; explicitly supplied Elements remain caller-owned. Safe to call from event handlers, including handlers on widgets outside the replaced subtree. Call it once per structural change rather than once per mutated property.

## Advanced dynamic construction

String-based construction exists for code that genuinely chooses a component or recipe dynamically:

```lua
local control = ui.component(componentName, options)
local surface = ui.recipe(recipeName, options)
```

Do not use `component` or `recipe` merely to spell a known constructor. `ui.button { ... }` and `ui.settings { ... }` are shorter, easier for LuaLS to discover, and are the documented application path.

## Built-in recipes

### `dialog`

Builds framed dialog content with optional `title`, `body`, `content`/`children`, normal frame options, and H3UI traits. It owns structure only; mounting and dialog state remain yours.

```lua
ui.dialog {
    title = 'Import complete',
    body = 'Imported 47 records.',
}
```

### `confirmDialog`

Builds a framed dialog plus an action row. Each action may supply normal button options including `role`, `label`, `tone`, `classes`, `style`, and `onActivate`.

If `actions` is omitted while `onConfirm` or `onCancel` is provided, H3UI generates conventional Cancel and Confirm actions:

```lua
ui.confirmDialog {
    title = 'Delete save?',
    body = 'There is no undo.',
    confirmLabel = 'Delete',
    confirmTone = 'negative',
    onCancel = close,
    onConfirm = deleteSave,
}
```

### `settings`

Builds labelled fields from existing H3 controls. `fields` use the canonical control kinds `toggle`, `slider`, `numberInput`, `selector`, and `textInput`. Application state remains caller-owned.

```lua
ui.settings {
    title = 'General',
    fieldGap = 12,
    fields = {
        {
            label = 'Enabled',
            kind = 'toggle',
            value = enabled,
            onChange = setEnabled,
        },
        {
            label = 'Mode',
            kind = 'selector',
            items = modes,
            selected = selectedMode,
            onSelect = selectMode,
        },
    },
}
```

### `itemGrid`

Builds `grid` + `itemSlot` composition. Item descriptors are presentation data only; the recipe does not query or own inventory.

### `searchableList`

Builds `searchInput` + `list` + `listItem` and filters items during construction. Pass `query`, `items`, and optionally a `text(item, index)` extractor; update query state in `onQueryChange`, then rebuild the caller-owned surface.

### `section`

Builds a semantic section with optional `header`, `title`, and right-aligned `secondary`, followed by a `divider` and `body`. Sections stretch across the available cross-axis by default so callers do not need to hand-wire Flex geometry for ordinary full-width rows. Supply body layouts through `content`, `children`, or the array part of the options table. The stable roles are `root`, `header`, `title`, `secondary`, `divider`, and `body`.

### `tabbedWindow`

Builds a window, tab strip, and only the selected page from each tab descriptor. Selection is controlled by `selected`; `onSelect` owns the state change and should rebuild the caller-owned surface.

```lua
ui.tabbedWindow {
    title = 'Preferences',
    selected = 1,
    tabs = {
        { label = 'General', content = generalPage },
        { label = 'Advanced', content = advancedPage },
    },
    onSelect = function(index, label)
        selectedPage = index
    end,
}
```

## Built-in tones

Built-in themes give semantic meaning to the normal text-bearing controls for these tones:

```text
accent  positive  negative  muted  link
```

Use a tone to describe meaning, not a literal color:

```lua
ui.button {
    label = 'Delete',
    tone = 'negative',
}
```

Themes may extend tone behavior through selectors.

## Appearance and registered themes

H3UI uses the appearance selected in the player's settings. Scripts describe UI structure and meaning; they do not select the active palette.

```lua
local H3UI = require('openmw.interfaces').H3UI
local util = require 'openmw.util'

H3UI.registerTheme {
    id = 'myMod:danger',
    name = 'Danger',
    description = 'A red-accented appearance.',
    author = 'My Mod',
    tokens = {
        color = {
            danger = util.color.rgb(1, 0.25, 0.2),
        },
    },
    rules = {
        {
            selector = {
                component = 'button',
                tone = 'negative',
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

The built-in presets are `Morrowind`, `Starwind`, and `Custom`. Selecting a preset copies its palette into the player settings. Editing a color changes the selection to `Custom`; resetting restores the canonical Morrowind palette. The default is Morrowind, unless built-in Starwind content-file detection supplies another default.

The settings group uses the player section `SettingsPlayerH3UI`; its saved Custom palette lives separately in `SettingsPlayerH3UICustom`. The visible `theme` value is a registered theme ID or `custom`, and its color values are six-digit hexadecimal strings. Custom starts with the canonical Morrowind palette, keeps edits while presets are cycled, and is not reset when the visible settings group is reset. `chromeBorder` is the user-facing color for tintable H3UI chrome, while built-in themes provide their matching default through the same palette token. `menuTransparency` controls H3UI window backgrounds from transparent (`0.0`) to opaque (`1.0`) and defaults to `0.84`, matching OpenMW's default GUI setting. `chromeTransparency` independently controls the opacity of borders and frames and defaults to `1.0`. `textSizeNormal` defaults to `16`, matching OpenMW's default `font size`; `textSizeHeader` defaults to H3's `18`-pixel header size. Both can be configured independently in the H3UI settings page. The `enableDebugHotkeys` setting is disabled by default; enabling it allows F7 to cycle component demos and Shift+F7 to reload Lua.

H3UI frame components use a chrome source independent of the palette. `Theme default` honors the active theme's recommendation, `Theme textures` forces its declared texture paths, and `H3UI customizable` uses H3's namespaced grayscale textures and the configurable `Chrome border color`, with the grain picked through material family and material settings. A theme may declare arbitrary VFS paths under `chrome`; its frame resources are not tied to OpenMW template names. Themes may omit chrome and H3UI then falls back to its built-in resources. See the [H3UI chrome materials](@/h3lp_yours3lf/source/index.md) library for every shipped grain and its credits.

Theme IDs must be stable and unique. Namespaced IDs such as `myMod:theme` are recommended. A registered theme may use `extends` with another registered theme ID; otherwise it extends the built-in Morrowind rules internally. Token references are resolved against the final derived token set.

Unknown token paths, token cycles, unknown selector fields, unknown component names, and invalid style slots are errors rather than silent no-ops.

## Selectors

Selectors are explicit Lua data intended primarily for theme and recipe authors:

```lua
selector = {
    component = 'button',
    recipe = 'confirmDialog',
    role = 'confirm',
    selected = true,
    variant = 'primary',
    tone = 'negative',
    class = 'important',
    state = 'hover',
    slot = 'label',
}
```

All supplied fields must match. `class` tests membership in the node's class set. `selected` is a semantic boolean exposed by selectable components such as `listItem`, `itemSlot`, and `iconButton`; it is separate from index-valued component options such as `selector.selected` and `tabs.selected`. `slot` chooses a component style target and does not itself increase specificity.

H3 intentionally does not parse CSS selector strings and does not implement descendant, sibling, `nth-child`, or arbitrary tree selectors. Recipes expose `role` values so themes can target a component's job instead of incidental child positions.

`state` is theme-owned. Runtime state currently means generated `hover` and `pressed` interaction state; application code does not set arbitrary instance state.

## Cascade

Matched rules apply from lower to higher precedence:

1. generic/component rules;
2. recipe/role rules;
3. `variant`, `tone`, or semantic `selected` rules;
4. class rules;
5. runtime state rules.

Inside one tier, a rule with more selector constraints wins; exact ties use later source order. Flat component options override theme-provided values, and explicit instance `style` is applied last.

A primitive's own defaults remain below the H3UI style cascade because the component builder receives resolved options and fills anything still absent.

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

Generated subparts expose narrower slots when the component has a stable public option for them:

| Component | Extra slots |
| --- | --- |
| `bookFrame` | `title`, `background` |
| `button` | `label` |
| `iconButton` | `icon`, `label` |
| `itemSlot` | `icon`, `count` |
| `listItem` | `label`, `secondary` |
| `meter`, `slider` | `fill`, `empty` |
| `toggle` | `label` |
| `tooltip` | `text` |
| `window` | `background`, `caption`, `captionText` |
| `grid` | `row` |
| `tabs` | `button`, `selected`, `label`, `selectedLabel` |
| `selector` | `button`, `icon`, `label` |
| `searchInput` | `input` |

Use `H3UI.slots('button')` to inspect the registered slot names for a component.

Generated-child slots do not grant permission to traverse caller-owned custom content. If custom `content`/`children` replaces a generated label or text child, the corresponding slot may have no rendered target; H3 does not mutate the replacement tree on the theme's behalf.

## Inline style and `H3UI.UNSET`

Inline styles can address multiple slots and always apply after theme rules and ordinary component arguments:

```lua
ui.button {
    label = 'Wide',
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

## Nine-slice frames

`H3UI.nineSlice` is an advanced framing primitive for theme and component work. It builds a resizable frame from one atlas region while returning ordinary OpenMW image layouts. `source` describes the complete source region and border thickness; `inset` places content inside a fixed inset from the frame edges.

```lua
local frame = H3UI.nineSlice {
    source = {
        path = 'textures/h3ui/h3ui_chrome.dds',
        offset = util.vector2(0, 0),
        size = util.vector2(516, 516),
        thickness = 2,
    },
    props = {
        size = util.vector2(320, 160),
    },
    inset = 2,
    content = require('openmw.ui').content {},
}
```

## Diagnostics

`H3UI.explain(spec)` accepts a diagnostic spec containing `component` or `recipe` and returns the resolved layout plus selector traces:

```lua
local explanation = H3UI.explain {
    component = 'button',
    tone = 'negative',
    label = 'Delete',
}
```

Each traced node records its component, recipe, role, matched rules, resolved theme style, and inline style. Use it when a theme rule does not appear to win the way you expect.
