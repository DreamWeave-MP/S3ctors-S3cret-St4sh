---
title: window
description: Build a caller-owned movable and resizable framed surface.
weight: 53
extra:
  kind: api
---

Builds a framed Widget with an optional caption and body. It is not `ui.TYPE.Window`: H3 does not create a window, persist geometry, dock, or manage focus. Position and size are ordinary layout properties owned by the caller.

## Example

```lua
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local H3UI = require('openmw.interfaces').H3UI

local position = util.vector2(80, 80)
local size = util.vector2(360, 220)
local pinned = false
local element

element = ui.create {
  type = ui.TYPE.Container,
  layer = 'Windows',
  content = ui.content {
    H3UI.window {
      title = 'My tool H3UI.window',
      position = position,
      size = size,
      pinnable = true,
      pinned = pinned,
      closable = true,
      onPin = function(value)
        pinned = value
        element:update()
      end,
      onClose = function()
        element:destroy()
      end,
      onMove = function(nextPosition)
        position = nextPosition
        element:update()
      end,
      onResize = function(nextSize, nextPosition)
        size = nextSize
        position = nextPosition
        element:update()
      end,
      children = {
        H3UI.text {
          text = 'Drag the caption or resize an edge.',
        },
      },
    },
  },
}
```

## Parameters

| Field | Type | Description |
| --- | --- | --- |
| `title` | string? | Optional caption text. |
| `position` | openmw.util.Vector2? | Initial position; defaults to 80×80. |
| `size` | openmw.util.Vector2? | Initial size; defaults to 400×300. |
| `minSize` | openmw.util.Vector2? | Minimum size; defaults to 64×64. |
| `maxSize` | openmw.util.Vector2? | Optional maximum size. |
| `movable` | boolean? | Enables dragging; enabled by default. |
| `resizable` | boolean? | Enables edge resizing; enabled by default. |
| `closable` | boolean? | Adds a close control. |
| `pinnable` | boolean? | Adds a pin control. |
| `pinned` | boolean? | Initial pin state. |
| `innerBorder` | boolean? | Adds the vanilla-style inner border below the caption; enabled by default. |
| `padding` | number? | Empty space between the frame and the body on all four sides; defaults to `8`. |
| `onMove` | function? | Receives the current position during movement. Invalidate the owning element here for live dragging. |
| `onResize` | function? | Receives size and position during resizing. |
| `onClose` | function? | Runs when close is pressed. |
| `onPin` | function? | Receives the new pin state. Invalidate the owning element here so the pin skin redraws. |
| `clampToScreen` | boolean? | Keeps movement within the screen. |
| `referenceSize` | openmw.util.Vector2 or function? | Coordinate space for nested windows. |
| `captionHeight` | number? | Caption strip height. |
| `resizeHandle` | number? | Resize hitbox; defaults to `4`. |
| `captionProps` | table? | Properties for the generated caption. |
| `captionTextProps` | table? | Properties for the generated caption text. |
| `backgroundProps` | table? | Properties for the generated background; H3UI themes use this slot for the configured background color and transparency. |
| `content` | table? | Body content; takes precedence over `children`. |
| `children` | table? | Body layouts used when `content` is absent. |

Common layout fields are documented on the [UI Components overview](@/h3lp_yours3lf/docs/api/components/_index.md). The caller owns geometry, persistence, visibility, redraw, and destruction.

## See also

[caption](@/h3lp_yours3lf/docs/api/components/caption.md) · [text](@/h3lp_yours3lf/docs/api/components/text.md)
