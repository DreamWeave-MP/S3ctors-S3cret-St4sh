+++
title = "Instance Conditions"
description = "Conditions for matching OpenMW objects, player state, location, ownership, and world state."
template = "docs/section.html"
page_template = "docs/page.html"
sort_by = "weight"
weight = 40

[extra]
api_docs = true
kind = "api"
+++

Instance conditions are YAML predicates. Put them in an instance rule's `conditions` array; every condition entry must pass. A table-valued condition is normally an OR-list when written as a YAML sequence, while map-shaped values are passed to the condition as one structured value. The exception is `global_value`, whose entries are ANDed. Conditions are normalized before evaluation; do not rely on YAML order.

These references document the instance-module format. Static replacement modules use `replace_meshes` and cannot be combined with `instances`.

## Choose a reference

| Need | Reference |
| --- | --- |
| Cells, regions, coordinates, files, and identity | [Location and identity](location-and-identity.md) |
| Meshes, names, inventory, tags, locks, and object properties | [Object properties](object-properties.md) |
| Target actors, stats, factions, spells, and disposition | [Actors and target state](actors-and-target-state.md) |
| Player state, quests, globals, time, equipment, and weather | [Player and world state](player-and-world-state.md) |
| Inverting conditions and exclusions | [Logic conditions](logic.md) |
| Comparison bounds and one-sided ranges | [Comparison ranges](comparison-ranges.md) |

## Common rule shape

```yaml
instances:
  - conditions:
      - object_type: Container
      - cell_match: tomb
    actions:
      - disable: true
```

Conditions do not roll chance. Add `chance` to an action block when the match should sometimes produce an effect. See [action execution order](@/static_switching_system/docs/api/actions/execution-order.md) and [random action ranges](@/static_switching_system/docs/api/actions/random-ranges.md).

## Evaluation

SSS may reorder conditions internally for efficient evaluation. Do not rely on YAML condition order.

Unless an entry says otherwise, a false or type-incompatible condition simply prevents the rule from matching; conditions do not persist state. Invalid condition names and invalid OpenMW type names raise errors. YAML shape and value constraints are enforced by the schema; runtime behavior outside schema validation is not a supported authoring contract.
