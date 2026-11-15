+++
title = "Reacting When a Quest Advances"
description = "Change objects around the player the moment a journal stage is reached."
weight = 100

[extra]
api_docs = true
kind = "recipe"
+++

## Goal

Make the world respond when a quest reaches a stage, including for objects the player is already standing next to, instead of waiting until those objects next become active.

## Smallest YAML excerpt

```yaml
instances:
  - trigger:
      - journal
      - active
    conditions:
      - object_type: Static
      - record_id: "^furn_6th_ashstatue$"
      - has_journal:
          quest: c3_destroydagoth
          min: 50
    actions:
      - disable: true
    once: true
```

This is reduced from `Examples/InstanceModifier_SixthHouseFalls.yaml`.

## Why it works

The [`journal` trigger](@/static_switching_system/docs/concepts/triggers.md#world-triggers) watches the quest named by the rule's own `has_journal` condition. When that quest changes stage, SSS runs the rule on the objects in the player's cell and, outdoors, the eight cells around it. The condition then decides whether the new stage is one the rule applies at.

Listing `active` as well covers everything the sweep cannot reach: statues elsewhere in the world are handled as the player meets them. The two triggers share one `once: true` mark, so no statue is processed twice.

`object_type` is worth including on any world-trigger rule. When every rule for a trigger names one, a sweep only looks at objects of those types.

To act during a window of stages rather than from a stage onwards, set both `min` and `max` on `has_journal`.

## Persistence

`once: true` and the disabled state are both saved. Nothing about the trigger itself is saved; after a load SSS records the current quest stage and waits for the next change.

## Caveats

- A `journal` rule must contain a `has_journal` condition, or it is skipped when the module loads.
- The trigger fires on a stage *change*. A quest already at the stage when a save is loaded does not fire it; that case is exactly what the `active` half of the rule is for.
- The change is noticed when the game is unpaused, so an object swaps as dialogue closes, not while the journal entry is still on screen.
- A sweep covers the player's cell and adjacent exterior cells only.
- Without `once`, the rule runs again on every later stage change that still satisfies the condition.

For the activation-only form of quest gating, see [Quest-state world patching](@/static_switching_system/docs/recipes/quest-state-world-patching.md).
