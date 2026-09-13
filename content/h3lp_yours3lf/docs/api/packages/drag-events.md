---
title: DragEvents
description: Add direct drag and resize behavior to menu and player UI layouts.
weight: 84
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.dragEvents' → DragEvents") }}

`DragEvents` installs mouse-drag and edge/Shift-resize behavior on an existing OpenMW layout table. It mutates the layout's `props` and `events`; it does not create an `Element`, choose a layer, or update a live element for you.

{% usage_note(title="Menu and player · Runtime UI helper") %}
This module is intended for `menu` and `player` scripts. Install it before calling `ui.create(layout)`. Keep the created element and call `element:update()` from callbacks after the layout properties change. The module wraps its installed event handlers with `async:callback`; the callbacks in the options table should be ordinary Lua functions.
{% end %}

## Minimal draggable layout

`onDrag` is required. The callback receives the layout and its new relative position after `props.relativePosition` has been changed.

```lua
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local dragEvents = require 'scripts.s3.dragEvents'

local layout = {
  props = {
    anchor = util.vector2(0, 0),
    relativePosition = util.vector2(0.1, 0.1),
    size = util.vector2(320, 120),
  },
}

local element

dragEvents.install(layout, {
  onDrag = function(changedLayout, newPosition)
    print('Moved to', newPosition.x, newPosition.y)
    element:update()
  end,
})

element = ui.create(
  layout
)
```

The callback is responsible for applying the mutation to the rendered element. Changing `layout.props` without calling `element:update()` does not update an already-created element.

## Drag and resize together

Provide `onResize` to enable resizing. A primary-button press near an edge starts resizing. By default, holding Shift starts resizing from anywhere inside the layout.

```lua
local dragEvents = require 'scripts.s3.dragEvents'

dragEvents.install(layout, {
  onDrag = function(changedLayout, newPosition)
    element:update()
  end,
  onDragStart = function(changedLayout)
    print('Interaction started')
  end,
  onDragEnd = function(changedLayout)
    print('Interaction finished')
  end,
  onResizeStart = function(changedLayout, newAnchor, newPosition)
    element:update()
  end,
  onResize = function(changedLayout, newSize)
    element:update()
  end,
  onResizeEnd = function(changedLayout)
    print('Resize finished')
  end,
})
```

At resize start, the helper converts the effective size to `props.relativeSize` and clears `props.size`. The effective size includes both contributions when a layout has `size` and `relativeSize`. The anchor and position are adjusted so the opposite corner remains fixed. Every later mouse move changes `relativeSize`; `onResize` runs after that change.

If an application needs a resize policy other than free two-dimensional resizing, provide `resolveResize`. It receives the proposed relative size, the absolute mouse delta since resize began, the starting relative size, and the reference size. Return a replacement size to clamp and commit it, or return nothing to accept the proposed size.

```lua
dragEvents.install(layout, {
  onDrag = function()
    element:update()
  end,
  onResize = function()
    element:update()
  end,
  resolveResize = function(_, proposedSize)
    local width = math.max(0.15, proposedSize.x)
    return require('openmw.util').vector2(width, width)
  end,
})
```

The `resolveResize` result is still subject to `clampToScreen`. This hook is the intended place to preserve application-specific rules such as a square indicator, a fixed aspect ratio, or a one-axis resize.

## Mouse-move cost

The normal `mouseMove` paths keep their calculations scalar. Reference dimensions and their reciprocals are cached when an interaction begins, and the drag/resize calculations use numeric X/Y values until they need to write `relativePosition` or `relativeSize` and invoke the public callback. There is no intermediate delta vector, relative-delta vector, or vector-based clamp result in the ordinary path. Supplying `resolveResize` intentionally crosses the public Vector2 boundary: custom-resize consumers pay for the proposed-size and absolute-delta vectors; ordinary resizing does not.

## Options

| Option | Default | Behavior |
| --- | --- | --- |
| `onDrag` | required | Called after `relativePosition` changes. The callback must update the live element if it is already mounted. |
| `onDragStart` | omitted | Called when a primary-button drag begins. |
| `onDragEnd` | omitted | Called when dragging ends through primary-button release or focus loss. |
| `onResize` | omitted | Enables resizing and is called after `relativeSize` changes. |
| `onResizeStart` | omitted | Called after resize-start geometry normalization. |
| `onResizeEnd` | omitted | Called when resizing ends through primary-button release or focus loss. |
| `resolveResize` | omitted | Replaces the proposed size before clamping and commit. |
| `edgeThreshold` | `0.025` | Edge width as a fraction of the effective layout size. |
| `shiftToResize` | `true` | Allows Shift to start resizing away from an edge. |
| `clampToScreen` | `true` | Keeps effective bounds inside the configured reference coordinate space. |
| `referenceSize` | layer size, then `ui.screenSize()` | A `Vector2` or function returning the coordinate-space size used for relative geometry. |
| `userData` | omitted | Shallowly merged into `layout.userData`. The reserved `__h3DragEvents` key cannot be supplied. |
| `section` | omitted | A mutable storage section loaded during installation and reused by `save` when no section is passed. |

`anchor` and `relativePosition` default to `(0, 0)` when `install` initializes a layout. Resizing requires `props.size` or `props.relativeSize`; drag-only layouts may omit size and are clamped by relative position when `clampToScreen` is enabled.

Automatic reference-size inference is a root-layout convenience: it uses the assigned layer size and then `ui.screenSize()`. For a child layout, pass the parent coordinate-space size through `referenceSize`; relative geometry is defined against the parent, not the screen.

## Existing event handlers

Installation composes the module's handlers with any `mousePress`, `mouseMove`, `mouseRelease`, or `focusLoss` handler already present on the layout. The existing handler runs first. If it returns a non-`nil` value, that value is preserved; otherwise the drag handler's result is returned.

The interaction handlers return `true` when they handle a primary-button interaction. That return value is part of OpenMW's event-propagation contract. Do not remove it or replace the callbacks with `async:callback` wrappers of your own.

Installation is idempotent for the same layout. Reinstalling replaces the H3 callback and configuration state without adding another layer of event wrappers. The module-owned state is stored under `layout.userData.__h3DragEvents`; do not overwrite that entry.

## Persistence

Persistence is explicit and cold-path only. `install` optionally calls `load` once. `save` writes the generic keys `relativePosition`, `relativeSize`, and `anchor`; it does not run during mouse movement.

Use a separate section or key namespace for each independently persisted layout. In a player or menu script, a player section is mutable. A global section is read-only in those contexts and is available to menu scripts only while a game is running.

```lua
local storage = require 'openmw.storage'
local dragEvents = require 'scripts.s3.dragEvents'

local section = storage.playerSection('MyModLayout')

dragEvents.install(layout, {
  section = section,
  onDrag = function()
    element:update()
  end,
})

-- Call this from the owning save lifecycle callback.
dragEvents.save(layout, section)
```

`load(layout, section)` can be called directly when the caller controls when a valid section is available. `save(layout)` uses the section passed to `install`; `save(layout, section)` overrides it. Neither function updates a mounted element, so call `element:update()` after a direct `load` when necessary.

## Intended H4ND integration

This helper exists in part to give H4ND a cleaner future migration path: mouse movement can mutate live layout properties directly, while persistence happens once at the end of an interaction or during the owning save callback. That removes storage writes, storage subscriptions, and UI rebuild work from the mouse-move path. H4ND has **not** been migrated to this module yet; its current drag implementation remains separate.

The migration will not be mechanical. H4ND elements use different resize policies: some preserve a square shape, some resize on one axis, and some use fixed pixel dimensions. Future integration should use `resolveResize` and H4ND-owned persistence rather than assuming one generic layout policy. The module provides the interaction primitive; H4ND remains responsible for choosing layouts, resolving policy, updating live elements, and migrating existing settings.
