+++
title = "The Door Knows What You're Wearing"
description = "Combine equipment and faction ownership conditions into a declarative disguise system."
weight = 60

[extra]
api_docs = true
kind = "experiment"
+++

## What this demonstrates

- [`player_equipped`](@/static_switching_system/docs/api/conditions/player-and-world-state.md#player-equipped)
- [`object_type`](@/static_switching_system/docs/api/conditions/location-and-identity.md#object-type), [`faction_owner_id`](@/static_switching_system/docs/api/conditions/actors-and-target-state.md#faction-owner-id), and [`locked`](@/static_switching_system/docs/api/conditions/object-properties.md#locked)
- [`lock_level`, `key`, and `trap`](@/static_switching_system/docs/api/actions/world-state.md)
- [Persistent instance changes](@/static_switching_system/docs/concepts/persistence.md#instance-rules)

## Why it works

An imperial-owned door that is still locked checks the player's currently equipped cuirass. When the condition passes, the fixed action order unlocks the door and clears its key and trap requirements. No Lua event bus, disguise registry, or door-specific script is required.

The same pattern can be duplicated for other factions and uniforms. The primitives are individually plain; together they are an access system.

## The catch

- This is checked only when the door becomes active. Equipping the uniform while the door is already active does not cause SSS to revisit it.
- Removing the uniform does not re-lock the door. The action is a persistent world mutation, not a live access predicate.
- `activate_by_player` is intentionally absent. The player still has to interact with the door normally.
- `key: false` and `trap: false` are destructive for matching doors; narrow the faction and uniform conditions before using this beyond an experiment.

## Complete YAML

The source fixture is `Examples/InstanceModifier_DoorKnowsWhatYoureWearing.yaml`.

```yaml
log_name: The Door Knows What You're Wearing
priority: standard

instances:
  - conditions:
      - object_type: Door
      - faction_owner_id: imperial legion
      - player_equipped: imperial cuirass_armor
      - locked: true
    actions:
      - lock_level: 0
      - key: false
      - trap: false
```
