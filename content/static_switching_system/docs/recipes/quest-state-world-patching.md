+++
title = "Quest-State World Patching"
description = "Change levelled world objects when a quest reaches a journal stage."
weight = 40

[extra]
api_docs = true
kind = "recipe"
+++

## Goal

Replace a tomb levelled-creature spawner after a main-quest stage is reached, without a custom quest script.

## Smallest YAML excerpt

```yaml
instances:
  - conditions:
      - cell_match: tomb
      - object_type: LevelledCreature
      - record_id: ^in_tomb_all_lev%+0$
      - has_journal:
          quest: a1_v_vivecinformants
          index: 50
    once: true
    actions:
      - replace:
          in_tomb_all_lev+2: 1.0
```

This is the first quest-gated phase in `Examples/InstanceModifier_TombSpiceUp.yaml`. The `%+` escapes the plus in a Lua pattern; the anchors keep the match specific.

## Why it works

All listed conditions must pass. `cell_match` is a case-insensitive substring test; `object_type` limits the rule to levelled creature objects; `has_journal.index` is a minimum journal stage; and `replace` tries the named replacement with the supplied chance. `once: true` prevents the same rule from repeatedly replacing the object after its first successful application.

For a bounded quest phase, use `min` and `max` instead of (or alongside) `index`. For an exact placed reference, use `content_file_target` with the content filename and reference number rather than a stale standalone reference-number condition.

## Persistence

The once-cache and replacement object's saved state let the successful instance change survive a save/load. If later quest stages need cleanup, express that as another instance rule, as the shipped example does for post-Dagoth-Ur cleanup.

## Caveats

- `has_journal` reads the player's quest state when the object is processed; it is not a continuously running quest listener.
- `replace` chooses candidates through their chance values. Do not rely on YAML map order to define a weighted distribution.
- The replacement record must exist in the active content files. A failed creation attempt leaves the original target unchanged.
- Broad `cell_match: tomb` also matches cell IDs containing that text. Narrow it with additional conditions when a quest patch must be local.

See [save and update compatibility](@/static_switching_system/docs/compatibility/save-updates-and-persistence.md) before applying this to an existing save.
