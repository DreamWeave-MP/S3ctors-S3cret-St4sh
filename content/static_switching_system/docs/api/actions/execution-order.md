+++
title = "Action Execution Order"
description = "Fixed ordering, chance rolls, replacement targets, and persistence caveats for combined actions."
page_template = "docs/page.html"
weight = 10

[extra]
api_docs = true
kind = "api"
+++

SSS sorts action fields by this fixed priority, independent of YAML mapping order:

| Order | Action |
| ---: | --- |
| 1 | `replace` |
| 2 | `transform` |
| 3 | `teleport` |
| 4 | `set_ownership` |
| 5 | `add_tag` |
| 6 | `remove_tag` |
| 7 | `add` |
| 8 | `remove` |
| 9 | `equip` |
| 10 | `unequip` |
| 11 | `lock_level` |
| 12 | `key` |
| 13 | `trap` |
| 14 | `create` |
| 15 | `global_set` |
| 16 | `playsound` |
| 17 | `add_lua_script` |
| 18 | `activate_by_player` |
| 19 | `remove_lua_script` |
| 20 | `disable` |
| 21 | `delete` |

## Action-block chance

**Shape:** `chance: number` alongside one or more action fields.

The block chance is rolled separately for each action table as SSS processes the rule. A failed roll skips every action field in that block. Omitted chance always permits the block; `0` never does and `1` always does.

```yaml
instances:
  - actions:
      - chance: 0.5
        add:
          gold_001: 10
        playsound: item_gold
```

## Combining actions

The following example first replaces the target, then transforms the current action target, and finally schedules disable/delete according to their documented target rules.

```yaml
instances:
  - conditions:
      - record_id: old_creature
    actions:
      - replace:
          new_creature: 1.0
        transform:
          scale: 1.25
        disable: true
        delete: true
```

`replace` changes the current action target to a newly created object only when a replacement roll succeeds. With `replace: self`, that object is created from the original object's record ID. Later transform, teleport, object-property, inventory, script, tag, sound, and disable operations use that replacement target. `delete` always refers to the original matched source; when it shares an action table with `replace`, it queues deletion only after a successful replacement. Use a separate delete action table when source deletion must be unconditional.

SSS accumulates transform and teleport placement changes, then performs one engine placement operation after the action list finishes. A teleport starts from the current accumulated cell, position, and rotation, so transforms and teleports compose without depending on the engine applying `GameObject:teleport()` immediately. A later transform continues from the intended teleported placement and clears an earlier teleport's `onGround` request. `create` receives that same accumulated cell, position, rotation, and scale, so pools are based on the pending placement rather than the target's still-committed engine state. A pending `onGround: true` teleport still contributes its requested, unsnapped position; `create` cannot observe the later ground-snapped result. `playsound` remains attached to the target's currently committed engine position. Deletes are queued and processed asynchronously, not necessarily during the handler call. A failed or unsupported action generally no-ops; invalid types, missing required random upper bounds, invalid records, and invalid cells can raise or log according to the action.

See [random action ranges](random-ranges.md) for sampled values and the relevant grouped pages for target restrictions and no-op behavior.
