+++
title = "Necromantic Compound Interest"
description = "Use generated objects and once-per-object rules to create an undead feedback loop that can become unbounded."
weight = 20

[extra]
api_docs = true
kind = "experiment"
+++

## What this demonstrates

- [`generated_object`](@/static_switching_system/docs/api/conditions/location-and-identity.md#generated-object)
- [`is_dead` and `creature_type`](@/static_switching_system/docs/api/conditions/actors-and-target-state.md)
- [`create`](@/static_switching_system/docs/api/actions/world-and-transform.md#create)
- [`once: true`](@/static_switching_system/docs/concepts/persistence.md#instance-rules)
- [Random ranges and saved generated objects](@/static_switching_system/docs/api/actions/random-ranges.md)

## Why it works

The rule ignores original placements and watches only dynamically created undead. When one of those creatures becomes active while dead, SSS rolls a chance to create up to two skeletons around it. Each child is itself a generated object, so after it eventually dies it can satisfy the same rule.

This is population dynamics through declarative YAML. `once: true` limits each dead generated object to one successful application across save/load; it does not impose one global limit on the family tree.

## The catch

- `once: true` records a successful application, not a failed roll. If the spawn pool misses, the corpse remains eligible on a later activation.
- Given enough revisits, every eligible dead generated undead eventually reproduces. A successful count roll samples uniformly from 1–2, so eventual offspring are 50% one child and 50% two children: expected offspring `1.5` per reproducing corpse. This is not a subcritical branching process; skeleton singularity is the mathematical destiny of the module if the descendants keep dying.
- SSS has no reproduction timer here. The rule runs when the dead generated object becomes active and SSS processes it.
- Created objects become ordinary saved world objects. Removing the YAML does not automatically remove the population it created.
- `creature_type: undead` already restricts the rule to Creature records; NPCs are not included by this condition.

## Complete YAML

The source fixture is `Examples/InstanceModifier_NecromanticCompoundInterest.yaml`.

```yaml
log_name: Necromantic Compound Interest
priority: balance

instances:
  - conditions:
      - generated_object: true
      - is_dead: true
      - creature_type: undead
    once: true
    actions:
      - create:
          skeleton:
            count:
              max: 2
            chance: 0.35
            position:
              x: { min: -96, max: 96 }
              y: { min: -96, max: 96 }
```
