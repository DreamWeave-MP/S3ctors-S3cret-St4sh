+++
title = "The House Moves When You're Not Looking"
description = "Use activation batches and small relative transforms to make dungeon clutter drift over time."
weight = 10

[extra]
api_docs = true
kind = "experiment"
+++

## What this demonstrates

- [Activation and deferred processing](@/static_switching_system/docs/api/lifecycle.md#activation-and-deferred-work)
- [`once: per_cell`](@/static_switching_system/docs/concepts/persistence.md#instance-rules)
- [`object_type`](@/static_switching_system/docs/api/conditions/location-and-identity.md#object-type), [`cell_match`](@/static_switching_system/docs/api/conditions/location-and-identity.md#cell-match), and [`record_id`](@/static_switching_system/docs/api/conditions/location-and-identity.md#record-id)
- [`transform`](@/static_switching_system/docs/api/actions/world-and-transform.md#transform) with [random action ranges](@/static_switching_system/docs/api/actions/random-ranges.md)

## Why it works

When a matching static object becomes active, SSS samples a small position offset and rotation and applies them relative to the object's current transform. `once: per_cell` prevents duplicate work within the current activation batch, but allows a later batch to roll again.

Nothing is polling these objects. They move when the world wakes them back up. Because the transform is relative, repeated successful activations can accumulate into a slow drift rather than replacing the original placement with one fixed random value.

## The catch

- `per_cell` means the current activation batch, not a tracked cell identity, and its marker is not saved.
- The transform itself may remain part of the saved world state, so this is accumulated mutation, not a temporary visual effect.
- `cell_match: tomb` is deliberately broad. Replace it with explicit cells, regions, or a FlexTag condition when “tomb” is not a sufficient boundary.
- The selectors use vanilla static record IDs; expand the list only after checking the active content load order.

## Complete YAML

The source fixture is `Examples/InstanceModifier_HouseMoves.yaml`.

```yaml
log_name: The House Moves When You're Not Looking
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
    once: per_cell
    actions:
      - transform:
          position:
            x: { min: -4, max: 4 }
            y: { min: -4, max: 4 }
          rotate:
            z: { min: -3, max: 3 }
```
