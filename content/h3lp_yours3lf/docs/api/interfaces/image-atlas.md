---
title: ImageAtlas
description: Address and cycle tiles from one atlas texture in a player UI.
weight: 62
extra:
  kind: api
---

{{ api_signature(value="require 'openmw.interfaces'.S3AtlasConstructor.constructAtlas(data) → ImageAtlas") }}

Use `ImageAtlas` when a UI needs many frames stored in one texture: an animated icon, hand pose, or status marker. H3 creates the tile resources and gives you an object that can spawn and cycle one image element.

{% usage_note(title="Installed interface · Player context") %}
The constructor is provided by H3's `S3AtlasConstructor` interface. Obtain it through `openmw.interfaces` in a player script. The atlas owns texture resources, not save data or an update handler.
{% end %}

## Create and display an atlas

```lua
local I = require 'openmw.interfaces'
local every = require 'scripts.s3.every'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local atlas = I.S3AtlasConstructor.constructAtlas {
  atlasPath = '<atlas VFS path>',
  tileSize = util.vector2(64, 64),
  tilesPerRow = 8,
  totalTiles = 32,
}

atlas:spawn {
  layer = 'HUD',
  name = 'MyModIcon',
  relativeSize = util.vector2(0.08, 0.08),
  relativePosition = util.vector2(0.5, 0.5),
  anchor = util.vector2(0.5, 0.5),
}

local nextFrame = every(0.1)

return {
  engineHandlers = {
    onFrame = function()
      if nextFrame() then atlas:cycleFrame(true) end
    end,
  },
}
```

`every(0.1)` uses real time by default, so the animation cadence is based on wall time rather than frame count and can continue while the game is paused.

Replace the atlas path and dimensions with the actual texture. `tileSize` is in atlas pixels. Frames are one-based and advance across each row before moving down.

## Members

| Call | Behavior |
| --- | --- |
| `constructAtlas(data)` | Creates one texture resource per tile and returns an atlas object. |
| `atlas:getCoordinates(frameNum)` | Returns the pixel offset for a one-based frame. |
| `atlas:getNextFrame(nextOrPrev)` | Moves the current frame forward when true or backward when false, wrapping at the ends. |
| `atlas:spawn(data)` | Creates and stores an `ui.TYPE.Image` element using the current frame. |
| `atlas:cycleFrame(nextOrPrev)` | Changes the spawned image resource to the next or previous frame and updates the element. |
| `atlas:getElement()` | Returns the spawned element, or nil before `spawn`. |

`spawn` requires `layer`; the other fields are optional image-layout properties. Call it before `cycleFrame`; cycling without an element raises. The atlas is runtime state, and its element becomes invalid after destruction.

Construction allocates the atlas object and `totalTiles` texture resources. Cycling updates an existing element. Construct atlases when the UI is created, not from `onFrame`.

Use ordinary `ui.texture` when you need one image resource, and use [uiSnapshot](@/h3lp_yours3lf/docs/api/packages/ui-snapshot.md) when the problem is inspecting a layout rather than displaying atlas frames.
