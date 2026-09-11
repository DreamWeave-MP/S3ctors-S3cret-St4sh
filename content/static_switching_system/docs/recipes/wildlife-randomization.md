+++
title = "Wildlife Randomization"
description = "Give creature instances a random scale while choosing whether the result persists."
weight = 30

[extra]
api_docs = true
kind = "recipe"
+++

## Goal

Randomize the size of creatures, while keeping each creature's result stable across save/load.

## Smallest YAML excerpt

```yaml
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

This is the compact form from `Examples/InstanceModifier_CreatureScale.yaml`.

## Why it works

`object_type: Creature` matches creature objects. `transform.scale` is relative by default, so the sampled value multiplies the current scale. The table is a random action range and includes the required `max`. The `once: true` marker records the rule's applied state for that object after it succeeds.

To deliberately vary an activation-batch effect, use `once: per_cell` instead. Omitting `once` lets the rule run whenever the object is activated; with a relative scale this can compound, so use that form only when repeated multiplication is intended.

## Persistence

The successful `once: true` application is represented in SSS's saved once-cache, while the object's transform is part of the saved world state. `per_cell` tracking is runtime-only and is not a save migration mechanism. Test on a copy of a save before changing a broad rule.

## Caveats

- `scale` is a relative multiplier unless `transform_type: absolute` is supplied.
- A random action range requires `max`; `min` is optional for sampled values and defaults according to the consuming action.
- This rule reaches creatures as they become active, not every creature in unloaded cells at once.
- Static and instance modules do not compose for one activation. A matching instance rule takes the instance path instead of falling through to static replacement.

The larger `Examples/InstanceModifier_WildlifeVariety.yaml` also demonstrates record, region, exterior, and per-cell patterns.
