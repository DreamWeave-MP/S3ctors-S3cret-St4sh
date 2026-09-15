---
title: CamHelper
description: Determine whether an object is onscreen and obtain a normalized viewport position.
weight: 75
extra:
  kind: api
---

{{ api_signature(value="require 'openmw.interfaces'.S3CamHelper → H3CamHelperInterface") }}

`S3CamHelper` is a player-scoped installed interface for target markers, lock-on indicators, and other UI that follows world objects. It is not a plain `require`-returned constructor.

Cod3x's [CamHelper Design Study](@/cod3x/docs/good-designs/cam-helper-extraction.md) follows its path from T4rg3t5 application code into a reusable H3 boundary and the performance fixes that followed.

```lua
local I = require 'openmw.interfaces'

local position = I.S3CamHelper.objectIsOnscreen(target)
if position then
    placeMarker(position.x, position.y)
end
```

| Member | Behavior |
| --- | --- |
| `isPositionBehindCamera(position)` | Return whether a world position lies behind the current camera. |
| `targetPosition(object, position, npcHeightOffset?)` | Choose an NPC-height-adjusted position or the object's bounding-box center. |
| `objectIsOnscreen(object, npcHeightOffset?)` | Return normalized `x`/`y` plus camera distance, or `nil` when outside the view. |
| `version` | Interface version, currently `2`. |

`objectIsOnscreen` uses strict screen-edge checks, camera view distance, and a behind-camera test. It does not perform an occlusion test or raycast, so “onscreen” does not mean unobstructed. Its returned `x` and `y` are normalized to `[0, 1]`; OpenMW defines `z` as the distance from the camera to the position in world-space units. For NPCs, the default target height is `1.6 * halfSize.z`. Pass a previously captured offset when animation-driven bounding-box changes would cause marker jitter.

The provider is implemented in [H3's CamHelper module](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content%2Fh3lp_yours3lf%2Fscripts%2Fs3%2FcamHelper.lua) and relies on OpenMW's [camera bindings](https://github.com/OpenMW/openmw/blob/master/apps/openmw/mwlua/camerabindings.cpp#L100-L125) and vector operations.
