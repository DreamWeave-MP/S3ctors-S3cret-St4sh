---
title: UI Components
description: Build composable passive OpenMW layouts for menu and player scripts.
weight: 80
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.components.*' → layout builder") }}

These modules return layout tables. They do not create or destroy mounted UI elements, choose a layer, persist state, or update a mounted tree. Interactive components mutate their returned layout state before notifying the caller; the caller owns the root `Element` and should call `Element:update()` from its callback. Read [UI Components and Layouts](@/h3lp_yours3lf/docs/concepts/ui-components.md) before choosing a component.

{% usage_note(title="Menu and player only · Layout builders") %}
All components in this page are annotated for `menu|player`. Low-level `events` callbacks are preserved and composed where a component owns the same event; wrap them with `async:callback` before handing them to OpenMW UI events. Controlled callbacks such as `onChange`, `onCommit`, `onSelect`, `onToggle`, `onMove`, and `onResize` are adapted by the component.
{% end %}

## Shared options

Most builders share `name`, `props`, `external`, `events`, `userData`, and `template`. Container-like builders also commonly accept `content` or `children`; specialized builders expose their own inputs. The outer `props` and `external` tables are shallow-copied, and when both child fields are present, `content` wins.

## Primitives

| Builder | Signature | Behavior |
| --- | --- | --- |
| `widget` | `require 'scripts.s3.components.widget'(opts?) → Layout` | Build a passive `ui.TYPE.Widget`. |
| `container` | `require 'scripts.s3.components.container'(opts?) → Layout` | Build a passive `ui.TYPE.Container`. |
| `box` | `require 'scripts.s3.components.box'(opts?) → Layout` | Build an MWUI box, using `I.MWUI.templates.box` by default. |
| `text` | `require 'scripts.s3.components.text'(opts?) → Layout` | Build a `ui.TYPE.Text`; `opts.text` supplies `props.text`. |
| `image` | `require 'scripts.s3.components.image'(opts?) → Layout` | Build a `ui.TYPE.Image`; `opts.resource` supplies a prebuilt texture resource. |

```lua
local box = require 'scripts.s3.components.box'
local text = require 'scripts.s3.components.text'

local panel = box {
    name = 'panel',
    children = {
        text { name = 'heading', text = 'Settings' },
    },
}
```

`image` does not call `ui.texture`; callers provide a resource or put one in `props.resource`. Shared MWUI templates are read-only inputs to these builders.

## Flow and spacing

| Builder | Signature | Behavior |
| --- | --- | --- |
| `row` | `require 'scripts.s3.components.row'(opts?) → Layout` | Build a horizontal Flex; forces `props.horizontal = true`. |
| `column` | `require 'scripts.s3.components.column'(opts?) → Layout` | Build a vertical Flex; forces `props.horizontal = false`. |
| `list` | `require 'scripts.s3.components.list'(opts?) → Layout` | Build a vertical Flex from `opts.items` or child content. |
| `listItem` | `require 'scripts.s3.components.listItem'(opts?) → Layout` | Build a padded list-item row, with an optional text label. |
| `grid` | `require 'scripts.s3.components.grid'(opts?) → Layout` | Group `opts.items` into horizontal rows; `columns` defaults to `1` and values below `1` become `1`. |
| `spacer` | `require 'scripts.s3.components.spacer'(...) → Layout` | Build an empty widget from `spacer(size)`, `spacer(width, height)`, or options. |

`row` and `column` preserve caller properties except for their intentional orientation. `grid` creates row/content wrappers but passes each item layout through without copying it. `spacer` supports `grow` and `stretch` conveniences only when `external` is omitted; an explicit `external` table takes precedence.

## Framing and actions

| Builder | Signature | Behavior |
| --- | --- | --- |
| `bookFrame` | `require 'scripts.s3.components.bookFrame'(opts?) → Layout` | Build a solid MWUI framed body, with an optional header title. |
| `dialog` | `require 'scripts.s3.components.dialog'(opts?) → Layout` | Build a Window-style widget layout, with an optional header title. It does not create a window or set a layer. |
| `button` | `require 'scripts.s3.components.button'(opts?) → Layout` | Build an MWUI text button; `label` supplies the default text child. |
| `iconButton` | `require 'scripts.s3.components.iconButton'(opts?) → Layout` | Build an MWUI button with a required-by-use icon resource and optional label. |
| `meter` | `require 'scripts.s3.components.meter'(opts?) → Layout` | Build a horizontal fill/empty meter from `value` and `max`, clamped to a `0..1` ratio. |
| `itemSlot` | `require 'scripts.s3.components.itemSlot'(opts?) → Layout` | Build a bordered icon slot with an optional count label. It does not query game state. |

`button`, `iconButton`, `bookFrame`, `dialog`, and `itemSlot` use shared MWUI templates by default and allow caller overrides. `iconButton` and `itemSlot` accept prebuilt texture resources; neither registers or owns textures. `meter` creates fill and empty Image children and does not update itself after construction.

## Controls and window chrome

| Builder | Signature | Behavior |
| --- | --- | --- |
| `toggle` | `require 'scripts.s3.components.toggle'(options?) → Layout` | Build a state-labelled yes/no button; clicking updates its label before `onChange` receives the next boolean. |
| `slider` | `require 'scripts.s3.components.slider'(options?) → Layout` | Build a bounded meter whose fill updates during pointer interaction; supports `min`, `max`, and `step`. |
| `select` | `require 'scripts.s3.components.select'(options?) → Layout` | Build a previous/value/next selector whose displayed value follows the selected item. |
| `tabs` | `require 'scripts.s3.components.tabs'(options?) → Layout` | Build a tab strip with mutable selected visual state; it does not create or own page content. |
| `collapsible` | `require 'scripts.s3.components.collapsible'(options) → Layout` | Build a disclosure header and a body whose visibility follows the expanded state. |
| `numberInput` | `require 'scripts.s3.components.numberInput'(options?) → Layout` | Build a numeric TextEdit with raw editing text and commit-time clamping, optional integer rounding, and stepping. |
| `searchInput` | `require 'scripts.s3.components.searchInput'(options?) → Layout` | Build a TextEdit with a clear-button convention. OpenMW TextEdit has no placeholder property; provide placeholder-like copy separately. |
| `headBlock` | `require 'scripts.s3.components.headBlock'(options?) → Layout` | Build a scalable Morrowind title block from vanilla VFS textures. |
| `caption` | `require 'scripts.s3.components.caption'(options?) → Layout` | Build a centered Morrowind title strip with optional pin and close controls. |
| `pinButton` | `require 'scripts.s3.components.pinButton'(options?) → Layout` | Build the canonical up/down pin control. |
| `window` | `require 'scripts.s3.components.window'(options?) → Layout` | Build a caller-owned movable/resizable framed surface with optional title, pin, and close controls. |

`slider` defaults to a 200×18 fixed track because pointer-to-value conversion needs a known width. Set `trackWidth` when `props.relativeSize.x` is non-zero so pointer conversion uses the rendered track width. Its event handlers update the returned meter layout and call `onChange`; update the owning mounted element from that callback. `select`, `tabs`, `toggle`, and `collapsible` likewise update their layout state before notifying the caller. `numberInput` preserves raw text during editing, normalizes it on focus loss, calls `onChange` when the committed number changes, and calls `onCommit` after every commit; use either callback to update the owning mounted element. The caller still owns durable state and the mounted `Element`.

`window` does not use `ui.TYPE.Window`, persist geometry, or implement docking and focus management. Its default minimum size is 64×64, it uses the shared thick-border MWUI template, clamps movement and resizing to the assigned layer by default, and accepts a `referenceSize` vector or provider when nested in another coordinate space. The default resize hitbox is 4 pixels; override `resizeHandle` when a larger edge target is needed. `clampToScreen = false` permits a partially off-screen surface. A caption bar is created when a title, pin control, or close control is requested. Position and size are ordinary layout properties owned by the caller; call the owning mounted element's `update()` from `onMove` and `onResize` for continuous redraw during interaction. `onResize` receives `(size, position)` so callers can persist both values when resizing from the left or top.

`searchInput.events` belongs to the returned row. Pass editor-specific handlers through `searchInput.inputEvents`; its `textChanged` handler receives the raw TextEdit value.

`tabs.selectedProps` and `tabs.selectedLabelProps` are merged over `buttonProps` and `labelProps`; unspecified base properties are retained for selected tabs.

`numberInput` requires integral `min`, `max`, and `step` values when `integer = true`; this keeps its normalization rules compatible with the integer contract. `pinButton` is fixed at 19×19. A `caption` with pin or close controls requires at least 19 pixels of height, and custom controls must not be taller than the caption.

```lua
local slider = require 'scripts.s3.components.slider'
local toggle = require 'scripts.s3.components.toggle'

local settings = { enabled = true, volume = 0.5 }
local controls = {
    toggle {
        value = settings.enabled,
        onChange = function(value)
            settings.enabled = value
            refresh()
        end,
    },
    slider {
        value = settings.volume,
        min = 0,
        max = 1,
        step = 0.05,
        onChange = function(value)
            settings.volume = value
            refresh()
        end,
    },
}
```

## Input and explanation

| Builder | Signature | Behavior |
| --- | --- | --- |
| `textInput` | `require 'scripts.s3.components.textInput'(opts?) → Layout` | Build a `ui.TYPE.TextEdit`, using `I.MWUI.templates.textEditLine` by default. |
| `tooltip` | `require 'scripts.s3.components.tooltip'(opts?) → Layout` | Build a transparent boxed text layout. It does not position, show, hide, create, or destroy a tooltip. |

```lua
local async = require 'openmw.async'
local textInput = require 'scripts.s3.components.textInput'

local nameInput = textInput {
    name = 'name_input',
    text = 'Nerevarine',
    events = {
        textChanged = async:callback(function(value)
            print('Name:', value)
        end),
    },
}
```

The builders allocate fresh construction tables. Store the mounted element when later updates or destruction are needed; changing `nameInput.props` after `ui.create(nameInput)` is not a live update.
