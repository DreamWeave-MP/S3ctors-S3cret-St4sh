+++
title = "Bad Weather Has Consequences"
description = "Use ash storms as activation-time conditions for statues and shrines."
weight = 50

[extra]
api_docs = true
kind = "experiment"
+++

## What this demonstrates

- [`current_weather`](@/static_switching_system/docs/api/conditions/player-and-world-state.md#current-weather)
- [`object_type`](@/static_switching_system/docs/api/conditions/location-and-identity.md#object-type) and [`record_id`](@/static_switching_system/docs/api/conditions/location-and-identity.md#record-id)
- [`transform` and `create`](@/static_switching_system/docs/api/actions/world-and-transform.md)
- [Activation-time processing](@/static_switching_system/docs/api/lifecycle.md#activation-and-deferred-work)

## Why it works

When a selected statue or shrine becomes active while the player's current weather is an ash storm, SSS twists it and scatters bones nearby. The weather map requires both `isStorm: true` and the name substring `ash`, so ordinary rain does not qualify.

The memorable rule is the boundary: weather is a condition, not a trigger. An ash storm beginning does not wake every statue in Vvardenfell. A statue entering the active scene while the storm condition already matches can be changed.

## The catch

- `current_weather` reads weather in the player's cell at object activation time; it is not an event subscription.
- `once: true` makes the mutation persistent per object after it succeeds. Changing the weather later does not undo it.
- The transform runs before the creation pool and always changes the target. Therefore `once: true` is recorded even when the 40% bone pool misses; this is a one-shot creation roll, unlike the probabilistic-only rules in the Low Health and Compound Interest experiments.
- The fixture uses vanilla static record IDs; add more statues or shrines only after checking the active content load order.
- Created bones are world objects, not temporary weather particles.

## Complete YAML

The source fixture is `Examples/InstanceModifier_BadWeatherHasConsequences.yaml`.

```yaml
log_name: Bad Weather Has Consequences
priority: polish

instances:
  - conditions:
      - object_type: Static
      - record_id:
          - ex_dwrv_statue00
          - ex_imp_dragonstatue
          - ex_v_vivecstatue_01
          - ex_v_vivecstatue_02
          - furn_6th_ashstatue
          - furn_shrine_vivec_01
          - furn_shrine_tribunal_01
      - current_weather:
          isStorm: true
          name: ash
    once: true
    actions:
      - transform:
          rotate:
            z: { min: -12, max: 12 }
      - create:
          furn_bone_01:
            count:
              max: 2
            chance: 0.4
            position:
              x: { min: -80, max: 80 }
              y: { min: -80, max: 80 }
```
