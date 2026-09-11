+++
title = "Your First Module"
description = "Create a static replacement and an instance rule using real SSS syntax."
weight = 30

[extra]
kind = "guide"
+++

## First successful test

Before adding replacement assets, verify the SSS path with an instance-only module using a vanilla creature record:

```yaml
log_name: SSS First Test
instances:
  - conditions:
      - object_type: Creature
      - record_id: "^rat$"
    once: true
    actions:
      - transform:
          scale: 1.25
```

Save it below `scripts/staticSwitcher/data/`, load a cell containing a rat, and confirm the rat is 25% larger. The action is relative, so `1.25` multiplies the reference scale. `once: true` saves the successful application for that object. If nothing happens, enable [debug logging](@/static_switching_system/docs/concepts/validation-and-debugging.md#debug-logging) and check [troubleshooting](@/static_switching_system/docs/compatibility/troubleshooting.md) before adding more conditions or actions.

## Static replacement

A static module maps an existing mesh to a replacement mesh. This excerpt is copied from the shipped `StaticModule_Advanced.yaml` example:

```yaml
log_name: Improved Creature Meshes with Exclusions
replace_meshes:
  r/CliffRacer.NIF: my_mod/creatures/cliff_racer_replacer.NIF
  r/Shalk.NIF: my_mod/creatures/shalk_replacer.NIF
ignore_records:
  - cliff racer_diseased
  - shalk_blighted
```

Copy the example from `Examples/StaticModule_Advanced.yaml`, or replace the paths with assets you have installed. `ignore_records` is checked before the mesh swap, so variants sharing a base mesh can remain unchanged. With no location filters, `replace_meshes` is eligible in every cell. See [Static module fields](@/static_switching_system/docs/api/module-format.md#static-modules).

An instance module matches an active object and applies an action. This small example is copied from `InstanceModifier_CreatureScale.yaml`:

```yaml
log_name: Wild Creature Size Randomizer
instances:
  - conditions:
      - object_type: Creature
    once: true
    actions:
      - transform:
          scale:
            min: 0.5
            max: 2.0
```

The scale is sampled for each matching creature, and `once: true` records the applied rule so that it is not rolled again for that object after save/load. The same rule without `once` can run again when the object becomes active. See [Instance modules](@/static_switching_system/docs/api/module-format.md#instance-modules) for the condition and action vocabulary.

## Test deliberately

Use a small module first. Check the SSS log after enabling [debug logging](@/static_switching_system/docs/concepts/validation-and-debugging.md#debug-logging), and confirm the target object is eligible. If an instance rule matches, it owns dispatch even when its chance roll misses; SSS does not fall back to static replacement for that activation.

Next read [Matching, Priority, and Action Order](@/static_switching_system/docs/concepts/order-and-matching.md), [Ranges](@/static_switching_system/docs/concepts/ranges.md), and the [behavioral edge cases](@/static_switching_system/docs/concepts/edge-cases.md).
