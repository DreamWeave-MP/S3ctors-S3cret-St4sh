+++
title = "Player and World-State Conditions"
description = "Match quest progress, globals, player stats, time, equipment, factions, and weather."
page_template = "docs/page.html"
weight = 40

[extra]
api_docs = true
kind = "api"
+++

These conditions read the player or shared world state rather than the target object. SSS may batch-cache the expensive underlying lookups, but each condition is still evaluated for each rule/object match. Their result is only a rule match; persistence comes from the enclosing rule's `once` value.

## `has_journal`

**Shape:** `has_journal: { quest: string, index?: integer, min?: integer, max?: integer }`

Matches the player's journal stage for `quest`, inclusive. `index` is shorthand for `min`. The schema requires `quest` and at least one of `index`, `min`, or `max`; a missing quest entry fails.

```yaml
has_journal:
  quest: a1_v_vivecinformants
  min: 50
```

## `global_value`

**Shape:** `global_value: [{ GlobalName: number | { min?: number, max?: number } }, ...]`

Checks MWScript globals. A number is a minimum; a range is inclusive. Every one-key map in the array must pass, so this condition is ANDed rather than an OR-list.

```yaml
global_value:
  - gamehour:
      min: 8
  - my_mod_stage:
      max: 3
```

## `player_level`

**Shape:** `player_level: number | { min?: number, max?: number }`

Checks the player's level. A bare number is an at-least threshold; a range is inclusive.

```yaml
player_level:
  min: 10
```

## `player_attribute`

**Shape:** `player_attribute: { AttributeId: number | { min?: number, max?: number }, ... }`

Checks modified player attributes. Numeric entries are minimums, tables are inclusive ranges, and all named entries must pass.

```yaml
player_attribute:
  strength:
    min: 50
```

## `player_skill`

**Shape:** `player_skill: { SkillId: number | { min?: number, max?: number }, ... }`

Checks modified player skills. All entries are ANDed.

```yaml
player_skill:
  longblade: 40
```

## `player_spell`

**Shape:** `player_spell: string | string[]`

Matches an exact spell ID known by the player. A list is any-of.

```yaml
player_spell: fireball
```

## `player_health`

**Shape:** `player_health: number | { min?: number, max?: number }`

Checks current player health. A number is a minimum; a range is inclusive.

```yaml
player_health:
  max: 20
```

## `player_magicka`

**Shape:** `player_magicka: number | { min?: number, max?: number }`

Checks current player magicka with the same threshold and inclusive range semantics.

```yaml
player_magicka:
  min: 50
```

## `player_fatigue`

**Shape:** `player_fatigue: number | { min?: number, max?: number }`

Checks current player fatigue with the same threshold and inclusive range semantics.

```yaml
player_fatigue:
  max: 25
```

## `time_of_day`

**Shape:** `time_of_day: number | { min?: number, max?: number }`

Checks the current game hour from `core.getGameTime()`. A bare number is at least that hour. Bounds are inclusive. When both bounds exist and `min > max`, the range wraps across midnight, such as `{ min: 20, max: 8 }`.

```yaml
time_of_day:
  min: 20
  max: 8
```

## `day_of_week`

**Shape:** `day_of_week: string | string[]`

Matches the current in-game Tamrielic weekday when the object is processed. It is a condition, not a weekday-change event. A string matches one canonical lowercase weekday; a list matches any listed weekday. The weekdays are `sundas`, `morndas`, `tirdas`, `middas`, `turdas`, `fredas`, and `loredas`.

```yaml
day_of_week:
  - loredas
  - sundas
```

The weekday is derived from the game calendar and cached for the current SSS activation batch. Waiting for a new weekday does not wake or reschedule an object; the rule is reconsidered the next time SSS processes that object.

## `player_faction`

**Shape:** `player_faction: { faction: string, rank?: integer, min?: integer, max?: integer }`

Checks player membership and rank in a faction. `rank` is shorthand for `min`; a range is inclusive. The schema requires a faction and at least one rank bound. A player outside the faction fails.

```yaml
player_faction:
  faction: mages guild
  rank: 2
```

## `player_equipped`

**Shape:** `player_equipped: string | string[]`

Matches an exact record ID against any item currently equipped by the player. A list is any-of.

```yaml
player_equipped: "iron longsword"
```

## `current_weather`

**Shape:** `current_weather: string | string[] | { isStorm?: boolean, name?: string }`

Reads weather in the player's cell. A string is a case-insensitive substring of the weather name; a list is any-of. The literal `none` matches when no weather is active. A map filters by storm flag and/or weather-name substring; both fields must match when both are present. The schema requires at least one map field.

```yaml
current_weather:
  isStorm: true
  name: rain
```

Player/world conditions use [condition comparison ranges](comparison-ranges.md), not action random ranges. They do not themselves change or persist player/world state.
