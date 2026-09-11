+++
title = "World-State Actions"
description = "Modify locks, keys, traps, ownership, globals, visibility, and object lifetime."
page_template = "docs/page.html"
weight = 40

[extra]
api_docs = true
kind = "api"
+++

## `lock_level`

**Shape:** `lock_level: number | { min?: number, max: number }`

On a lockable target, a positive value locks at that level; zero or a negative value unlocks. A range samples an integer lock level and requires `max`, defaulting `min` to `1`. Non-lockable objects, including statics and creatures, no-op.

```yaml
lock_level:
  min: 1
  max: 20
```

## `key`

**Shape:** `key: false | [{ RecordId: chance }, ...]`

`false` removes the key from a lockable object. An array is an ordered list of one-key chance maps; the first entry whose chance passes wins. Chance can be fixed or a chance range. Non-lockable objects no-op, and a list in which every roll fails leaves the current key unchanged.

```yaml
key:
  - "key_iron": 0.7
  - "key_steel": 1.0
```

## `trap`

**Shape:** `trap: false | [{ RecordId: chance }, ...]`

The trap analogue of `key`: `false` removes the trap, and the ordered first-passing entry sets one. Non-lockable objects no-op.

```yaml
trap:
  - trap_fire00: 0.5
  - trap_frost00: 1.0
```

## `set_ownership`

**Shape:** `set_ownership: { owner?: string, faction?: string, factionRank?: integer }`

Sets any supplied owner record ID, faction ID, and faction rank on the target's ownership data. Fields are independent and can be combined.

```yaml
set_ownership:
  faction: fighters guild
  factionRank: 2
```

The schema permits an empty map, but it has no effect. `factionRank: 0` is a real rank value; there is no documented clear-ownership form here.

## `global_set`

**Shape:** `global_set: { name: string, value: number | { min?: number, max: number } }`

Sets an MWScript global to a fixed value or a sampled integer value. Range tables require `max` and default their lower bound to `1`.

```yaml
global_set:
  name: my_mod_stage
  value: 2
```

The action does not require the global to pre-exist. Use the schema-approved `name` and `value` fields; malformed ranges can assert. A `min: 0` lower bound is preserved when sampling a global.

## `disable`

**Shape:** `disable: true | { chance?: number }`

Schedules the final action target to be disabled. With `replace`, the replacement is disabled; without it, the original target is. The object is disabled after rule processing. The table form rolls an independent chance. `disable: false` is schema-invalid and is a no-op in the runtime handler.

```yaml
disable:
  chance: 0.5
```

Disabled objects do not trigger SSS's later `onObjectActive` path on cell insertion, so SSS cannot re-enable them across cell visits. Use `once: true` for a one-time disable, or do not use disable for a toggle you expect to reverse.

## `delete`

**Shape:** `delete: true`

Queues removal of the original matched source for asynchronous processing. With `replace` in the same action table, the queue entry is made only if replacement succeeded. Use a separate action table for unconditional source deletion.

```yaml
delete: true
```

Deletion is deferred through SSS's delete manager. It is not a synchronous validity guarantee at the action call site.
