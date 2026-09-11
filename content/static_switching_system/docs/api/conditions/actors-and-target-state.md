+++
title = "Actor and Target-State Conditions"
description = "Match actor type, death, creature classification, stats, spells, factions, class, and disposition."
page_template = "docs/page.html"
weight = 30

[extra]
api_docs = true
kind = "api"
+++

Target conditions inspect the object being processed. Player conditions are on [the player and world state page](player-and-world-state.md). Bare numeric thresholds are generally at-least comparisons; `{ min, max }` tables are inclusive comparison ranges.

## `is_dead`

**Shape:** `is_dead: boolean`

Matches an Actor's dead state. Non-actors return false.

```yaml
is_dead: false
```

## `creature_type`

**Shape:** `creature_type: creatures | daedra | undead | humanoid | [named values, ...]`

Matches a Creature record's OpenMW creature classification. A list is any-of. The schema-approved YAML form uses the four named values. The runtime handler also accepts numeric OpenMW type values, but numeric YAML is not the schema contract.

```yaml
creature_type:
  - daedra
  - undead
```

Non-creatures return false.

## `race`

**Shape:** `race: string | string[]`

Case-insensitive exact match against an NPC's race ID. Non-NPCs return false.

```yaml
race: dunmer
```

## `target_disposition`

**Shape:** `target_disposition: number | { min?: number, max?: number }`

Checks the target NPC's disposition toward the player. A number is a minimum; a range is inclusive. Non-NPCs return false.

```yaml
target_disposition:
  min: 0
  max: 30
```

## `target_level`

**Shape:** `target_level: number | { min?: number, max?: number }`

Checks the target's current level. A bare number means at least that level; a range is inclusive. Targets without usable level stats return false.

```yaml
target_level:
  min: 10
```

## `target_attribute`

**Shape:** `target_attribute: { AttributeId: number | { min?: number, max?: number }, ... }`

Checks modified target attributes. A number is a minimum; a range is inclusive. Every attribute entry must pass. Targets without attribute stats return false.

```yaml
target_attribute:
  strength: 50
```

## `target_skill`

**Shape:** `target_skill: { SkillId: number | { min?: number, max?: number }, ... }`

Checks modified target skills. Every entry is ANDed. The handler requires target skill stats; non-compatible targets return false.

```yaml
target_skill:
  longblade:
    min: 40
```

## `target_spell`

**Shape:** `target_spell: string | string[]`

Matches an exact spell ID known by the target actor. A list is any-of. Targets without an actor spell list return false.

```yaml
target_spell: fireball
```

## `target_health`

**Shape:** `target_health: number | { min?: number, max?: number }`

Checks current target health. A number is a minimum and a range is inclusive. Targets without dynamic stats return false.

```yaml
target_health:
  max: 20
```

## `target_magicka`

**Shape:** `target_magicka: number | { min?: number, max?: number }`

Checks current target magicka using the same threshold and range semantics as `target_health`.

```yaml
target_magicka:
  min: 50
```

## `target_fatigue`

**Shape:** `target_fatigue: number | { min?: number, max?: number }`

Checks current target fatigue using the same threshold and range semantics as `target_health`.

```yaml
target_fatigue:
  max: 25
```

## `target_faction`

**Shape:** `target_faction: { faction: string, rank?: integer, min?: integer, max?: integer }`

Checks the target NPC's primary faction rank. `rank` is shorthand for a minimum rank. If no threshold is supplied, the schema rejects the rule; when a threshold is present, the target must belong to the faction and meet the inclusive threshold/range. Non-NPCs return false. This does not search every faction the NPC has joined.

```yaml
target_faction:
  faction: fighters guild
  min: 2
```

## `faction_owner_id`

**Shape:** `faction_owner_id: string | string[]`

Case-insensitive exact match against the faction ID in the target object's ownership data. A list is any-of. Objects without a faction owner return false.

```yaml
faction_owner_id: fighters guild
```

## `owner_id`

**Shape:** `owner_id: string | string[]`

Case-insensitive exact match against the NPC record ID in the target object's ownership data. A list is any-of. Objects without an owner return false.

```yaml
owner_id: caius cosades
```

## `faction_owner_rank`

**Shape:** `faction_owner_rank: number | { min?: number, max?: number }`

Checks the rank stored with the target object's faction ownership. A bare number is a minimum; a range is inclusive. Objects without a faction-owner rank return false.

```yaml
faction_owner_rank:
  min: 2
```

## `target_class`

**Shape:** `target_class: string | string[]`

Case-insensitive exact match against an NPC class ID. A list is any-of; non-NPCs return false.

```yaml
target_class: warrior
```
