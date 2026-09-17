---
title: UI Components
description: Option contracts for H3UI's application-facing constructors and internal building blocks.
template: docs/section.html
page_template: docs/page.html
sort_by: title
weight: 1
extra:
  kind: api
  sidebar_groups:
    - title: Layout and spacing
      pages: [row, column, spacer, divider]
    - title: Text and images
      pages: [text, image]
    - title: Lists and repeated content
      pages: [list, list-item, grid]
    - title: Frames and surfaces
      pages: [box, book-frame, tooltip, window]
    - title: Actions and indicators
      pages: [button, icon-button, meter, item-slot]
    - title: State and input
      pages: [toggle, slider, selector, number-input, search-input, text-input]
    - title: Tabbed or expandable content
      pages: [tabs, collapsible]
    - title: Advanced internals
      pages: [widget, container, head-block, caption, pin-button]
aliases:
  - /h3lp_yours3lf/docs/api/ui-components/
---

H3 components are passive layout builders. Application code normally reaches them through the [H3UI facade](@/h3lp_yours3lf/docs/api/interfaces/h3ui.md):

```lua
local I = require 'openmw.interfaces'
local ui = I.H3UI.scope { invalidate = refresh }

local layout = ui.column {
    gap = 8,
    ui.text 'Hello from H3',
    ui.button {
        label = 'Continue',
        onActivate = continue,
    },
}
```

The pages in this section document the option contracts behind those constructors. You should not need one `require` per component in ordinary mod code.

H3UI returns normal OpenMW layouts; it does not create elements, choose layers, retain application state, or own a rendered surface. Start with [UI Layouts and Lifecycle](@/h3lp_yours3lf/docs/concepts/ui-components.md), then use the [application recipes](@/h3lp_yours3lf/docs/examples/ui-recipes.md) for complete copyable surfaces.

## Choose by job

| Need | Constructors |
| --- | --- |
| Layout and spacing | [row](@/h3lp_yours3lf/docs/api/components/row.md), [column](@/h3lp_yours3lf/docs/api/components/column.md), [spacer](@/h3lp_yours3lf/docs/api/components/spacer.md), [divider](@/h3lp_yours3lf/docs/api/components/divider.md) |
| Text and images | [text](@/h3lp_yours3lf/docs/api/components/text.md), [image](@/h3lp_yours3lf/docs/api/components/image.md) |
| Lists and repeated content | [list](@/h3lp_yours3lf/docs/api/components/list.md), [listItem](@/h3lp_yours3lf/docs/api/components/list-item.md), [grid](@/h3lp_yours3lf/docs/api/components/grid.md) |
| Frames and surfaces | [box](@/h3lp_yours3lf/docs/api/components/box.md), [bookFrame](@/h3lp_yours3lf/docs/api/components/book-frame.md), [tooltip](@/h3lp_yours3lf/docs/api/components/tooltip.md), [window](@/h3lp_yours3lf/docs/api/components/window.md) |
| Actions and indicators | [button](@/h3lp_yours3lf/docs/api/components/button.md), [iconButton](@/h3lp_yours3lf/docs/api/components/icon-button.md), [meter](@/h3lp_yours3lf/docs/api/components/meter.md), [itemSlot](@/h3lp_yours3lf/docs/api/components/item-slot.md) |
| State and input | [toggle](@/h3lp_yours3lf/docs/api/components/toggle.md), [slider](@/h3lp_yours3lf/docs/api/components/slider.md), [selector](@/h3lp_yours3lf/docs/api/components/selector.md), [numberInput](@/h3lp_yours3lf/docs/api/components/number-input.md), [searchInput](@/h3lp_yours3lf/docs/api/components/search-input.md), [textInput](@/h3lp_yours3lf/docs/api/components/text-input.md) |
| Tabbed or expandable content | [tabs](@/h3lp_yours3lf/docs/api/components/tabs.md), [collapsible](@/h3lp_yours3lf/docs/api/components/collapsible.md) |

`widget`, `container`, `headBlock`, `caption`, and `pinButton` remain documented because H3 itself and advanced component authors use them. They are not part of the normal application constructor surface.

## Shared layout options

Most constructors accept these layout fields:

| Field | Type | Description |
| --- | --- | --- |
| `name` | string? | Name a child for lookup from its owning `Content`. |
| `props` | table? | Set layout properties such as `size`, `position`, or `visible`. |
| `external` | table? | Set parent-facing properties such as `grow` or `stretch`. |
| `events` | table? | Supply low-level OpenMW callbacks when no semantic callback fits. |
| `userData` | any? | Attach caller-owned data to a layout. |
| `template` | openmw.ui.Template? | Override the default template where supported. |
| `content` | openmw.ui.Content? | Provide child content where supported. |
| `children` | openmw.ui.LayoutOrElement[]? | Provide child layouts where supported. |

`row` and `column` also accept children directly in the array part of the options table:

```lua
ui.row {
    gap = 6,
    ui.text 'Name',
    ui.textInput { text = name, onChange = setName },
}
```

The builders shallow-copy `props` and `external`. They do not deeply copy child layouts, textures, or caller state.

## Mount a component

```lua
local I = require 'openmw.interfaces'
local openmwUi = require 'openmw.ui'
local util = require 'openmw.util'

local layout = I.H3UI.column {
    gap = 4,
    I.H3UI.text 'Hello from H3',
}

local element = openmwUi.create {
    type = openmwUi.TYPE.Container,
    layer = 'Windows',
    props = {
        position = util.vector2(80, 80),
    },
    content = openmwUi.content { layout },
}
```

Keep `element` when a callback changes layout state, then call `element:update()`. Rebuild the caller-owned root for structural changes.

The bundled component tests now separate small diagnostic probes from application-grade reference fixtures. The Magic menu, inventory panel, and mod configuration surfaces are intended to be useful examples as well as integration tests.
