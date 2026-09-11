+++
title = "Randomized Object Creation"
description = "Create a chance-based scatter of objects around an active trigger."
weight = 50

[extra]
api_docs = true
kind = "recipe"
+++

## Goal

When a suitable creature becomes active, create several additional creatures at random offsets around it.

## Smallest YAML excerpt

```yaml
instances:
  - conditions:
      - record_id: mudcrab
      - player_level:
          min: 10
          max: 19
      - is_dead: false
    actions:
      - chance: 0.1
        create:
          mudcrab:
            count: 5
            position:
              x: { min: -300, max: 300 }
              y: { min: -300, max: 300 }
    once: per_cell
```

This is reduced from `Examples/InstanceModifier_MudcrabReinforcements.yaml`.

## Why it works

The conditions identify a living mudcrab while the player is in the chosen level range. The action-level `chance` gates the whole action block. `create` evaluates the `mudcrab` pool, creates five objects, and samples each supplied position component for each object. Position is relative to the trigger by default; an omitted `z` component contributes no offset.

Each record ID under `create` is its own pool. A pool can also use a fixed integer, a bare record string, a random count, and transform overrides supported by the schema.

## Persistence

`per_cell` marks the rule only for the current activation batch; that marker is not saved. Created objects are ordinary world objects and become part of the saved world state. Use a test save when tuning spawn counts.

## Caveats

- Every table-form random position component needs `max`; a condition range has different, independently optional-bound semantics.
- The trigger must be a valid active object and the created record must be available in the active content set.
- Relative offsets can place objects inside geometry or outside a safe nav/ground area. Keep the range conservative and test in the target cell.
- `once: per_cell` is an activation-batch policy, not a global “once ever” policy. Use `once: true` when the successful application should be remembered per saved object.
