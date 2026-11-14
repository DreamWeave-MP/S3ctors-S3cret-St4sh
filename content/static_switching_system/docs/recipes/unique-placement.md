+++
title = "Placing Something Unique in a Cell"
description = "Put one NPC, creature, or object at an exact spot the first time the player enters a cell."
weight = 90

[extra]
api_docs = true
kind = "recipe"
+++

## Goal

Add a single newcomer to a specific cell, at a predictable position, exactly once per save, without matching any object that is already there.

## Smallest YAML excerpt

```yaml
instances:
  - trigger: cell_enter
    conditions:
      - cell: "Balmora, South Wall Cornerclub"
    actions:
      - create:
          dremora:
            transform_type: absolute
            position:
              x: 291
              y: 537
              z: 261
            rotate:
              z: 90
    once: true
```

This is `Examples/InstanceModifier_ADremoraWalksIntoACornerclub.yaml`.

## Why it works

The [`cell_enter` trigger](@/static_switching_system/docs/concepts/triggers.md#entering-a-cell) fires once each time the player enters a cell and runs the rule on the player. The rule is therefore about the place: `cell` names it, and nothing inside it has to be found.

`create` spawns into the cell of the object the rule runs on, which is the player's. `transform_type: absolute` makes `position` and `rotate` exact cell coordinates; without it they would be offsets from wherever the player happens to stand.

`once: true` records the rule against the player. There is one player per save, so the rule applies once ever, however many times the cell is entered.

For an exterior cell, use `coords` with the grid position instead of `cell`.

## Persistence

The created object is an ordinary world object and is saved with the game. The once mark is saved too. Removing the module later does not remove what it created.

## Caveats

- The rule runs when the player is *in* the cell. Outdoors, something placed in a neighbouring cell appears when the player steps into that cell, not when it comes into view.
- `cell_enter` also fires on the first check after a load or a new game. With `once: true` that is harmless; without it, the rule applies on every load as well as every entry.
- `replace`, `disable`, and `delete` are refused on a `cell_enter` rule, because their target would be the player.
- If the `create` cannot place every object it was asked for, the rule still counts as applied; see [When a create only partly succeeds](@/static_switching_system/docs/api/actions/world-and-transform.md#when-a-create-only-partly-succeeds).
- This replaces the older workaround of matching an anchor object in the cell with an `active` rule. That workaround is evaluated against every object that loads anywhere; this is evaluated once per cell change.

See [save and update compatibility](@/static_switching_system/docs/compatibility/save-updates-and-persistence.md) before adding a placement to an existing save.
