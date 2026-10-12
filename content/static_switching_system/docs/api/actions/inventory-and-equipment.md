+++
title = "Inventory, Equipment, and Spell Actions"
description = "Add, remove, equip, and unequip items on actor and container targets, and add, remove, or apply spells on actors."
page_template = "docs/page.html"
weight = 30

[extra]
api_docs = true
kind = "api"
+++

The four item actions accept the common item forms below. The target must expose an Actor or Container inventory; otherwise the action no-ops.

| Form | Meaning |
| --- | --- |
| `item_id` | One item, count `1`. |
| `[item_id, ...]` | Each item, using the action's default count. |
| `{ item_id: count }` | Fixed count per item. |
| `{ item_id: { count?: integer | { min?: integer, max: integer }, chance?: number | { min?: number, max: number } } }` | Count and optional per-entry chance. |

Item count range tables are sampled integer ranges and require `max`; their default `min` is `1`. A chance is a number from `0` to `1`, or `{ min?: number, max: number }`; entry chance is tested independently. A nested item-detail map must provide `count` or `chance`. See [random action ranges](@/static_switching_system/docs/api/actions/random-ranges.md).

## `add`

**Shape:** `add: RecordId | RecordId[] | { RecordId: integer | { count?: integer | { min?: integer, max: integer }, chance?: number | { min?: number, max: number } } }`

Creates and moves requested items into an Actor or Container inventory. String and array entries use count `1`; map entries default to count `1` when only `chance` is supplied.

```yaml
add:
  gold_001:
    count: 25
    chance: 0.5
```

Counts below one are not applied. An invalid target or failed inventory lookup returns a no-op.

## `remove`

**Shape:** `remove: RecordId | RecordId[] | { RecordId: integer | { count?: integer | { min?: integer, max: integer }, chance?: number | { min?: number, max: number } } }`

Removes items from an Actor or Container inventory. A string requests one. Array entries use `math.huge`, so they remove all available copies of each listed record. Map counts request the specified amount and are capped at what is available.

```yaml
remove:
  - glass claymore
  - ebony longsword
```

An absent item or unsupported target is a no-op. A partial available stack can be removed even when fewer than the requested count exists.

## `equip`

**Shape:** `equip: RecordId | RecordId[] | { RecordId: integer | { count?: integer | { min?: integer, max: integer }, chance?: number | { min?: number, max: number } } }`

Queues a forced OpenMW `UseItem` event for each requested item on an Actor. If an item is missing, SSS creates the requested count before queueing the use. OpenMW decides whether the item equips or is consumed/used; this is not an equipment-slot API.

```yaml
equip:
  imperial shield: 1
```

Non-actors, invalid counts, and failed inventory access no-op. The use is queued rather than a synchronous guarantee that the final equipment table has already changed.

## `unequip`

**Shape:** `unequip: RecordId | RecordId[] | { RecordId: integer | { count?: integer | { min?: integer, max: integer }, chance?: number | { min?: number, max: number } } }`

Queues forced `UseItem` events for currently equipped matching items on an Actor. The requested count must already be equipped; missing items are not created.

```yaml
unequip:
  imperial shield: 1
```

If fewer matching items are equipped than requested, that entry fails without partially queueing its requested count. As with `equip`, OpenMW processes the use event rather than the action synchronously.

## Spell actions

The three spell actions target Actors only; other objects no-op. They accept a spell record ID, an array of IDs, or a map of IDs to per-entry options. Map entries may carry a `chance` that is tested independently. There is no count.

## `add_spell`

**Shape:** `add_spell: RecordId | RecordId[] | { RecordId: { chance?: number | { min?: number, max: number } } }`

Adds spells to the actor's known spell list. Abilities, diseases, curses, and powers belong here, since they have no duration. A spell the actor already knows is a no-op and does not count as an applied action.

```yaml
add_spell:
  corprus: { chance: 0.25 }
```

## `remove_spell`

**Shape:** `remove_spell: RecordId | RecordId[] | { RecordId: { chance?: number | { min?: number, max: number } } }`

Removes spells from the actor's known spell list. A spell the actor does not know is a no-op.

```yaml
remove_spell:
  - common disease
  - ash woe blight
```

## `add_active_spell`

**Shape:** `add_active_spell: RecordId | RecordId[] | { RecordId: { chance?, effects?: integer[], name?: string, stackable?: boolean, ignoreResistances?: boolean, ignoreSpellAbsorption?: boolean, ignoreReflect?: boolean, quiet?: boolean } }`

Applies a timed spell effect to the actor through OpenMW's active spells, without casting VFX or sound. When `effects` is omitted, every effect of the spell record is applied; a record ID that is not a spell record, such as a potion or enchanted item, requires an explicit `effects` list of zero-based indexes and otherwise logs a warning and no-ops. The remaining fields are forwarded to OpenMW unchanged.

```yaml
add_active_spell:
  frenzy humanoid:
    name: Sixth House Whispers
    stackable: false
```

Spells without durations expire instantly when applied this way; use `add_spell` for those. Rules without `once` re-apply on every activation, which is the intended way to keep a cell-wide effect active while a condition such as `has_journal` holds.

