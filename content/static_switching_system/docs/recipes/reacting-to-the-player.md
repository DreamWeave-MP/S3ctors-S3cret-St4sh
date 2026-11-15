+++
title = "Reacting to What the Player Does"
description = "Run a rule when the player activates, drops, places, or uses something."
weight = 110

[extra]
api_docs = true
kind = "recipe"
+++

## Goal

Tie a rule to a player action rather than to an object loading: opening a container, dropping an item, or using one.

## Smallest YAML excerpt

```yaml
instances:
  - trigger: activate
    conditions:
      - object_type: Container
      - by_player: true
      - locked: true
      - exterior: false
    actions:
      - chance: 0.2
        create:
          rat:
            count:
              max: 2
            position:
              x: { min: -60, max: 60 }
              y: { min: -60, max: 60 }
    once: true
```

This is `Examples/InstanceModifier_RatsInTheLockbox.yaml`.

## Why it works

The [interaction triggers](@/static_switching_system/docs/concepts/triggers.md#interaction-triggers) fire for one object, immediately, and know which actor was responsible. `by_player` uses that: without it the rule would also run when an NPC or creature activated the container.

`activate` runs before the engine performs the activation, and the rule runs on the activated object, so the `create` offsets are measured from the container. `once: true` gives each container one roll; a container whose roll missed is not marked and can roll again.

The other interaction triggers follow the same shape:

```yaml
# Dropped or placed: the rule runs on the item, now back in the world.
- trigger: [drop, place]
  conditions:
    - by_player: true
    - record_id: "^gold_"
    - exterior: true
  actions:
    - chance: 0.3
      create: { mudcrab: 1 }

# Used: the rule runs on the actor, and the item is matched with used_item.
- trigger: use
  conditions:
    - by_player: true
    - used_item: "^potion_skooma_01$"
    - exterior: true
  actions:
    - chance: 0.25
      set_weather: foggy
```

These come from `Examples/InstanceModifier_MudcrabsLikeShinyThings.yaml` and `Examples/InstanceModifier_StormAtronachsLastWord.yaml`.

## Persistence

Interaction triggers keep no state of their own. What a rule does is saved as usual: created objects, once marks, and changed properties.

## Caveats

- Rules observe an activation; they cannot cancel it. If another mod's handler cancels the activation first, the rule does not run.
- A `use` rule runs on the actor. Location conditions describe where the actor is, and `record_id` would match the actor, not the item.
- `by_player` and `used_item` are only valid under the triggers that supply them. Used elsewhere, the rule is skipped when the module loads.
- A dropped or placed item also becomes active, so an `active` rule that matches it runs too.
- The same trigger on the same object within a quarter of a second is ignored. For `use`, different items count separately.
- A rule's own action cannot fire another trigger while it is running; see [Custom triggers](@/static_switching_system/docs/concepts/triggers.md#custom-triggers).
