+++
title = "Triggers"
description = "Choose when an instance rule runs: on activation, on world changes, on interaction, on death, or when another mod asks."
weight = 85

[extra]
kind = "concepts"
+++

Every instance rule has a `trigger`: the moment SSS evaluates it. A rule with no `trigger` runs when its object becomes active, which is how every rule behaved before triggers existed.

```yaml
instances:
  - trigger: journal
    conditions:
      - has_journal: { quest: my_quest, min: 60 }
      - record_id: "^my_prop$"
    actions:
      - replace: { my_prop_after: 1 }
    once: true
```

`trigger` takes one name or a list. A rule listed under several triggers is the same rule each time, so `once: true` covers all of them together.

Static mesh replacement is not affected by triggers; it only happens when an object becomes active.

## Trigger reference

| Trigger | Fires when | The rule runs on |
| --- | --- | --- |
| `active` | An object becomes active. This is the default. | That object. |
| `journal` | A quest named by the rule's own `has_journal` condition changes stage. | Objects near the player. |
| `hour` | The game hour rolls over. | Objects near the player. |
| `day` | The game day rolls over. | Objects near the player. |
| `weather` | The weather in the player's cell changes. | Objects near the player. |
| `activate` | An actor activates the object. | The activated object. |
| `drop` | An actor drops an item from their inventory. | The item. |
| `place` | The player places an item on a surface. | The item. |
| `use` | An actor uses or equips an item. | The actor, not the item. |
| `death` | An NPC or creature dies. | The dead actor. |
| `custom:<name>` | Another mod fires the named trigger. | The object that mod passes. |

## World triggers

`journal`, `hour`, `day`, and `weather` are not about any one object. When one fires, SSS *sweeps*: it runs that trigger's rules on the objects in the player's cell and, outdoors, the eight exterior cells around it. Objects farther away are not swept, even if your settings keep them loaded. Disabled objects are not swept.

SSS checks for these changes twice per second of game simulation, so nothing fires while the game is paused. A change made in a menu or in dialogue is noticed when play resumes.

World triggers are built so that one busy rule cannot run away with the game:

- A trigger that no loaded rule uses costs nothing. It is not checked at all.
- Loading a save never fires a trigger. The first check after a load only records the current hour, day, weather, and quest stages.
- A sweep runs only that trigger's rules, and when every one of those rules names an `object_type`, it only looks at objects of those types. Naming `object_type` is the single most effective way to keep a sweep cheap.
- A sweep is spread over frames, a fixed number of objects per frame, and only advances on frames where SSS has no newly active objects to process.
- The list of objects is fixed when a sweep starts. Objects a sweep creates, or puts in place of others, are not swept by it.
- One sweep runs at a time. A trigger that fires again while it is waiting or running is remembered once, not queued repeatedly. Waiting 24 hours is one `hour` sweep, not 24.
- A weather change made by SSS's own `set_weather` does not fire `weather`. Arriving somewhere with different weather does not fire it either.
- A trigger that starts more than four sweeps within ten seconds of simulation time is suspended until the next load, with a warning in the log.

A `journal` rule must contain a `has_journal` condition; that is how SSS knows which quest to watch. It fires on any stage change of that quest, and the condition then decides whether the rule applies at the new stage.

A world rule without `once` runs on every firing. That is the point for an hourly schedule, and a trap for anything cumulative: a relative `transform` compounds each time. `once: per_cell` is not a safeguard here, since it only lasts until the next batch of objects becomes active. Use `once: true`, or conditions that stop matching after the rule has done its work.

## Interaction triggers

`activate`, `drop`, `place`, and `use` fire for one object, immediately, and carry the actor responsible.

- `activate` runs before the engine's own activation, so an item is still in the world when the rule sees it. Rules observe an activation; they cannot cancel it. Another mod's activation handler that cancels the activation first also prevents the rule from running.
- `use` runs on the *actor*. The item is in an inventory and has no cell, so location conditions and actor actions apply to whoever used it. Match the item with `used_item`.
- Dropping or placing an item also makes it active, so an `active` rule matching it runs as well.

Two conditions exist only for these triggers:

- [`by_player`](@/static_switching_system/docs/api/conditions/player-and-world-state.md#by-player): whether the actor is the player.
- [`used_item`](@/static_switching_system/docs/api/conditions/player-and-world-state.md#used-item): the record ID of the item being used.

A rule that uses them under a trigger that cannot supply them is skipped when the module loads.

The same trigger on the same object is ignored if it repeats within a quarter of a second of simulation time.

## Death

`death` runs once on an NPC or creature when it dies. The player is not covered.

OpenMW only announces a death to the dying actor's own scripts, so when a `death` rule is loaded SSS attaches a small relay script to each living NPC and creature as it becomes active. An actor that was already dead when it became active never fires `death`. The relay is declared in `Static Switching System.esp`; with an older copy of that plugin the trigger is unavailable and SSS logs one error saying so.

## Custom triggers

`custom:<name>` lets another mod decide when a rule runs:

```yaml
instances:
  - trigger: custom:myMod_bellRung
    conditions:
      - record_id: "^my_bell$"
    actions:
      - playsound: bell1
```

Fire it from a global script through the [interface](@/static_switching_system/docs/api/interface.md), or from any script with a global event:

```lua
I.StaticSwitcher_G.trigger('myMod_bellRung', bell)

core.sendGlobalEvent('StaticSwitcherTrigger', { name = 'myMod_bellRung', object = bell })
```

The object must be in the world. A custom trigger fired from inside another rule's actions, while that rule is still running, is refused with a warning; triggers cannot recurse into each other.
