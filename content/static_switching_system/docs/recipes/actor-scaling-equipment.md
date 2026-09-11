+++
title = "Actor Scaling and Equipment"
description = "Target one placed actor, equip a set, and apply an absolute scale."
weight = 70

[extra]
api_docs = true
kind = "recipe"
+++

## Goal

Change one known NPC without affecting every NPC with the same record ID: force equipment onto the actor and set its scale to a fixed value.

## Smallest YAML excerpt

```yaml
instances:
  - conditions:
      - record_id: "caius cosades"
      - content_file_target:
          Morrowind.esm:
            - 67647
    once: true
    actions:
      - equip:
          "imperial helmet armor": 1
          "imperial cuirass_armor": 1
          "imperial shield": 1
          "imperial broadsword": 1
      - transform:
          transform_type: absolute
          scale: 0.1
```

The example is in `Examples/InstanceModifier_DiminutiveCaius.yaml`.

## Why it works

`record_id` provides the broad actor check. `content_file_target` narrows it to reference `67647` originating in `Morrowind.esm`; both conditions must pass. `equip` applies the requested items to an actor, creating and moving a missing item into its inventory before sending the forced OpenMW use operation. `transform_type: absolute` makes `scale: 0.1` one-tenth of the normal reference scale instead of a relative multiplier.

## Persistence

`once: true` records that the rule applied to this actor, and the equipment and transform become part of the saved world state. Test changes to broad rules on a copy of an existing save.

## Caveats

- Equipment actions use OpenMW's UseItem behavior. An item that is usable but not equippable may be used or consumed; do not treat `equip` as a guaranteed armor-only operation.
- `content_file_target` needs the exact content filename and local reference number. It is preferable to a stale standalone `ref_num` condition.
- A numeric `scale` is relative unless `transform_type: absolute` is explicit.
- The referenced equipment records must be supplied by active content. A missing item can make the intended equipment set incomplete.

Use [wildlife randomization](@/static_switching_system/docs/recipes/wildlife-randomization.md) for a broad creature rule instead of a reference-targeted actor patch.
