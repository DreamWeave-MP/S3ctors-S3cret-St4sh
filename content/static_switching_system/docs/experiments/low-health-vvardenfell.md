+++
title = "Low Health Makes Vvardenfell Worse"
description = "Turn low player health into persistent, activation-time world scarring."
weight = 30

[extra]
api_docs = true
kind = "experiment"
+++

## What this demonstrates

- [`player_health`](@/static_switching_system/docs/api/conditions/player-and-world-state.md#player-health)
- [`object_type`](@/static_switching_system/docs/api/conditions/location-and-identity.md#object-type), [`cell_match`](@/static_switching_system/docs/api/conditions/location-and-identity.md#cell-match), and [`record_id`](@/static_switching_system/docs/api/conditions/location-and-identity.md#record-id)
- [`transform`, `create`, and `replace`](@/static_switching_system/docs/api/actions/world-and-transform.md)
- [Persistent instance mutations](@/static_switching_system/docs/concepts/persistence.md)

## Why it works

Three rules use increasingly severe absolute health thresholds. At 50 health or less, selected tomb clutter drifts. At 25 or less, it grows a few more bones. At 10 or less, skulls and bone piles have a small chance to become bonewalkers. Since matching rules can all contribute, the lowest-health band can layer all three effects during one activation.

The player's state controls whether a mutation occurs when the object becomes active. It does not continuously control the mutation afterward.

## The catch

- `player_health` compares absolute current health; it is not a percentage-of-maximum-health condition. Tune the thresholds for the intended difficulty curve.
- Every rule uses `once: true`. The world mutation persists after recovery; `once` only prevents a successful rule from being applied again to the same object.
- Chance misses do not consume `once: true`. The 25-health bone pool and 10-health replacement remain eligible until their action actually changes something; they are repeated opportunities, not one-shot lifetime lotteries.
- SSS does not scan unloaded cells or react when health changes. The target must become active while the threshold matches.
- The fixture uses vanilla static record IDs; add more selectors only after checking the active content load order.

## Complete YAML

The source fixture is `Examples/InstanceModifier_LowHealthMakesVvardenfellWorse.yaml`.

```yaml
log_name: Low Health Makes Vvardenfell Worse
priority: polish

instances:
  - conditions:
      - object_type: Static
      - cell_match: tomb
      - record_id:
          - furn_bone_01
          - furn_bone_rib_01
          - furn_bone_skull_01
          - furn_bone_stake00
          - furn_com_lantern_hook
      - player_health:
          max: 50
    once: true
    actions:
      - transform:
          position:
            x: { min: -3, max: 3 }
            y: { min: -3, max: 3 }
          rotate:
            z: { min: -8, max: 8 }

  - conditions:
      - object_type: Static
      - cell_match: tomb
      - record_id:
          - furn_bone_01
          - furn_bone_rib_01
          - furn_bone_skull_01
          - furn_bone_stake00
          - furn_com_lantern_hook
      - player_health:
          max: 25
    once: true
    actions:
      - create:
          furn_bone_01:
            count:
              max: 2
            chance: 0.25
            position:
              x: { min: -64, max: 64 }
              y: { min: -64, max: 64 }

  - conditions:
      - object_type: Static
      - cell_match: tomb
      - record_id:
          - furn_bone_01
          - furn_bone_skull_01
      - player_health:
          max: 10
    once: true
    actions:
      - replace:
          bonewalker: 0.05
```
