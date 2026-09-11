+++
title = "You Probably Want Lua"
description = "A deliberately pathological SSS module showing where declarative composition should stop."
weight = 70

[extra]
api_docs = true
kind = "experiment"
+++

## What this demonstrates

- A large AND-only condition intersection across object identity, location, weather, player resources, attributes, skills, faction, equipment, and target state
- [`generated_object`](@/static_switching_system/docs/api/conditions/location-and-identity.md#generated-object), [`current_weather`](@/static_switching_system/docs/api/conditions/player-and-world-state.md#current-weather), and [`player_health`](@/static_switching_system/docs/api/conditions/player-and-world-state.md#player-health)
- [`replace: self`](@/static_switching_system/docs/api/actions/world-and-transform.md#replace), replacement failure followed by later actions, and fixed action order
- [`transform`, `teleport`, and `create`](@/static_switching_system/docs/api/actions/world-and-transform.md), [`playsound`](@/static_switching_system/docs/api/actions/scripts-tags-and-sound.md#playsound), [`delete`, keys, traps, and ownership](@/static_switching_system/docs/api/actions/world-state.md), and [inventory actions](@/static_switching_system/docs/api/actions/inventory-and-equipment.md)
- A generated-object feedback path that combines replacement, relocation, spawning, and deletion
- [Persistence and activation timing](@/static_switching_system/docs/concepts/persistence.md)

## Why it works

This module is intentionally doing too much. Its first rule requires a particular family of vanilla bone statics, an ash storm, three depleted player resources, two player attributes, two skills, Imperial Legion membership, and a cuirass. One action then conditionally replaces the static, applies random transform values, creates three independent object pools, and plays a sound.

The second rule catches generated undead corpses, recreates them with `replace: self`, teleports the new object to a named vanilla cell, spawns more creatures and bones at that pending destination, plays another sound at the old committed position, and deletes the old object. The third rule makes a rich locked tomb container or door change its lock, key, trap, ownership, and contents. The fourth rule changes an Imperial warrior's equipment through an unequip/remove/add/equip sequence.

SSS can express each operation and its fixed ordering. That is not the same as being the right home for the behavior. The module has no loops, timers, local variables, event subscriptions, or shared state, so every “phase” is actually another independently evaluated rule. The result is a pile of predicates and side effects whose interactions are governed by activation timing and save history rather than by an explicit state machine.

## The catch

- The conditions are ANDed; a rule that looks dramatic may almost never match.
- Action-level `chance` gates the whole first action, while replacement, item pools, and sounds have additional independent rolls.
- `replace: self` disables the old instance and creates a new one from its base record. In the second rule, `delete: true` then removes the old generated corpse after the replacement succeeds.
- Created objects can satisfy later rules when they become active. `once: true` limits each successful rule application per object; it is not a global recursion guard.
- The teleport target is a real vanilla cell (`Ashurnabitashpi`), but relocating a corpse there is intentionally absurd. Created children use the requested destination position; they cannot observe the later ground-snapped result of `onGround: true`.
- The fixture uses record IDs and a sound ID from the installed Morrowind content. Adapt or revalidate them when the active load order changes.
- If the design needs state transitions, cross-object coordination, timers, retries with different policy, or readable branching, write Lua. This is a stress test, not a recommendation.

## Complete YAML

The source fixture is `Examples/InstanceModifier_YouProbablyWantLua.yaml`.

```yaml
log_name: You Probably Want Lua
priority: finisher

instances:
  - conditions:
      - object_type: Static
      - record_id:
          - furn_bone_01
          - furn_bone_rib_01
          - furn_bone_skull_01
          - furn_bone_stake00
      - generated_object: false
      - current_weather:
          isStorm: true
          name: ash
      - player_health:
          max: 20
      - player_magicka:
          max: 30
      - player_fatigue:
          max: 40
      - player_attribute:
          willpower:
            min: 40
          luck:
            min: 40
      - player_skill:
          mysticism:
            min: 30
          security:
            min: 40
      - player_faction:
          faction: imperial legion
          min: 1
      - player_equipped: imperial cuirass_armor
    once: true
    actions:
      - chance: 0.8
        replace:
          bonewalker: 0.35
        transform:
          scale: { min: 0.75, max: 1.5 }
          rotate:
            x: { min: -10, max: 10 }
            y: { min: -10, max: 10 }
            z: { min: -30, max: 30 }
          position:
            x: { min: -8, max: 8 }
            y: { min: -8, max: 8 }
        create:
          furn_bone_01:
            count: { min: 1, max: 4 }
            chance: 0.8
            scale: { min: 0.6, max: 1.3 }
            rotate:
              z: { min: 0, max: 360 }
            position:
              x: { min: -128, max: 128 }
              y: { min: -128, max: 128 }
          furn_bone_skull_01:
            count: { min: 1, max: 2 }
            chance: 0.45
            rotate:
              z: { min: 0, max: 360 }
            position:
              x: { min: -160, max: 160 }
              y: { min: -160, max: 160 }
          bonewalker:
            count: { min: 1, max: 2 }
            chance: 0.25
            position:
              x: { min: -192, max: 192 }
              y: { min: -192, max: 192 }
        playsound:
          id: bonewalkerroar
          chance: 0.5
          volume: 0.7
          pitch: 0.8

  - conditions:
      - object_type: Creature
      - generated_object: true
      - creature_type: undead
      - is_dead: true
      - current_weather:
          isStorm: true
          name: ash
      - player_health:
          max: 20
    once: true
    actions:
      - replace: self
        transform:
          scale: { min: 0.8, max: 1.2 }
          rotate:
            z: { min: -180, max: 180 }
        teleport:
          cell: Ashurnabitashpi
          position:
            x: { min: -128, max: 128 }
            y: { min: -128, max: 128 }
            z: { min: 0, max: 64 }
          onGround: true
        create:
          bonewalker_greater:
            count: { min: 1, max: 2 }
            chance: 0.6
            position:
              x: { min: -96, max: 96 }
              y: { min: -96, max: 96 }
          furn_bone_skull_01:
            count: { min: 1, max: 3 }
            chance: 0.8
            position:
              x: { min: -96, max: 96 }
              y: { min: -96, max: 96 }
        playsound: bonewalkerroar
        delete: true

  - conditions:
      - object_type:
          - Door
          - Container
      - cell_match: tomb
      - player_level:
          min: 20
      - player_health:
          max: 20
      - player_skill:
          security:
            min: 80
      - player_equipped: imperial cuirass_armor
      - locked: true
      - has_key: true
      - has_trap: false
      - carrying:
          - gold_001: 100
    once: true
    actions:
      - lock_level: { min: 75, max: 100 }
        key:
          - key_caius_cosades: 0.35
          - key_marvani_tomb: 1.0
        trap:
          - trap_paralyze00: 0.2
          - trap_poison00: 0.4
          - trap_fire00: 1.0
        set_ownership:
          faction: imperial legion
          factionRank: 1
        create:
          furn_bone_01:
            count: { min: 1, max: 3 }
            chance: 0.5
            position:
              x: { min: -80, max: 80 }
              y: { min: -80, max: 80 }
        playsound:
          id: bonewalkerroar
          chance: 0.25

  - conditions:
      - object_type: NPC
      - target_faction:
          faction: imperial legion
          min: 1
      - target_class: warrior
      - target_attribute:
          strength:
            min: 50
      - target_skill:
          longblade:
            min: 40
      - target_health:
          max: 50
      - player_fatigue:
          max: 25
      - player_equipped: imperial cuirass_armor
    once: true
    actions:
      - unequip:
          - imperial shield
          - imperial broadsword
      - remove:
          imperial broadsword: { chance: 0.5 }
      - add:
          imperial broadsword: { count: 1, chance: 0.75 }
      - equip:
          imperial broadsword: { chance: 0.5 }
          imperial shield: { chance: 0.5 }
```
