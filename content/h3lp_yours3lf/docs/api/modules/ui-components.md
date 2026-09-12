---
title: UI Components
description: Build composable passive OpenMW layouts for menu and player scripts.
weight: 80
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.components.*' → layout builder") }}

These modules return layout tables. They do not create or destroy `openmw.ui.Element` objects, choose a layer, persist state, or update a mounted tree. Read [UI Components and Layouts](@/h3lp_yours3lf/docs/concepts/ui-components.md) before choosing a component.

{% usage_note(title="Menu and player only · Passive builders") %}
All components in this page are annotated for `menu|player`. Event callbacks are passed through unchanged; wrap them with `async:callback` before handing them to OpenMW UI events.
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

`button`, `iconButton`, `bookFrame`, `dialog`, and `itemSlot` use shared MWUI templates by default and allow caller overrides. `iconButton` and `itemSlot` accept prebuilt texture resources; neither registers or owns textures. `meter` creates fill and empty child widgets and does not update itself after construction.

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
