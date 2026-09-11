+++
title = "Object Property Conditions"
description = "Match names, meshes, inventory, scripts, tags, enchantments, locks, keys, and traps."
page_template = "docs/page.html"
weight = 20

[extra]
api_docs = true
kind = "api"
+++

These conditions inspect the active object. Type-restricted checks return false when the target cannot provide the requested property.

## `nameMatch`

**Shape:** `nameMatch: string | string[]`

Matches a non-static object's record name by exact equality or plain substring. Static objects never match because they do not have a record name. The handler's substring comparison is not a case-folded comparison.

```yaml
nameMatch: Guard
```

## `has_name`

**Shape:** `has_name: boolean`

Tests whether the target record has a non-empty name. Objects without a type count as unnamed.

```yaml
has_name: false
```

## `mesh`

**Shape:** `mesh: string | string[]`

Matches the target record's model after SSS mesh-path normalization. Listed paths are alternatives.

```yaml
mesh: "r/CliffRacer.NIF"
```

## `scale`

**Shape:** `scale: number | { min?: number, max?: number }`

A number requires the current scale to equal that number. A range compares the current scale inclusively; either bound may be omitted in the condition form. See [comparison ranges](comparison-ranges.md).

```yaml
scale:
  min: 0.5
  max: 1.2
```

## `carrying`

**Shape:** `carrying: string | { RecordId: integer } | [string | { RecordId: integer }, ...]`

For a record ID, tests whether an Actor or Container inventory contains that item. A count map requires at least the specified count. A YAML sequence is an any-of list of record IDs or count maps. Other target types do not match.

```yaml
carrying:
  gold_001: 100
```

## `has_lua_script`

**Shape:** `has_lua_script: string | string[]`

Exact match against a Lua script path attached to the object. A list matches if any listed path is attached.

```yaml
has_lua_script: Scripts/myMod/object.lua
```

## `has_mwscript`

**Shape:** `has_mwscript: string | string[]`

Case-insensitive exact match against the object's MWScript record ID. It fails when no MWScript is attached.

```yaml
has_mwscript: my_script
```

## `has_tag`

**Shape:** `has_tag: string | string[]`

Matches any listed FlexTag on the object. This condition requires the optional FlexTag mod/interface; without it, it always returns false.

```yaml
has_tag: LootContainer
```

## `cell_tag`

**Shape:** `cell_tag: string | string[]`

Matches any listed FlexTag on the object's cell. It has the same optional FlexTag dependency and no-match behavior as `has_tag`.

```yaml
cell_tag: CellDungeon
```

## `has_enchantment`

**Shape:** `has_enchantment: boolean`

Tests whether the target record has an enchantment. A target without a readable record does not match either positive form.

```yaml
has_enchantment: true
```

## `enchantment`

**Shape:** `enchantment: string | string[]`

Case-insensitive exact match against the target record's enchantment ID. No enchantment means false.

```yaml
enchantment: fire_damage
```

## `locked`

**Shape:** `locked: boolean | integer | { min?: integer, max?: integer }`

A boolean checks locked or unlocked state. A number requires a locked object at that level or higher. A range requires a locked object whose lock level is within the inclusive bounds. Non-lockable targets return false. In the YAML schema, range objects must provide at least one bound; the action form has different random-range semantics.

```yaml
locked:
  min: 25
  max: 50
```

## `has_key`

**Shape:** `has_key: boolean | string | string[]`

On a lockable target, `true` tests for any key, `false` for no key, and a string or list tests case-insensitive exact key ID. Non-lockable targets return false.

```yaml
has_key: true
```

## `has_trap`

**Shape:** `has_trap: boolean | string | string[]`

The trap analogue of `has_key`: booleans test presence, while strings and lists test case-insensitive exact trap spell IDs. Non-lockable targets return false.

```yaml
has_trap: false
```

## No-op and dependency notes

Name, inventory, script, enchantment, lock, key, and trap checks fail safely when the target lacks the required OpenMW type capability. FlexTag conditions are deliberately dependency-sensitive rather than silently matching all objects. Conditions are evaluated before actions; they do not persist state themselves.
