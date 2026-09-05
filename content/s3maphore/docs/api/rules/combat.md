+++
title = "Combat Rules"
description = "Rules for combatants, target types, factions, levels, and dynamic stats."
weight = 20

[extra]
api_docs = true
kind = "PlaylistRules"
+++

Every combat rule returns `false` when the player has no tracked combat targets. Combat lookups operate on `Playback.state.combatTargets`, which is an array of live actor objects in insertion order.

## `combatTargetExact`

{{ api_signature(value="Playback.rules.combatTargetExact(validTargets) -> boolean") }}

Returns `true` when any current target's lowercased display name is a `true` key in `validTargets`.

```lua
local NamedTargets = {
    ['dagoth ur'] = true,
    ['vivec'] = true,
}

isValidCallback = function()
    return Playback.rules.combatTargetExact(NamedTargets)
end
```

## `combatTargetMatch`

{{ api_signature(value="Playback.rules.combatTargetMatch(validTargetPatterns) -> boolean") }}

Returns `true` when any target's lowercased display name contains one of the supplied plain-string patterns.

```lua
local DaedraNames = { 'dremora', 'clannfear', 'golden saint' }

isValidCallback = function()
    return Playback.rules.combatTargetMatch(DaedraNames)
end
```

Patterns are substring matches, not Lua patterns. Keep the input lowercase.

## `combatTargetType`

{{ api_signature(value="Playback.rules.combatTargetType(targetTypeRules) -> boolean") }}

Matches any current target against one of these true-valued keys: `npc`, `humanoid`, `undead`, `daedra`, or `creatures`.

```lua
local UndeadOrDaedra = {
    undead = true,
    daedra = true,
}

isValidCallback = function()
    return Playback.rules.combatTargetType(UndeadOrDaedra)
end
```

These are hash sets. Only `true` enables a type.

## `combatTargetClass`

{{ api_signature(value="Playback.rules.combatTargetClass(classes) -> boolean") }}

Matches any NPC target whose class is a true-valued key in `classes`. Creature targets do not have NPC classes.

```lua
local MartialClasses = {
    guard = true,
    warrior = true,
}

isValidCallback = function()
    return Playback.rules.combatTargetClass(MartialClasses)
end
```

Class keys must be lowercase.

## `combatTargetFaction`

{{ api_signature(value="Playback.rules.combatTargetFaction(factionRules) -> boolean") }}

Matches when any target has a faction rank inside one of the requested ranges. Each range accepts an optional `min` and `max`; omitted bounds use `1` and infinity.

```lua
local FactionRanks = {
    hlaalu = { min = 1, max = 3 },
    ashlanders = { min = 1 },
}

isValidCallback = function()
    return Playback.rules.combatTargetFaction(FactionRanks)
end
```

Faction names are passed to OpenMW's faction-rank query. Use the faction IDs used by the game data.

## `combatTargetLevelDifference`

{{ api_signature(value="Playback.rules.combatTargetLevelDifference(levelRule) -> boolean") }}

Matches when any target falls inside an absolute or relative level range. Supply exactly one of `absolute` or `relative`; each range can use `min` and `max`. Either bound may be omitted; an omitted lower bound is unbounded below and an omitted upper bound is unbounded above.

`absolute` is the target level minus the player's level. Negative values mean the player is higher level. `relative` is the target level divided by the player's level.

```lua
local StrongOpponents = {
    absolute = { min = 0, max = 5 },
}

isValidCallback = function()
    return Playback.rules.combatTargetLevelDifference(StrongOpponents)
end
```

For a level-20 player, `{ relative = { min = 0.5, max = 2.0 } }` accepts targets from half the player's level through twice the player's level.

## `dynamicStatThreshold`

{{ api_signature(value="Playback.rules.dynamicStatThreshold(statThreshold) -> boolean") }}

Checks target health, magicka, and/or fatigue as percentages of each target's base value. Each stat accepts an optional `min` and `max` between `0` and `1`.

Unlike the other combat predicates, every current combat target must pass every supplied threshold. The rule requires combat and returns `false` when there are no active combat targets.

```lua
local WoundedTargets = {
    health = { max = 0.25 },
    fatigue = { max = 0.5 },
}

isValidCallback = function()
    return Playback.state.isInCombat
        and Playback.rules.dynamicStatThreshold(WoundedTargets)
end
```

## `fightingVampires`

{{ api_signature(value="Playback.rules.fightingVampires() -> boolean") }}

Returns `true` when any current target has an active vampirism effect. Use `combatTargetFaction` when a specific vampire clan matters.

```lua
isValidCallback = function()
    return Playback.rules.fightingVampires()
end
```

## `combatTargetTagged`

{{ api_signature(value="Playback.rules.combatTargetTagged(tagTable) -> boolean") }}

Returns `true` when any current target's record has one of the supplied FlexTag tags. This requires the optional FlexTag integration. Without it, S3maphore logs a diagnostic and returns `false`.

```lua
local MarkedEnemies = { 'npcassassin', 'npcbandit' }

isValidCallback = function()
    return Playback.rules.combatTargetTagged(MarkedEnemies)
end
```

Tags are defined by FlexTag, not by S3maphore.
