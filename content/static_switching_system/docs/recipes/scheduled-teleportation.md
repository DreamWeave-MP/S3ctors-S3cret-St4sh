+++
title = "Scheduled Teleportation"
description = "Move an actor to different destinations when activation-time hours match."
weight = 80

[extra]
api_docs = true
kind = "recipe"
+++

## Goal

Send an NPC to a morning destination when the NPC becomes active in its home cell.

## Smallest YAML excerpt

```yaml
instances:
  - conditions:
      - record_id: caius cosades
      - cell_match: "Balmora, Caius Cosades' House"
      - time_of_day:
          min: 8
          max: 13
    actions:
      - teleport:
          cell:
            x: -2
            y: -2
          position:
            x: -15371
            y: -12604
            z: 759
    once: per_cell
```

This is the morning leg of `Examples/InstanceModifier_CaiusSchedule.yaml`.

## Why it works

`time_of_day` compares the current game hour, while `cell_match` and `record_id` identify the actor and source location. `teleport.cell` accepts an exterior grid table or a cell name/ID; the position values are fixed numbers in this recipe. `once: per_cell` allows a fresh activation batch to evaluate the schedule again.

To express an overnight window, a comparison such as `min: 20` and `max: 8` wraps across midnight. The shipped schedule uses this for Caius's return home.

## Persistence

The per-cell marker is runtime-only and is not saved as a permanent schedule. A teleport that succeeds changes the actor's current world state, and that state is retained by the save.

## Caveats

- This is activation-time scheduling, not a continuously running clock callback. An actor that remains active will not be teleported merely because the hour changes.
- Several schedule rules can be written, but `once: per_cell` means the first matching successful rule can mark that rule for the current activation batch. Test overlapping time and location windows carefully.
- Cell names and IDs must resolve through the active content set. A missing destination is logged and the teleport is skipped.
- Teleport position components accept fixed numbers or random ranges; table-form random components need `max`. Rotation values are applied by the supported teleport handler and should be tested in the destination cell.

Read [save and update compatibility](@/static_switching_system/docs/compatibility/save-updates-and-persistence.md) before changing a schedule in a save that already contains its effects.
