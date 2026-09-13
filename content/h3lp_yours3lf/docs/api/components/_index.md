---
title: UI Components
description: H3 UI component contracts and copyable examples.
template: docs/section.html
page_template: docs/page.html
sort_by: title
weight: 1
extra:
  kind: api
  sidebar_groups:
    - title: Basic layout shape
      pages: [widget, container, row, column]
    - title: Text, images, and spacing
      pages: [text, image, spacer]
    - title: Lists and repeated content
      pages: [list, list-item, grid]
    - title: Framed content
      pages: [box, book-frame, dialog, tooltip]
    - title: Actions and indicators
      pages: [button, icon-button, meter, item-slot]
    - title: State and input
      pages: [toggle, slider, selector, number-input, search-input, text-input]
    - title: Tabbed or expandable content
      pages: [tabs, collapsible]
    - title: Morrowind window chrome
      pages: [head-block, caption, pin-button, window]
aliases:
  - /h3lp_yours3lf/docs/api/ui-components/
---

H3 components are passive layout builders for registered `menu` and `player` scripts. Each call returns an OpenMW layout; it does not create an element or own your state. Start with [UI Layouts and Lifecycle](@/h3lp_yours3lf/docs/concepts/ui-components.md), or jump to a [UI recipe](@/h3lp_yours3lf/docs/examples/ui-recipes.md) for a complete surface.

A content-only root uses `ui.TYPE.Container` so it sizes itself to its children. The default `ui.TYPE.Widget` is also valid, but needs explicit geometry.

## Choose by job

| Need | Components |
| --- | --- |
| Basic layout shape | [widget](@/h3lp_yours3lf/docs/api/components/widget.md), [container](@/h3lp_yours3lf/docs/api/components/container.md), [row](@/h3lp_yours3lf/docs/api/components/row.md), [column](@/h3lp_yours3lf/docs/api/components/column.md) |
| Text, images, and spacing | [text](@/h3lp_yours3lf/docs/api/components/text.md), [image](@/h3lp_yours3lf/docs/api/components/image.md), [spacer](@/h3lp_yours3lf/docs/api/components/spacer.md) |
| Lists and repeated content | [list](@/h3lp_yours3lf/docs/api/components/list.md), [listItem](@/h3lp_yours3lf/docs/api/components/list-item.md), [grid](@/h3lp_yours3lf/docs/api/components/grid.md) |
| Framed content | [box](@/h3lp_yours3lf/docs/api/components/box.md), [bookFrame](@/h3lp_yours3lf/docs/api/components/book-frame.md), [dialog](@/h3lp_yours3lf/docs/api/components/dialog.md), [tooltip](@/h3lp_yours3lf/docs/api/components/tooltip.md) |
| Actions and indicators | [button](@/h3lp_yours3lf/docs/api/components/button.md), [iconButton](@/h3lp_yours3lf/docs/api/components/icon-button.md), [meter](@/h3lp_yours3lf/docs/api/components/meter.md), [itemSlot](@/h3lp_yours3lf/docs/api/components/item-slot.md) |
| State and input | [toggle](@/h3lp_yours3lf/docs/api/components/toggle.md), [slider](@/h3lp_yours3lf/docs/api/components/slider.md), [selector](@/h3lp_yours3lf/docs/api/components/selector.md), [numberInput](@/h3lp_yours3lf/docs/api/components/number-input.md), [searchInput](@/h3lp_yours3lf/docs/api/components/search-input.md), [textInput](@/h3lp_yours3lf/docs/api/components/text-input.md) |
| Tabbed or expandable content | [tabs](@/h3lp_yours3lf/docs/api/components/tabs.md), [collapsible](@/h3lp_yours3lf/docs/api/components/collapsible.md) |
| Morrowind window chrome | [headBlock](@/h3lp_yours3lf/docs/api/components/head-block.md), [caption](@/h3lp_yours3lf/docs/api/components/caption.md), [pinButton](@/h3lp_yours3lf/docs/api/components/pin-button.md), [window](@/h3lp_yours3lf/docs/api/components/window.md) |

## Shared layout options

Most builders accept these layout fields:

| Field | Type | Description |
| --- | --- | --- |
| `name` | string? | Name a child for lookup from its owning `Content`. |
| `props` | table? | Set layout properties such as `size`, `position`, or `visible`. |
| `external` | table? | Set parent-facing properties such as `grow` or `stretch`. |
| `events` | table? | Supply low-level OpenMW callbacks. Wrap them with `async:callback`. |
| `userData` | any? | Attach caller-owned data to a layout. |
| `template` | openmw.ui.Template? | Override the default template where supported. |
| `content` | openmw.ui.Content? | Provide child content; takes precedence over `children`. |
| `children` | openmw.ui.LayoutOrElement[]? | Provide child layouts when `content` is absent. |

The builders shallow-copy `props` and `external`. They do not copy child layouts, textures, or caller state deeply.

## Mount a component

```lua
local ui = require 'openmw.ui'
local column = require 'scripts.s3.components.column'
local text = require 'scripts.s3.components.text'
local util = require 'openmw.util'

ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  props = {
    position = util.vector2(80, 80),
  },
  content = ui.content {
    column {
      children = {
        text {
          text = 'Hello from H3',
        },
      },
    },
  },
}
```

Keep `element` when a callback changes layout state, then call `element:update()`. Rebuild the root for structural changes. The [component tests](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/tree/main/content/h3lp_yours3lf/scripts/s3/components/componentTests) provide larger executable constructions.
