+++
title = "Loot, Locks, and Traps"
description = "Add container loot and scale dungeon locks and traps by player level."
weight = 60

[extra]
api_docs = true
kind = "recipe"
+++

## Goal

Add a chance-based reward to a dungeon container and attach level-appropriate locks and traps to doors or containers.

## Smallest YAML excerpts

Add loot once per container:

```yaml
instances:
  - conditions:
      - object_type: Container
      - cell_tag: CellDungeon
      - locked: true
      - player_level:
          min: 15
          max: 24
    once: true
    actions:
      - chance: 0.6
        add:
          gold_001:
            count:
              min: 50
              max: 200
```

Set a random trap from an ordered chance list:

```yaml
instances:
  - conditions:
      - object_type: [Door, Container]
      - cell_tag: CellDungeon
      - locked: true
      - has_trap: false
    once: true
    actions:
      - chance: 0.3
        trap:
          - trap_fire00: 0.6
          - trap_frost00: 0.4
```

Raise a lock level with a sampled integer:

```yaml
instances:
  - conditions:
      - object_type: [Door, Container]
      - cell_tag: CellDungeon
      - locked: true
      - player_level:
          min: 25
    once: true
    actions:
      - lock_level:
          min: 60
          max: 100
```

These patterns come from `Examples/InstanceModifier_DynamicDungeonTraps.yaml`.

## Why it works

`cell_tag: CellDungeon` uses a FlexTag cell classification, while `object_type` accepts an OR-list of OpenMW type names. `locked`, `has_trap`, and `player_level` are comparison conditions. `add` modifies an actor or container inventory; `lock_level` locks at a positive level; and `trap` checks the ordered entries until one chance passes. The action-level `chance` is a separate gate from the item or trap entry chances.

## Persistence

The example uses `once: true`, so successful loot, lock, and trap changes are remembered in the saved instance-rule state and the affected world objects remain changed. These are instance changes, not static replacement-chain steps: removing the YAML does not automatically remove loot, unlock doors, or clear traps. To reverse a change, author an explicit rule using the corresponding supported action, such as `trap: false` or `key: false`, and apply it deliberately.

## Caveats

- Lock and trap actions no-op on non-lockable objects. The conditions in this recipe keep the target types narrow.
- A random lock-level table requires `max`; the `min`-only form is valid for comparison conditions but not for sampled action values.
- Trap entries are an ordered array of one-key tables. The first entry whose chance passes wins; keep the order explicit.
- `cell_tag` and `has_tag` require FlexTag. Without it, those conditions do not match; see [FlexTag compatibility](@/static_switching_system/docs/compatibility/flextag.md).
- Inventory record IDs must be available in the active content files. `add` is for actor or container inventories, not arbitrary statics.

`Examples/InstanceModifier_TombSpiceUp.yaml` shows the same actions alongside creature replacement and transforms.
