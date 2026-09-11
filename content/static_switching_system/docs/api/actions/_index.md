+++
title = "Instance Actions"
description = "Actions for replacing, transforming, spawning, moving, and modifying matched OpenMW objects."
template = "docs/section.html"
page_template = "docs/page.html"
sort_by = "weight"
weight = 50

[extra]
api_docs = true
kind = "api"
+++

Instance actions run from YAML `actions` arrays after a rule's conditions match. An action table may contain multiple fields; SSS executes those fields in a fixed priority order rather than YAML key order. See [action execution order](execution-order.md).

## Choose a reference

| Need | Reference |
| --- | --- |
| Replacement, transforms, teleport, and spawning | [World and transform actions](world-and-transform.md) |
| Add, remove, equip, and unequip inventory items | [Inventory and equipment actions](inventory-and-equipment.md) |
| Locks, keys, traps, ownership, globals, disable, and delete | [World-state actions](world-state.md) |
| Scripts, activation, tags, and sounds | [Scripts, tags, and sound actions](scripts-tags-and-sound.md) |
| Sampled action values and required upper bounds | [Random action ranges](random-ranges.md) |
| Combined action order and chance rolls | [Action execution order](execution-order.md) |

## Common rule shape

```yaml
instances:
  - conditions:
      - record_id: mudcrab
    actions:
      - chance: 0.25
        create:
          mudcrab:
            count: 2
            position:
              x: { min: -100, max: 100 }
```

`chance` belongs to an action block, not to a condition. It rolls independently each time that action block is reached. Per-entry or per-pool chance is documented with the relevant action. For rule persistence, `once: true` saves a successful rule application for the object; `once: per_cell` tracks it only for the current SSS activation batch; omitted `once` permits later activations. A failed or no-op action does not generally establish a successful rule application, except where a dependency caveat is called out.
