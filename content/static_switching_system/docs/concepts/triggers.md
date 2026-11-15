+++
title = "Triggers"
description = "Choose when an instance rule runs: on activation, on world changes, on entering a cell, on interaction, on death, or when another mod asks."
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

`trigger` takes one name or a list. A rule listed under several triggers is the same rule each time, so `once: true` covers all of them together. Listing the same trigger twice is an error and the rule is skipped.

Static mesh replacement is not affected by triggers; it only happens when an object becomes active.

## Trigger reference

| Trigger | Fires when | The rule runs on |
| --- | --- | --- |
| `active` | An object becomes active. This is the default. | That object. |
| `journal` | A quest named by the rule's own `has_journal` condition changes stage. | Objects near the player. |
| `hour` | The game hour rolls over. | Objects near the player. |
| `day` | The game day rolls over. | Objects near the player. |
| `weather` | The weather in the player's cell changes. | Objects near the player. |
| `cell_enter` | The player enters a cell, including on load. | The player. |
| `activate` | An actor activates the object. | The activated object. |
| `drop` | An actor drops an item from their inventory. | The item. |
| `place` | The player places an item on a surface. | The item. |
| `use` | An actor uses or equips an item. | The actor, not the item. |
| `death` | An NPC or creature dies. | The dead actor. |
| `custom:<name>` | Another mod fires the named trigger. | The object that mod passes. |

## Shipped examples

Each trigger has a working module under `Examples/`:

| Trigger | Example |
| --- | --- |
| `journal` | `InstanceModifier_SixthHouseFalls.yaml` |
| `hour` | `InstanceModifier_CaiusClocksOut.yaml` |
| `day`, `weather` | `InstanceModifier_WhileYouWereStandingThere.yaml` |
| `cell_enter` | `InstanceModifier_ADremoraWalksIntoACornerclub.yaml` |
| `activate` | `InstanceModifier_RatsInTheLockbox.yaml` |
| `drop`, `place` | `InstanceModifier_MudcrabsLikeShinyThings.yaml` |
| `use`, `death` | `InstanceModifier_StormAtronachsLastWord.yaml` |
| `custom:<name>` | `InstanceModifier_SoundTheAlarm.yaml` |

The recipes [Placing something unique in a cell](@/static_switching_system/docs/recipes/unique-placement.md), [Reacting when a quest advances](@/static_switching_system/docs/recipes/reacting-to-quest-progress.md), and [Reacting to what the player does](@/static_switching_system/docs/recipes/reacting-to-the-player.md) walk through three of them.

## World triggers

`journal`, `hour`, `day`, and `weather` are not about any one object. When one fires, SSS *sweeps*: it runs that trigger's rules on the objects in the player's cell and, outdoors, the eight exterior cells around it. Objects farther away are not swept, even if your settings keep them loaded. Disabled objects are not swept.

SSS checks for these changes twice per second of game simulation, so nothing fires while the game is paused. A change made in a menu or in dialogue is noticed when play resumes.

World triggers are built so that one busy rule cannot run away with the game:

- A trigger that no loaded rule uses costs nothing. It is not checked at all.
- Loading a save never fires a trigger. The first check after a load only records the current hour, day, weather, and quest stages.
- A sweep runs only that trigger's rules, and when every one of those rules names an `object_type`, it only looks at objects of those types. Naming `object_type` is the single most effective way to keep a sweep cheap.
- A sweep is spread over frames and only advances on frames where SSS has no newly active objects to process. A frame either lists one cell's objects or runs rules on a fixed number of them, never both.
- The cells are fixed when a sweep starts and each is listed once, when the sweep reaches it. Objects a sweep creates beside the object that made them, or puts in place of others, are not swept by it. An object a rule teleports into a cell the sweep has not reached yet can be swept there.
- Conditions are evaluated against the world as it is on the frame they run. If a quest stage changes halfway through a sweep, the remaining objects see the new stage.
- One sweep runs at a time. A trigger that fires again while it is waiting or running is remembered once, not queued repeatedly. Waiting 24 hours is one `hour` sweep, not 24.
- A weather change made by SSS's own `set_weather` does not fire `weather`, including when several requests are outstanding at once. Arriving somewhere with different weather does not fire it either.
- A trigger that starts more than four sweeps within ten seconds of simulation time is suspended until the next load, with a warning in the log.

A `journal` rule must contain a `has_journal` condition; that is how SSS knows which quest to watch. It fires on any stage change of that quest, and the condition then decides whether the rule applies at the new stage.

A world rule without `once` runs on every firing. That is the point for an hourly schedule, and a trap for anything cumulative: a relative `transform` compounds each time. `once: per_cell` is not a safeguard here, since it only lasts until the next batch of objects becomes active. Use `once: true`, or conditions that stop matching after the rule has done its work.

## Entering a cell

`cell_enter` is for rules about a place rather than about something in it: put a unique NPC in a tavern, leave a chest in a cave, change the weather on arrival. It fires once each time the player enters a cell, and the rule runs on the *player*. No object in the cell has to match anything.

```yaml
instances:
  - trigger: cell_enter
    conditions:
      - cell: "Balmora, South Wall Cornerclub"
    actions:
      - create:
          my_unique_npc:
            transform_type: absolute
            position: { x: 291, y: 537, z: 261 }
            rotate: { z: 90 }
    once: true
```

- `create` spawns into the player's cell. With `transform_type: absolute` the position and rotation are exact cell coordinates; without it they are offsets from the player.
- `once: true` marks the player for that rule, and there is one player per save, so the rule applies once ever. Without `once` it applies on every entry.
- Location conditions (`cell`, `cell_match`, `coords`, `region`, `exterior`) describe the cell being entered. Player and world conditions work as usual.
- It also fires on the first check after a load or a new game, because the player is already standing somewhere. This is the one trigger that does; rely on `once` or conditions, not on it staying quiet.
- Only the cell the player is in counts. Outdoors, something meant for a neighbouring exterior cell appears when the player steps into that cell, not when it comes into view.
- `replace`, `disable`, and `delete` are refused on a `cell_enter` rule, since their target would be the player. Under any trigger, those three actions do nothing when the rule is running on the player.
- A `teleport` moves the player, but arriving where an SSS rule sent them is not an entry and does not fire `cell_enter`. Two rules that send the player to each other's cells therefore stop after the first move.

A rule like this is evaluated once per cell change against one object. That is far cheaper than an `active` rule that looks for an anchor object in every cell that loads.

## Interaction triggers

`activate`, `drop`, `place`, and `use` fire for one object, immediately, and carry the actor responsible.

- `activate` runs before the engine's own activation, so an item is still in the world when the rule sees it. Rules observe an activation; they cannot cancel it. Another mod's activation handler that cancels the activation first also prevents the rule from running.
- `use` runs on the *actor*. The item is in an inventory and has no cell, so location conditions and actor actions apply to whoever used it. Match the item with `used_item`.
- Dropping or placing an item also makes it active, so an `active` rule matching it runs as well.

Two conditions exist only for these triggers:

- [`by_player`](@/static_switching_system/docs/api/conditions/player-and-world-state.md#by-player): whether the actor is the player.
- [`used_item`](@/static_switching_system/docs/api/conditions/player-and-world-state.md#used-item): the record ID of the item being used.

A rule that uses them under a trigger that cannot supply them is skipped when the module loads.

The same trigger on the same object is ignored if it repeats within a quarter of a second of simulation time. For `use`, the item is part of that identity: two different items used in quick succession are two events.

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

The object must be in the world. A trigger fired while any rule is still running is refused with a warning. That covers a rule's own actions calling back into SSS, whether the rule was started by an activation, a sweep, or another trigger; rules cannot start further rule execution. Send the global event instead when a rule needs to cause a trigger: it arrives on a later frame, after the rule has finished.

A `StaticSwitcherTrigger` event whose payload is not a table with a string `name` and an object is ignored.
