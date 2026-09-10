---
title: Settings
description: T4rg3t5's player-backed settings and their PLAYER and MENU access contract.
weight: 40
extra:
  api_docs: true
  kind: settings
---

Settings live in `SettingsPlayerT4rg3t5`. PLAYER scripts should normally use the [Manager](@/t4rg3t5/docs/api/interface.md); MENU scripts can access the player section directly. LOAD scripts can't access it—they don't get a vote here.

```lua
local Settings = require 'openmw.storage'.playerSection('SettingsPlayerT4rg3t5')

local checkLOS = Settings:get('CheckLOS')
Settings:set('CheckLOS', true)
```

## Fields

| Field | Type | Default | Meaning |
| --- | --- | --- | --- |
| `S3TargetLockBinding` | input binding | `T4TargetLockBindingKey` | Binding for the `S3TargetLock` trigger. |
| `TargetLockToggle` | boolean | `true` | Enables target locking. |
| `SwitchOnDeadTarget` | boolean | `true` | Selects another target when the locked target dies. |
| `CheckLOS` | boolean | `false` | Keeps checking line of sight while locked. |
| `ThirdPersonLockCamera` | boolean | `true` | Enables T4rg3t5's third-person lock camera. |
| `EnableFlickSwitch` | boolean | `true` | Enables mouse-flick target switching. |
| `FlickSwitchDistance` | integer | `64` | Mouse distance required for flick switching. |
| `EnableHitBounce` | boolean | `true` | Enables hit feedback on the target marker. |
| `HitBounceSize` | integer | `16` | Additional marker size at the bounce peak. |
| `DisableLockWhenSheathing` | boolean | `false` | Clears the lock when the player sheathes. |
| `LockOnCombatStart` | boolean | `false` | Automatically locks onto an actor that starts combat with the player. |
| `CameraDistance` | integer | `120` | Base camera distance from the player. |
| `CameraHeight` | integer | `25` | Camera height offset. |
| `CameraSideOffset` | integer | `90` | Horizontal shoulder offset. |
| `CameraPreferredShoulder` | string | `Right` | Shoulder preferred when a new target lock begins; collision and visibility can still switch sides. |
| `CameraFOV` | integer | `0` | Vertical lock-camera field of view in degrees; `0` inherits the current FOV. T4rg3t5 restores the previous FOV when its camera ends unless another camera has changed it. |
| `CameraMinDistance` | integer | `30` | Minimum collision-pinned camera distance. |
| `CameraResponsiveness` | integer | `6` | Third-person camera spring responsiveness. |
| `CameraLookResponsiveness` | integer | `8` | Look-target spring responsiveness. |
| `CameraLookBias` | integer | `80` | Percentage bias from player center toward the target. |
| `TargetFramingHeight` | integer | `80` | Height on the target that the lock camera looks toward, from feet (`0`) to head (`100`). |
| `LockLossDelay` | number | `0.25` | Seconds a temporarily invalid target remains locked before the lock breaks. |
| `TargetMinSize` | integer | `32` | Marker size at or beyond the minimum-size distance. |
| `TargetMinDistance` | integer | `256` | Distance at which the marker reaches minimum size. |
| `TargetMaxSize` | integer | `128` | Marker size at or below the maximum-size distance. |
| `TargetMaxDistance` | integer | `3564` | Maximum target and marker distance. |
| `TargetLockIcon` | string | `Starburst` | Base name of the marker texture. |
| `TargetColorF` | color | `#0df8cc` | Marker color at 100% health or above. |
| `TargetColorVH` | color | `#069e00` | Marker color at 80–100% health. |
| `TargetColorH` | color | `#047a00` | Marker color at 60–80% health. |
| `TargetColorW` | color | `#9e7100` | Marker color at 40–60% health. |
| `TargetColorVW` | color | `#4c3700` | Marker color at 20–40% health. |
| `TargetColorD` | color | `#4c0000` | Marker color at 0–20% health or below. |

The settings menu watches the same section, so external writes update its controls.
