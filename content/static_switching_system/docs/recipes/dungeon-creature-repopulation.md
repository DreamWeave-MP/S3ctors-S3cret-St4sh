+++
title = "Dungeon Creature Repopulation"
description = "Recreate dead creatures from their base records in selected dungeon cells."
weight = 75

[extra]
api_docs = true
kind = "recipe"
+++

## Goal

Recreate dead creatures in dungeon cells when their base records carry OpenMW's respawn flag.

## Smallest YAML excerpt

```yaml
log_name: The Dead Walk Again
priority: balance

instances:
  - conditions:
      - object_type: Creature
      - is_dead: true
      - is_respawning: true
      - cell_tag: CellDungeon
    actions:
      - replace: self
```

The same module is shipped as `Examples/InstanceModifier_DeadWalkAgain.yaml`. `cell_tag` requires FlexTag and its `CellDungeon` tag convention. Replace it with `cell_match`, explicit cell names, or another location condition when FlexTag is not part of the load order.

## Why it works

`is_dead` checks the current actor instance. `is_respawning` checks the matched Creature record's `isRespawning` flag as an eligibility marker, avoiding a second list of records. `replace: self` creates a fresh object from the original record ID, disables the dead source instance, and applies the normal placement pipeline to the replacement.

## NPC safety

Do not broaden this example to `object_type: [NPC, Creature]`. Recreating a named NPC can interfere with quest state, inventory, scripts, and unique world history. If an NPC really belongs in a custom resurrection rule, constrain it with explicit record IDs and, where necessary, `content_file_target`, known generic enemy classes or factions, and explicit exclusions. A broad indoor rule is how Caius Cosades acquires an unexpected constitutional right to return from the dead.

## Caveats

- Self-replacement is a fresh-instance operation, not an in-place reset. Runtime state from the old object is not copied.
- `is_respawning` uses the record's respawn flag as an eligibility check. SSS does not reproduce OpenMW's normal respawn timing; an eligible corpse is recreated the next time SSS processes it after becoming active.
- Keep `is_dead: true` or another narrowing condition on self-replacement rules. An unconditional rule can match the newly created object again on a later activation.
- A failed object creation is a no-op; the original object is disabled only after creation succeeds.
- This example deliberately targets `Creature`, not NPC, because generic NPC resurrection is dangerous even though `is_respawning` supports both actor record types.
