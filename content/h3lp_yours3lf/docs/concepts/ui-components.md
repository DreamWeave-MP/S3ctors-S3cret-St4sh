---
title: UI Components and Layouts
description: Compose passive OpenMW UI layouts without hiding ownership or lifecycle.
weight: 25
extra:
  kind: concept
---

H3's UI components are layout builders and controlled interaction compositions, not retained widgets. A component returns an `openmw.ui.Layout` table; interactive handlers mutate that layout before notifying the caller, but the caller remains responsible for updating the mounted root `Element`.

{% usage_note(title="Menu and player layouts · Caller owns the element") %}
The component modules are available in `menu` and `player` scripts. The caller owns the root element, its layer, its rebuild/destroy path, and any durable state used to produce a new layout. Low-level event callbacks are preserved and composed where a component owns the same event; controlled component callbacks are adapted by H3 and receive semantic values after the component has updated its layout state. Any interactive component that mutates layout state needs an owner update path: have its state callback or low-level event callback call the mounted root `Element:update()`, or the rendered UI can remain stale even though the layout table changed.
{% end %}

## Build, mount, update

Build the complete layout tree first, then mount the root deliberately:

```lua
local ui = require 'openmw.ui'
local column = require 'scripts.s3.components.column'
local text = require 'scripts.s3.components.text'

local layout = {
    layer = 'Windows',
    props = { size = require('openmw.util').vector2(360, 120) },
    content = ui.content({
        column {
            name = 'body',
            children = {
                text { name = 'title', text = 'H3 UI' },
            },
        },
    }),
}

local element = ui.create(layout)
```

Keep the live `element` when later mutation is needed. Updating the old construction table does not update the engine; mutate the live element or its live layout and call `element:update()`. Structural changes belong to the owner of the root, not to a distant child that happens to have a reference to it.

## Shared options

Most builders share these options; specialized builders expose their own inputs:

| Field | Behavior |
| --- | --- |
| `name` | Name used for lookup from the owning `Content`. Keep names unique within that owner. |
| `props` | Shallow-copied layout properties. Component-specific convenience values are applied afterward. |
| `external` | Shallow-copied external layout properties, such as `grow` or `stretch`. |
| `events` | Event table passed to the returned layout. Callbacks are not automatically async-wrapped. |
| `userData` | Caller-owned data attached to the layout using the camel-cased `userData` field. |
| `template` | Optional template override when the component supports one. |
| `content` / `children` | Common on container-like builders for child layouts or an existing `openmw.ui.Content`; `content` takes precedence. |

Components copy the outer `props` and `external` tables, but they do not deep-copy values, child layouts, textures, or caller-owned state. Construction allocates layout tables and usually one or more `Content` wrappers. Do not treat a returned layout as a pooled or save-safe object.

## Component families

- **Primitives:** `widget`, `container`, `box`, `text`, and `image` map directly to basic OpenMW layout shapes or shared MWUI templates.
- **Flow:** `row` and `column` are horizontal and vertical Flex layouts; `list` is a vertical Flex layout; `grid` builds a vertical Flex of horizontal rows.
- **Spacing and framing:** `spacer`, `bookFrame`, and `dialog` add geometry or presentation without creating a window or layer.
- **Actions and state display:** `button`, `iconButton`, `meter`, and `itemSlot` compose common controls and indicators.
- **Controls:** `toggle`, `slider`, `select`, `tabs`, `collapsible`, `numberInput`, and `searchInput` report changes while the caller owns their state.
- **Input and explanation:** `textInput` builds a TextEdit line; `tooltip` builds a boxed content layout but does not position or show it.
- **Morrowind chrome:** `headBlock`, `caption`, `pinButton`, and `window` compose caller-owned framed surfaces without using `ui.TYPE.Window`.

For the exact options and defaults, see the [UI Components reference](@/h3lp_yours3lf/docs/api/ui-components.md).
